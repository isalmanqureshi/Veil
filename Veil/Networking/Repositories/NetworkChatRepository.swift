import Foundation
import CryptoKit

final class NetworkChatRepository: ChatRepository {
    private let crypto: CryptoService
    private let preKeysService: PreKeysService
    private let localKeyManager: KeyManager
    private let sessionManager: SessionManager
    private let authContext: LocalAuthContext
    private let messageObjectStore: MessageObjectStore
    private let pointerPublisher: MessagePointerPublisher
    private let conversationEventLog: ConversationEventLog
    private let conversationProjector: ConversationProjector

    private let lock = NSLock()
    private var store: [String: [ChatMessage]] = [:]
    private var threadIdByUsername: [String: UUID] = [:]
    private var seenPointerIds: Set<UUID> = []

    init(
        crypto: CryptoService,
        preKeysService: PreKeysService,
        messageObjectStore: MessageObjectStore,
        pointerPublisher: MessagePointerPublisher,
        conversationEventLog: ConversationEventLog,
        conversationProjector: ConversationProjector,
        localKeyManager: KeyManager = KeyManager(),
        sessionStore: SessionStore = InMemorySessionStore(),
        authContext: LocalAuthContext = LocalAuthContext()
    ) {
        self.crypto = crypto
        self.preKeysService = preKeysService
        self.messageObjectStore = messageObjectStore
        self.pointerPublisher = pointerPublisher
        self.conversationEventLog = conversationEventLog
        self.conversationProjector = conversationProjector
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
        guard let fromUsername = authContext.currentSignedInUsername() else {
            throw APIError.server(statusCode: 401, message: "Not signed in")
        }

        var session = try await ensureSession(for: chatUsername)
        let payloadB64 = try crypto.encrypt(plaintext: plaintext, for: chatUsername, session: &session)

        let conversationId = ConversationId.directMessage(localUsername: fromUsername, peerUsername: chatUsername)
        let object = EncryptedMessageObject(
            ref: nil,
            payloadB64: payloadB64,
            envelopeVersion: 1,
            senderUsername: fromUsername,
            recipientUsername: chatUsername,
            conversationId: conversationId.id,
            createdAt: Date(),
            timer: timer,
            metadata: .messageDefault
        )

        let objectRef = try await messageObjectStore.putMessageObject(object)
        let heads = try await conversationEventLog.fetchHeads(conversationId: conversationId.id)
        let currentEvents = try await conversationEventLog.fetchEvents(conversationId: conversationId.id)
        let clientMessageId = UUID().uuidString

        let event = ConversationEvent(
            id: UUID(),
            conversationId: conversationId.id,
            eventType: .messageCreated,
            objectRef: objectRef,
            actorUsername: fromUsername,
            createdAt: Date(),
            logicalClock: UInt64(currentEvents.count + 1),
            previousEventRefs: heads.headRefs,
            payload: .messageCreated(
                timer: timer,
                clientMessageId: clientMessageId,
                plaintextPreview: plaintext,
                ciphertextPreview: payloadB64
            ),
            signature: nil
        )

        _ = try await conversationEventLog.append(event)

        let pointer = MessagePointerEvent(
            id: UUID(),
            toUsername: chatUsername,
            fromUsername: fromUsername,
            objectRef: objectRef,
            createdAt: event.createdAt,
            requestFlow: false,
            oneTimePreKeyId: session.remoteOneTimePreKeyId,
            deliveryState: .pending
        )
        try await pointerPublisher.publishPointer(pointer)
        sessionManager.saveSession(session)

        let projected = try await reprojectConversation(peerUsername: chatUsername, localUsername: fromUsername)
        return projected.last ?? ChatMessage(
            id: event.id,
            chatUsername: chatUsername,
            direction: .outgoing,
            ciphertext: payloadB64,
            plaintextPreview: plaintext,
            createdAt: event.createdAt,
            timer: timer,
            state: .sent
        )
    }

    func ensureChatExists(username: String) {
        lock.withLock {
            _ = store[username, default: []]
        }
    }

    @discardableResult
    func pollIncomingPointers() async throws -> Bool {
        guard let username = authContext.currentSignedInUsername() else {
            return false
        }

        let pointers = try await pointerPublisher.fetchPointers(for: username, deviceId: authContext.currentDeviceId())
        guard !pointers.isEmpty else { return false }

        var ackIds: [UUID] = []
        var touchedPeers = Set<String>()

        for pointer in pointers {
            if lock.withLock({ seenPointerIds.contains(pointer.id) }) {
                ackIds.append(pointer.id)
                continue
            }

            guard var session = sessionManager.session(for: pointer.fromUsername) else {
                // Until request/session acceptance, we cannot decrypt. Acknowledge to avoid unbounded replay.
                ackIds.append(pointer.id)
                continue
            }

            guard let object = try? await messageObjectStore.getMessageObject(ref: pointer.objectRef) else {
                ackIds.append(pointer.id)
                continue
            }

            guard let plaintext = try? crypto.decrypt(ciphertext: object.payloadB64, for: pointer.fromUsername, session: &session) else {
                ackIds.append(pointer.id)
                continue
            }

            sessionManager.saveSession(session)

            let conversationId = ConversationId.directMessage(localUsername: username, peerUsername: pointer.fromUsername)
            let heads = try await conversationEventLog.fetchHeads(conversationId: conversationId.id)
            let currentEvents = try await conversationEventLog.fetchEvents(conversationId: conversationId.id)

            let event = ConversationEvent(
                id: stableMessageUUID(from: pointer.id.uuidString),
                conversationId: conversationId.id,
                eventType: .messageCreated,
                objectRef: pointer.objectRef,
                actorUsername: pointer.fromUsername,
                createdAt: pointer.createdAt,
                logicalClock: UInt64(currentEvents.count + 1),
                previousEventRefs: heads.headRefs,
                payload: .messageCreated(
                    timer: object.timer ?? .hour1,
                    clientMessageId: pointer.id.uuidString,
                    plaintextPreview: plaintext,
                    ciphertextPreview: object.payloadB64
                ),
                signature: nil
            )

            _ = try await conversationEventLog.append(event)
            lock.withLock { seenPointerIds.insert(pointer.id) }
            touchedPeers.insert(pointer.fromUsername)
            ackIds.append(pointer.id)
        }

        for peer in touchedPeers {
            _ = try await reprojectConversation(peerUsername: peer, localUsername: username)
        }

        if !ackIds.isEmpty {
            try await pointerPublisher.ackPointers(ids: ackIds, username: username)
        }

        return !touchedPeers.isEmpty
    }

    private func ensureSession(for username: String) async throws -> SessionState {
        if let existing = sessionManager.session(for: username) {
            return existing
        }

        let remoteBundle = try await preKeysService.fetch(username: username).toDomain()
        return try sessionManager.establishSessionAsInitiator(remote: remoteBundle)
    }

    private func reprojectConversation(peerUsername: String, localUsername: String) async throws -> [ChatMessage] {
        let conversationId = ConversationId.directMessage(localUsername: localUsername, peerUsername: peerUsername)
        let events = try await conversationEventLog.fetchEvents(conversationId: conversationId.id)
        let projected = conversationProjector.projectMessages(events: events, for: peerUsername)

        lock.withLock {
            store[peerUsername] = projected
        }

        return projected
    }

    private func stableMessageUUID(from rawId: String) -> UUID {
        let digest = SHA256.hash(data: Data("msg.network.\(rawId)".utf8))
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
