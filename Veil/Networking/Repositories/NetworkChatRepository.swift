import Foundation
import CryptoKit

final class NetworkChatRepository: ChatRepository {
    private let crypto: CryptoService
    private let messageService: MessageService
    private let preKeyService: PreKeyService
    private let localKeyManager: KeyManager
    private let sessionManager: SessionManager

    private let lock = NSLock()
    private var store: [String: [ChatMessage]] = [:]
    private var threadIdByUsername: [String: UUID] = [:]
    private var didPublishBundle = false

    init(
        crypto: CryptoService,
        messageService: MessageService,
        preKeyService: PreKeyService,
        localKeyManager: KeyManager = KeyManager(),
        sessionStore: SessionStore = InMemorySessionStore()
    ) {
        self.crypto = crypto
        self.messageService = messageService
        self.preKeyService = preKeyService
        self.localKeyManager = localKeyManager
        self.sessionManager = SessionManager(keyManager: localKeyManager, store: sessionStore)
    }

    func loadMessages(chatUsername: String) -> [ChatMessage] {
        lock.withLock {
            store[chatUsername, default: []]
        }
    }

    func listChats() -> [ChatThread] {
        lock.withLock {
            store.compactMap { username, msgs in
                guard let last = msgs.max(by: { $0.createdAt < $1.createdAt }) else { return nil }
                return ChatThread(
                    id: deterministicThreadId(for: username),
                    username: username,
                    lastPreview: last.plaintextPreview,
                    lastAt: last.createdAt
                )
            }
            .sorted(by: {
                if $0.lastAt == $1.lastAt { return $0.username < $1.username }
                return $0.lastAt > $1.lastAt
            })
        }
    }

    func sendMessage(chatUsername: String, plaintext: String, timer: MessageTimer) async throws -> ChatMessage {
        var session = try await ensureSession(for: chatUsername)
        let ciphertext = try crypto.encrypt(plaintext: plaintext, for: chatUsername, session: &session)
        sessionManager.saveSession(session)

        let envelope = MessageEnvelopeDTO(version: 1, to: chatUsername, from: nil, payloadB64: ciphertext)
        try await messageService.sendEnvelope(envelope)

        let sent = ChatMessage(
            id: UUID(),
            chatUsername: chatUsername,
            direction: .outgoing,
            ciphertext: ciphertext,
            plaintextPreview: plaintext,
            createdAt: Date(),
            timer: timer,
            state: .sent
        )

        lock.withLock {
            store[chatUsername, default: []].append(sent)
        }

        return sent
    }

    func ingestIncoming(_ envelopes: [MessageEnvelopeDTO]) {
        guard !envelopes.isEmpty else { return }

        let incoming = envelopes.compactMap { dto -> ChatMessage? in
            let username = dto.from ?? dto.to
            guard var session = sessionManager.session(for: username) else { return nil }
            guard let plaintext = try? crypto.decrypt(ciphertext: dto.payloadB64, for: username, session: &session) else {
                return nil
            }
            sessionManager.saveSession(session)
            return ChatMessage(
                id: UUID(),
                chatUsername: username,
                direction: .incoming,
                ciphertext: dto.payloadB64,
                plaintextPreview: plaintext,
                createdAt: Date(),
                timer: .hour1,
                state: .sent
            )
        }

        lock.withLock {
            for message in incoming {
                store[message.chatUsername, default: []].append(message)
            }
        }
    }

    private func ensureSession(for username: String) async throws -> SessionState {
        if let existing = sessionManager.session(for: username) {
            return existing
        }

        try await publishBundleIfNeeded()
        let remoteBundle = try await preKeyService.fetchBundle(username: username)
        return try sessionManager.establishSessionAsInitiator(remote: remoteBundle)
    }


    private func publishBundleIfNeeded() async throws {
        let shouldPublish = lock.withLock {
            if didPublishBundle { return false }
            didPublishBundle = true
            return true
        }

        guard shouldPublish else { return }

        do {
            let bundle = try localKeyManager.makePreKeyBundle(oneTimeCount: 20)
            try await preKeyService.publishBundle(bundle)
        } catch {
            lock.withLock { didPublishBundle = false }
            throw error
        }
    }

    private func deterministicThreadId(for username: String) -> UUID {
        if let existing = threadIdByUsername[username] {
            return existing
        }

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
