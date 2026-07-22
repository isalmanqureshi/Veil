//
//  ChatRepository.swift
//  Veil
//
//  Created by Salman Qureshi on 2/10/26.
//
import SwiftUI
import CryptoKit
import Foundation

private func stableUUID(_ rawValue: String) -> UUID {
    UUID(uuidString: rawValue) ?? UUID()
}


//Keep ChatRepository focused on per-chat messages + send
protocol ChatRepository {
    func loadMessages(chatUsername: String) -> [ChatMessage]
    func sendMessage(chatUsername: String, plaintext: String, timer: MessageTimer) async throws -> ChatMessage
    
    // NEW: for inbox
    func listChats() -> [ChatThread]
   
    //func ensureChatExists(username: String)
}

//ChatRepository with deterministic mock data + silent retry
enum SendError: Error { case transient }

/// `@unchecked Sendable`: all mutable dictionary/set state is serialized
/// through `lock`, mirroring `NetworkChatRepository`.
final class MockChatRepository: ChatRepository, @unchecked Sendable {

    private let crypto: CryptoService
    private let localKeyManager: KeyManager
    private let sessionManager: SessionManager
    private let lock = NSLock()
    private var remoteKeyManagers: [String: KeyManager] = [:]
    private var store: [String: [ChatMessage]] = [:]
    private var threadIdByUsername: [String: UUID] = [:]
    private var failFirstSendForChat: Set<String> = ["gfhjj"] // deterministic “first send fails"
    private let messageObjectStore: MessageObjectStore
    private let pointerPublisher: MessagePointerPublisher
    private let conversationEventLog: ConversationEventLog
    private let conversationProjector: ConversationProjector

    init(
        crypto: CryptoService,
        messageObjectStore: MessageObjectStore = InMemoryMessageObjectStore(),
        pointerPublisher: MessagePointerPublisher = InMemoryPointerPublisher(),
        conversationEventLog: ConversationEventLog = InMemoryConversationEventLog(),
        conversationProjector: ConversationProjector = DefaultConversationProjector(localUsername: "mock_local")
    ) {
        self.crypto = crypto
        self.localKeyManager = KeyManager(service: "veil.keys.local.mock")
        self.sessionManager = SessionManager(keyManager: localKeyManager, store: InMemorySessionStore())

        let localSeed = Data(SHA256.hash(data: Data("veil.local.seed".utf8)))
        try? localKeyManager.bootstrapIdentityIfNeeded(seed: localSeed)
        self.messageObjectStore = messageObjectStore
        self.pointerPublisher = pointerPublisher
        self.conversationEventLog = conversationEventLog
        self.conversationProjector = conversationProjector

        seedDeterministicChats()
    }

    func loadMessages(chatUsername: String) -> [ChatMessage] {
        if let existing = lock.withLock({ store[chatUsername] }) { return existing }

        // Deterministic seed messages
        let seeded: [ChatMessage] = [
            ChatMessage(
                id: stableUUID("11111111-2222-3333-4444-555555555555"),
                chatUsername: chatUsername,
                direction: .incoming,
                ciphertext: "enc(\(chatUsername)):!olleH",
                plaintextPreview: "Hello!",
                createdAt: Date(timeIntervalSince1970: 1_738_900_000).addingTimeInterval(-3600),
                timer: .hour1,
                state: .sent
            )
        ]
        lock.withLock { store[chatUsername] = seeded }
        return seeded
    }

    func sendMessage(chatUsername: String, plaintext: String, timer: MessageTimer) async throws -> ChatMessage {
        // Simulate transient failure once per specified chat (silent retry handled in VM)
        let shouldFailFirst = lock.withLock { failFirstSendForChat.contains(chatUsername) }
        if shouldFailFirst {
            lock.withLock { _ = failFirstSendForChat.remove(chatUsername) }
            throw SendError.transient
        }

        try await Task.sleep(nanoseconds: 200_000_000)

        // Use the signed-in identity so projected messages resolve as outgoing.
        // The projector compares each event's actor against the local username;
        // a hardcoded "mock_local" would flip sent messages to .incoming once a
        // real account exists on device.
        let fromUsername = LocalAuthContext().currentSignedInUsername() ?? "mock_local"
        var session = try ensureSession(for: chatUsername)
        let payloadB64 = try crypto.encrypt(plaintext: plaintext, for: chatUsername, session: &session)
        sessionManager.saveSession(session)

        let object = EncryptedMessageObject(
            ref: nil,
            payloadB64: payloadB64,
            envelopeVersion: 1,
            senderUsername: fromUsername,
            recipientUsername: chatUsername,
            conversationId: nil,
            createdAt: Date(),
            timer: timer,
            metadata: .messageDefault
        )

        let objectRef = try await messageObjectStore.putMessageObject(object)

        let conversationId = ConversationId.directMessage(localUsername: fromUsername, peerUsername: chatUsername)
        let currentEvents = try await conversationEventLog.fetchEvents(conversationId: conversationId.id)
        let currentHeads = try await conversationEventLog.fetchHeads(conversationId: conversationId.id)

        let event = ConversationEvent(
            id: UUID(),
            conversationId: conversationId.id,
            eventType: .messageCreated,
            objectRef: objectRef,
            actorUsername: fromUsername,
            createdAt: Date(),
            logicalClock: UInt64(currentEvents.count + 1),
            previousEventRefs: currentHeads.headRefs,
            payload: .messageCreated(timer: timer, clientMessageId: UUID().uuidString, plaintextPreview: plaintext, ciphertextPreview: payloadB64),
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

        let projected = conversationProjector.projectMessages(
            events: try await conversationEventLog.fetchEvents(conversationId: conversationId.id),
            for: chatUsername
        )
        replaceMessages(projected, for: chatUsername)
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

    private func replaceMessages(_ messages: [ChatMessage], for username: String) {
        var deduped: [ChatMessage] = []
        for message in messages {
            guard !deduped.contains(where: { $0.id == message.id }) else { continue }
            deduped.append(message)
        }
        let sorted = deduped.sorted {
            if $0.createdAt == $1.createdAt { return $0.id.uuidString < $1.id.uuidString }
            return $0.createdAt < $1.createdAt
        }
        lock.withLock { store[username] = sorted }
    }

    private func ensureSession(for chatUsername: String) throws -> SessionState {
        if let existing = sessionManager.session(for: chatUsername) {
            return existing
        }

        let remoteManager = try ensureRemoteKeyManager(for: chatUsername)
        let bundle = try sessionManager.mockRemoteBundle(for: chatUsername, kmRemote: remoteManager)
        return try sessionManager.establishSessionAsInitiator(remote: bundle)
    }

    private func ensureRemoteKeyManager(for username: String) throws -> KeyManager {
        if let existing = lock.withLock({ remoteKeyManagers[username] }) {
            return existing
        }

        let keyManager = KeyManager(service: "veil.keys.remote.\(username)")
        let seed = Data(SHA256.hash(data: Data("veil.remote.\(username)".utf8)))
        try keyManager.bootstrapIdentityIfNeeded(seed: seed)
        lock.withLock { remoteKeyManagers[username] = keyManager }
        return keyManager
    }

    private func deterministicThreadId(for username: String) -> UUID {
        if let existing = lock.withLock({ threadIdByUsername[username] }) {
            return existing
        }

        let digest = SHA256.hash(data: Data("thread.\(username)".utf8))
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
        lock.withLock { threadIdByUsername[username] = id }
        return id
    }

    private func seedDeterministicChats() {
        let base = Date(timeIntervalSince1970: 1_738_900_000) // fixed anchor for deterministic previews/order

        store = [
            "unknown_veil": [
                ChatMessage(
                    id: stableUUID("00000000-0000-0000-0000-000000000111"),
                    chatUsername: "unknown_veil",
                    direction: .incoming,
                    ciphertext: "seed",
                    plaintextPreview: "Hello!",
                    createdAt: base.addingTimeInterval(-2700),
                    timer: .hour1,
                    state: .sent
                )
            ],
            "maya": [
                ChatMessage(
                    id: stableUUID("00000000-0000-0000-0000-000000000112"),
                    chatUsername: "maya",
                    direction: .incoming,
                    ciphertext: "seed",
                    plaintextPreview: "Dinner tonight?",
                    createdAt: base.addingTimeInterval(-600),
                    timer: .hour1,
                    state: .sent
                )
            ],
            "aiden": [
                ChatMessage(
                    id: stableUUID("00000000-0000-0000-0000-000000000113"),
                    chatUsername: "aiden",
                    direction: .outgoing,
                    ciphertext: "seed",
                    plaintextPreview: "On my way 🚕",
                    createdAt: base.addingTimeInterval(-1200),
                    timer: .minutes5,
                    state: .sent
                )
            ],
            "studio_ops": [
                ChatMessage(
                    id: stableUUID("00000000-0000-0000-0000-000000000114"),
                    chatUsername: "studio_ops",
                    direction: .incoming,
                    ciphertext: "seed",
                    plaintextPreview: "Build finished successfully",
                    createdAt: base.addingTimeInterval(-3600),
                    timer: .day1,
                    state: .sent
                )
            ]
        ]

        threadIdByUsername = [
            "unknown_veil": stableUUID("10000000-0000-0000-0000-000000000001"),
            "maya": stableUUID("10000000-0000-0000-0000-000000000002"),
            "aiden": stableUUID("10000000-0000-0000-0000-000000000003"),
            "studio_ops": stableUUID("10000000-0000-0000-0000-000000000004")
        ]
    }
}

extension MockChatRepository {
    func listChats() -> [ChatThread] {
        // Derive threads from store. Deterministic sort by last message date desc.
        lock.withLock { store }
            .compactMap { (username, msgs) -> ChatThread? in
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
//extension MockChatRepository {
//    
//    func ensureChatExists(username: String) {
//        _ = loadMessages(chatUsername: username)
//    }
//}
