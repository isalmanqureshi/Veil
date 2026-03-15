import Foundation
import CryptoKit

final class NetworkChatRepository: ChatRepository {
    private let crypto: CryptoService
    private let messagesService: MessagesService
    private let preKeysService: PreKeysService
    private let localKeyManager: KeyManager
    private let sessionManager: SessionManager
    private let authContext: LocalAuthContext

    private let lock = NSLock()
    private var store: [String: [ChatMessage]] = [:]
    private var threadIdByUsername: [String: UUID] = [:]
    private var seenServerMessageIds: Set<String> = []

    init(
        crypto: CryptoService,
        messagesService: MessagesService,
        preKeysService: PreKeysService,
        localKeyManager: KeyManager = KeyManager(),
        sessionStore: SessionStore = InMemorySessionStore(),
        authContext: LocalAuthContext = LocalAuthContext()
    ) {
        self.crypto = crypto
        self.messagesService = messagesService
        self.preKeysService = preKeysService
        self.localKeyManager = localKeyManager
        self.sessionManager = SessionManager(keyManager: localKeyManager, store: sessionStore)
        self.authContext = authContext
    }

    func loadMessages(chatUsername: String) -> [ChatMessage] {
        lock.withLock { store[chatUsername, default: []] }
    }

    func listChats() -> [ChatThread] {
        lock.withLock {
            store.compactMap { username, msgs in
                guard let last = msgs.max(by: { $0.createdAt < $1.createdAt }) else { return nil }
                return ChatThread(id: deterministicThreadId(for: username), username: username, lastPreview: last.plaintextPreview, lastAt: last.createdAt)
            }
            .sorted(by: {
                if $0.lastAt == $1.lastAt { return $0.username < $1.username }
                return $0.lastAt > $1.lastAt
            })
        }
    }

    func sendMessage(chatUsername: String, plaintext: String, timer: MessageTimer) async throws -> ChatMessage {
        guard let fromUsername = authContext.currentUsername() else {
            throw APIError.server(statusCode: 401, message: "Not signed in")
        }

        let deviceId = authContext.currentDeviceId()
        var session = try await ensureSession(for: chatUsername)
        let payloadB64 = try crypto.encrypt(plaintext: plaintext, for: chatUsername, session: &session)
        sessionManager.saveSession(session)

        let request = SendMessageRequestDTO(
            fromUsername: fromUsername,
            toUsername: chatUsername,
            deviceId: deviceId,
            payloadB64: payloadB64,
            envelopeVersion: 1,
            oneTimePreKeyId: session.remoteOneTimePreKeyId,
            timer: timer.rawValue,
            clientMessageId: UUID().uuidString
        )

        _ = try await messagesService.sendEnvelope(request)

        let sent = ChatMessage(
            id: UUID(),
            chatUsername: chatUsername,
            direction: .outgoing,
            ciphertext: payloadB64,
            plaintextPreview: plaintext,
            createdAt: Date(),
            timer: timer,
            state: .sent
        )

        append(sent)
        return sent
    }

    func ensureChatExists(username: String) {
        lock.withLock {
            _ = store[username, default: []]
        }
    }

    func ingestIncoming(_ envelopes: [InboxEnvelopeDTO]) -> [String] {
        var ackIds: [String] = []

        for envelope in envelopes {
            if lock.withLock({ seenServerMessageIds.contains(envelope.serverMessageId) }) {
                ackIds.append(envelope.serverMessageId)
                continue
            }

            guard var session = sessionManager.session(for: envelope.fromUsername) else {
                let fallback = ChatMessage(
                    id: stableMessageUUID(from: envelope.serverMessageId),
                    chatUsername: envelope.fromUsername,
                    direction: .incoming,
                    ciphertext: envelope.payloadB64,
                    plaintextPreview: "Unable to decrypt message",
                    createdAt: envelope.queuedAt,
                    timer: MessageTimer(rawValue: envelope.timer ?? "") ?? .hour1,
                    state: .failed
                )
                append(fallback, serverMessageId: envelope.serverMessageId)
                ackIds.append(envelope.serverMessageId)
                continue
            }
            guard let plaintext = try? crypto.decrypt(ciphertext: envelope.payloadB64, for: envelope.fromUsername, session: &session) else {
                let fallback = ChatMessage(
                    id: stableMessageUUID(from: envelope.serverMessageId),
                    chatUsername: envelope.fromUsername,
                    direction: .incoming,
                    ciphertext: envelope.payloadB64,
                    plaintextPreview: "Unable to decrypt message",
                    createdAt: envelope.queuedAt,
                    timer: MessageTimer(rawValue: envelope.timer ?? "") ?? .hour1,
                    state: .failed
                )
                append(fallback, serverMessageId: envelope.serverMessageId)
                ackIds.append(envelope.serverMessageId)
                continue
            }
            sessionManager.saveSession(session)

            let message = ChatMessage(
                id: stableMessageUUID(from: envelope.serverMessageId),
                chatUsername: envelope.fromUsername,
                direction: .incoming,
                ciphertext: envelope.payloadB64,
                plaintextPreview: plaintext,
                createdAt: envelope.queuedAt,
                timer: MessageTimer(rawValue: envelope.timer ?? "") ?? .hour1,
                state: .sent
            )

            append(message, serverMessageId: envelope.serverMessageId)
            ackIds.append(envelope.serverMessageId)
        }

        return Array(Set(ackIds))
    }

    private func append(_ message: ChatMessage) {
        lock.withLock {
            var messages = store[message.chatUsername, default: []]
            guard !messages.contains(where: { $0.id == message.id }) else { return }
            messages.append(message)
            messages.sort {
                if $0.createdAt == $1.createdAt { return $0.id.uuidString < $1.id.uuidString }
                return $0.createdAt < $1.createdAt
            }
            store[message.chatUsername] = messages
        }
    }

    private func append(_ message: ChatMessage, serverMessageId: String) {
        lock.withLock {
            guard !seenServerMessageIds.contains(serverMessageId) else { return }
            var messages = store[message.chatUsername, default: []]
            guard !messages.contains(where: { $0.id == message.id }) else {
                seenServerMessageIds.insert(serverMessageId)
                return
            }
            messages.append(message)
            messages.sort {
                if $0.createdAt == $1.createdAt { return $0.id.uuidString < $1.id.uuidString }
                return $0.createdAt < $1.createdAt
            }
            store[message.chatUsername] = messages
            seenServerMessageIds.insert(serverMessageId)
            if seenServerMessageIds.count > 2_000 {
                seenServerMessageIds = Set(seenServerMessageIds.suffix(1_000))
            }
        }
    }

    private func ensureSession(for username: String) async throws -> SessionState {
        if let existing = sessionManager.session(for: username) {
            return existing
        }

        let remoteBundle = try await preKeysService.fetch(username: username).toDomain()
        return try sessionManager.establishSessionAsInitiator(remote: remoteBundle)
    }

    private func stableMessageUUID(from serverMessageId: String) -> UUID {
        let digest = SHA256.hash(data: Data("msg.network.\(serverMessageId)".utf8))
        let bytes = Array(digest)
        let uuidString = String(
            format: "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5],
            bytes[6], bytes[7],
            bytes[8], bytes[9],
            bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
        )

        return UUID(uuidString: uuidString) ?? UUID()
    }

    private func deterministicThreadId(for username: String) -> UUID {
        if let existing = threadIdByUsername[username] { return existing }

        let digest = SHA256.hash(data: Data("thread.network.\(username)".utf8))
        let bytes = Array(digest)
        let uuidString = String(
            format: "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5],
            bytes[6], bytes[7],
            bytes[8], bytes[9],
            bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
        )

        let id = UUID(uuidString: uuidString) ?? UUID()
        threadIdByUsername[username] = id
        return id
    }
}
