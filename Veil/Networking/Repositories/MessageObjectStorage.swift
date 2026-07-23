import Foundation
import CryptoKit

// MARK: - Domain models for encrypted object plane

enum MessageObjectKind: String, Codable {
    case message
    case attachment
    case conversationEvent
}

struct MessageObjectRef: Codable, Equatable {
    let id: String
    let kind: MessageObjectKind
    let contentAddress: String?
    let locator: String?
    let transportHint: String?
    let createdAt: Date
}

struct MessageObjectMetadata: Codable, Equatable {
    let contentType: String?
    let byteCount: Int?
    let isEphemeral: Bool
    let expiresAt: Date?
    let attachmentFileName: String?
    let attachmentMimeType: String?

    static let messageDefault = MessageObjectMetadata(
        contentType: "application/veil-message",
        byteCount: nil,
        isEphemeral: false,
        expiresAt: nil,
        attachmentFileName: nil,
        attachmentMimeType: nil
    )
}

struct EncryptedMessageObject: Codable, Equatable {
    let ref: MessageObjectRef?
    let payloadB64: String
    let envelopeVersion: Int
    let senderUsername: String?
    let recipientUsername: String?
    let conversationId: String?
    let createdAt: Date
    let timer: MessageTimer?
    let metadata: MessageObjectMetadata
}

enum PointerDeliveryState: String, Codable {
    case pending
    case delivered
    case acked
}

struct MessagePointerEvent: Codable, Equatable {
    let id: UUID
    let toUsername: String
    let fromUsername: String
    let objectRef: MessageObjectRef
    let createdAt: Date
    let requestFlow: Bool
    let oneTimePreKeyId: UInt32?
    let deliveryState: PointerDeliveryState?
}

// MARK: - Object store / pointer interfaces

enum MessageObjectStoreError: Error {
    case notImplemented
    case notFound
    case transportFailure
    case invalidRef
}

protocol MessageObjectStore {
    func putMessageObject(_ object: EncryptedMessageObject) async throws -> MessageObjectRef
    func getMessageObject(ref: MessageObjectRef) async throws -> EncryptedMessageObject
    func putAttachmentObject(_ object: EncryptedMessageObject) async throws -> MessageObjectRef
    func pin(ref: MessageObjectRef) async throws
    func unpin(ref: MessageObjectRef) async throws
}

protocol MessagePointerPublisher {
    func publishPointer(_ event: MessagePointerEvent) async throws
    func fetchPointers(for username: String, deviceId: String?) async throws -> [MessagePointerEvent]
    func ackPointers(ids: [UUID], username: String) async throws
}

// MARK: - In-memory implementations (tests, previews, mock mode)

final class InMemoryMessageObjectStore: MessageObjectStore {
    private let lock = NSLock()
    private var objectsByRefId: [String: EncryptedMessageObject] = [:]

    func putMessageObject(_ object: EncryptedMessageObject) async throws -> MessageObjectRef {
        try put(object: object, kind: .message)
    }

    func putAttachmentObject(_ object: EncryptedMessageObject) async throws -> MessageObjectRef {
        try put(object: object, kind: .attachment)
    }

    func getMessageObject(ref: MessageObjectRef) async throws -> EncryptedMessageObject {
        try lock.withLock {
            guard let object = objectsByRefId[ref.id] else {
                throw MessageObjectStoreError.notFound
            }
            return object
        }
    }

    func pin(ref: MessageObjectRef) async throws {
        _ = ref
    }

    func unpin(ref: MessageObjectRef) async throws {
        _ = ref
    }

    @discardableResult
    private func put(object: EncryptedMessageObject, kind: MessageObjectKind) throws -> MessageObjectRef {
        let now = Date()
        let idSource = "\(object.senderUsername ?? "")|\(object.recipientUsername ?? "")|\(object.createdAt.timeIntervalSince1970)|\(object.payloadB64)"
        let digest = SHA256.hash(data: Data(idSource.utf8))
        let refId = digest.compactMap { String(format: "%02x", $0) }.joined()

        let ref = MessageObjectRef(
            id: refId,
            kind: kind,
            contentAddress: nil,
            locator: refId,
            transportHint: "in-memory",
            createdAt: now
        )

        let stored = EncryptedMessageObject(
            ref: ref,
            payloadB64: object.payloadB64,
            envelopeVersion: object.envelopeVersion,
            senderUsername: object.senderUsername,
            recipientUsername: object.recipientUsername,
            conversationId: object.conversationId,
            createdAt: object.createdAt,
            timer: object.timer,
            metadata: object.metadata
        )

        lock.withLock {
            objectsByRefId[ref.id] = stored
        }

        return ref
    }
}

final class InMemoryPointerPublisher: MessagePointerPublisher {
    private let lock = NSLock()
    private var queueByUsername: [String: [MessagePointerEvent]] = [:]

    func publishPointer(_ event: MessagePointerEvent) async throws {
        lock.withLock {
            var queue = queueByUsername[event.toUsername, default: []]
            queue.append(event)
            queueByUsername[event.toUsername] = queue
        }
    }

    func fetchPointers(for username: String, deviceId: String?) async throws -> [MessagePointerEvent] {
        _ = deviceId
        return lock.withLock { queueByUsername[username, default: []] }
    }

    func ackPointers(ids: [UUID], username: String) async throws {
        let idSet = Set(ids)
        lock.withLock {
            var queue = queueByUsername[username, default: []]
            queue.removeAll { idSet.contains($0.id) }
            queueByUsername[username] = queue
        }
    }
}

// MARK: - Centralized adapters for current backend

final class CentralizedMessageObjectStore: MessageObjectStore {
    private let lock = NSLock()
    private var objectsByRefId: [String: EncryptedMessageObject] = [:]

    func putMessageObject(_ object: EncryptedMessageObject) async throws -> MessageObjectRef {
        try put(object: object, kind: .message)
    }

    func putAttachmentObject(_ object: EncryptedMessageObject) async throws -> MessageObjectRef {
        try put(object: object, kind: .attachment)
    }

    func getMessageObject(ref: MessageObjectRef) async throws -> EncryptedMessageObject {
        try lock.withLock {
            guard let object = objectsByRefId[ref.id] else {
                // Current backend exposes inbox polling rather than a generic object lookup endpoint.
                // The centralized adapter therefore resolves objects from locally cached send/inbox payloads.
                throw MessageObjectStoreError.notFound
            }
            return object
        }
    }

    func pin(ref: MessageObjectRef) async throws {
        _ = ref
        // No-op for centralized backend.
    }

    func unpin(ref: MessageObjectRef) async throws {
        _ = ref
        // No-op for centralized backend.
    }

    func cacheIncoming(serverMessageId: String, envelope: InboxEnvelopeDTO) {
        let ref = MessageObjectRef(
            id: serverMessageId,
            kind: .message,
            contentAddress: nil,
            locator: serverMessageId,
            transportHint: "centralized",
            createdAt: envelope.queuedAt
        )

        let object = EncryptedMessageObject(
            ref: ref,
            payloadB64: envelope.payloadB64,
            envelopeVersion: envelope.envelopeVersion,
            senderUsername: envelope.fromUsername,
            recipientUsername: envelope.toUsername,
            conversationId: nil,
            createdAt: envelope.queuedAt,
            timer: envelope.timer.flatMap(MessageTimer.init(rawValue:)),
            metadata: .messageDefault
        )

        lock.withLock {
            objectsByRefId[ref.id] = object
        }
    }

    private func put(object: EncryptedMessageObject, kind: MessageObjectKind) throws -> MessageObjectRef {
        let generatedId = UUID().uuidString
        let ref = MessageObjectRef(
            id: generatedId,
            kind: kind,
            contentAddress: nil,
            locator: generatedId,
            transportHint: "centralized",
            createdAt: Date()
        )

        let stored = EncryptedMessageObject(
            ref: ref,
            payloadB64: object.payloadB64,
            envelopeVersion: object.envelopeVersion,
            senderUsername: object.senderUsername,
            recipientUsername: object.recipientUsername,
            conversationId: object.conversationId,
            createdAt: object.createdAt,
            timer: object.timer,
            metadata: object.metadata
        )

        lock.withLock {
            objectsByRefId[ref.id] = stored
        }

        return ref
    }
}

final class CentralizedPointerPublisher: MessagePointerPublisher {
    private let messagesService: MessagesService
    private let messageObjectStore: CentralizedMessageObjectStore

    private let lock = NSLock()
    private var serverMessageIdByPointerId: [UUID: String] = [:]

    init(messagesService: MessagesService, messageObjectStore: CentralizedMessageObjectStore) {
        self.messagesService = messagesService
        self.messageObjectStore = messageObjectStore
    }

    func publishPointer(_ event: MessagePointerEvent) async throws {
        // Current backend couples pointer publish + payload send in one endpoint.
        // We keep the abstraction split so future decentralized adapters can send pointers independently.
        let object = try await messageObjectStore.getMessageObject(ref: event.objectRef)
        let request = SendMessageRequestDTO(
            fromUsername: event.fromUsername,
            toUsername: event.toUsername,
            deviceId: LocalAuthContext().currentDeviceId(),
            payloadB64: object.payloadB64,
            envelopeVersion: object.envelopeVersion,
            oneTimePreKeyId: event.oneTimePreKeyId,
            timer: object.timer?.rawValue,
            clientMessageId: event.id.uuidString
        )

        let response = try await messagesService.sendEnvelope(request)

        // Store outgoing payload under server message id for parity with incoming references.
        let envelope = InboxEnvelopeDTO(
            serverMessageId: response.serverMessageId,
            fromUsername: event.fromUsername,
            toUsername: event.toUsername,
            deviceId: LocalAuthContext().currentDeviceId(),
            payloadB64: object.payloadB64,
            envelopeVersion: object.envelopeVersion,
            queuedAt: Date(),
            timer: object.timer?.rawValue
        )
        messageObjectStore.cacheIncoming(serverMessageId: response.serverMessageId, envelope: envelope)
    }

    func fetchPointers(for username: String, deviceId: String?) async throws -> [MessagePointerEvent] {
        let effectiveDeviceId = deviceId ?? LocalAuthContext().currentDeviceId()
        let response = try await messagesService.pollInbox(username: username, deviceId: effectiveDeviceId)

        return response.messages.map { envelope in
            messageObjectStore.cacheIncoming(serverMessageId: envelope.serverMessageId, envelope: envelope)

            let ref = MessageObjectRef(
                id: envelope.serverMessageId,
                kind: .message,
                contentAddress: nil,
                locator: envelope.serverMessageId,
                transportHint: "centralized",
                createdAt: envelope.queuedAt
            )
            let pointerId = stablePointerUUID("pointer.centralized.\(envelope.serverMessageId)")
            lock.withLock {
                serverMessageIdByPointerId[pointerId] = envelope.serverMessageId
            }

            return MessagePointerEvent(
                id: pointerId,
                toUsername: envelope.toUsername,
                fromUsername: envelope.fromUsername,
                objectRef: ref,
                createdAt: envelope.queuedAt,
                requestFlow: false,
                oneTimePreKeyId: nil,
                deliveryState: .delivered
            )
        }
    }

    func ackPointers(ids: [UUID], username: String) async throws {
        let serverIds: [String] = lock.withLock {
            ids.compactMap { serverMessageIdByPointerId[$0] }
        }

        guard !serverIds.isEmpty else { return }
        let deduped = Array(Set(serverIds))
        _ = try await messagesService.ackMessages(
            AckMessagesRequestDTO(username: username, deviceId: LocalAuthContext().currentDeviceId(), messageIds: deduped)
        )

        lock.withLock {
            ids.forEach { serverMessageIdByPointerId.removeValue(forKey: $0) }
        }
    }
}

// MARK: - Decentralized adapter seams (stubs)

final class DecentralizedMessageObjectStore: MessageObjectStore {
    func putMessageObject(_ object: EncryptedMessageObject) async throws -> MessageObjectRef {
        _ = object
        // TODO: store encrypted payload as content-addressed block and return CID-backed MessageObjectRef.
        throw MessageObjectStoreError.notImplemented
    }

    func getMessageObject(ref: MessageObjectRef) async throws -> EncryptedMessageObject {
        _ = ref
        // TODO: resolve `contentAddress` and fetch encrypted block via decentralized transport.
        throw MessageObjectStoreError.notImplemented
    }

    func putAttachmentObject(_ object: EncryptedMessageObject) async throws -> MessageObjectRef {
        _ = object
        throw MessageObjectStoreError.notImplemented
    }

    func pin(ref: MessageObjectRef) async throws {
        _ = ref
        // TODO: request local or relay pinning for content-addressed data.
        throw MessageObjectStoreError.notImplemented
    }

    func unpin(ref: MessageObjectRef) async throws {
        _ = ref
        // TODO: release local or relay pin.
        throw MessageObjectStoreError.notImplemented
    }
}

final class DecentralizedPointerPublisher: MessagePointerPublisher {
    func publishPointer(_ event: MessagePointerEvent) async throws {
        _ = event
        // TODO: publish encrypted pointer event through decentralized relay/index/pubsub mesh.
        throw MessageObjectStoreError.notImplemented
    }

    func fetchPointers(for username: String, deviceId: String?) async throws -> [MessagePointerEvent] {
        _ = username
        _ = deviceId
        throw MessageObjectStoreError.notImplemented
    }

    func ackPointers(ids: [UUID], username: String) async throws {
        _ = ids
        _ = username
        throw MessageObjectStoreError.notImplemented
    }
}

private func stablePointerUUID(_ rawValue: String) -> UUID {
    let digest = SHA256.hash(data: Data(rawValue.utf8))
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
