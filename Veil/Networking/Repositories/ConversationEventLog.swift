import Foundation
import CryptoKit

struct ConversationId: Codable, Hashable, Equatable {
    let id: String

    static func directMessage(localUsername: String, peerUsername: String) -> ConversationId {
        let normalized = [localUsername.lowercased(), peerUsername.lowercased()].sorted()
        return ConversationId(id: "dm:\(normalized[0])|\(normalized[1])")
    }
}

enum ConversationEventKind: String, Codable {
    case messageCreated
    case attachmentAdded
    case messageDeletedLocal
    case timerUpdated
    case requestAccepted
    case participantStateChanged
    case systemNote
}

struct ConversationEventRef: Codable, Equatable {
    let id: String
    let contentAddress: String?
    let locator: String?
    let createdAt: Date
}

struct ConversationEventPayload: Codable, Equatable {
    let timerRaw: String?
    let clientMessageId: String?
    let attachmentFileName: String?
    let attachmentMimeType: String?
    let updatedTimerRaw: String?
    let requestAccepted: Bool?
    let plaintextPreview: String?
    let ciphertextPreview: String?
    let messageStateRaw: String?

    static func messageCreated(timer: MessageTimer, clientMessageId: String, plaintextPreview: String, ciphertextPreview: String) -> ConversationEventPayload {
        ConversationEventPayload(
            timerRaw: timer.rawValue,
            clientMessageId: clientMessageId,
            attachmentFileName: nil,
            attachmentMimeType: nil,
            updatedTimerRaw: nil,
            requestAccepted: nil,
            plaintextPreview: plaintextPreview,
            ciphertextPreview: ciphertextPreview,
            messageStateRaw: "sent"
        )
    }
}

struct ConversationEvent: Codable, Equatable {
    let id: UUID
    let conversationId: String
    let eventType: ConversationEventKind
    let objectRef: MessageObjectRef?
    let actorUsername: String
    let createdAt: Date
    let logicalClock: UInt64
    let previousEventRefs: [ConversationEventRef]
    let payload: ConversationEventPayload
    let signature: String?
}

struct ConversationLogHead: Codable, Equatable {
    let conversationId: String
    let headRefs: [ConversationEventRef]
    let updatedAt: Date
}

protocol ConversationEventLog {
    func append(_ event: ConversationEvent) async throws -> ConversationEventRef
    func fetchEvents(conversationId: String) async throws -> [ConversationEvent]
    func fetchHeads(conversationId: String) async throws -> ConversationLogHead
    func mergeHeads(conversationId: String, incoming: [ConversationEventRef]) async throws
    func compactIfNeeded(conversationId: String) async throws
}

protocol ConversationProjector {
    func projectMessages(events: [ConversationEvent], for chatUsername: String) -> [ChatMessage]
    func projectThread(events: [ConversationEvent], peerUsername: String) -> ChatThread?
}

struct DefaultConversationProjector: ConversationProjector {
    private let fallbackLocalUsername: String

    init(localUsername: String) {
        self.fallbackLocalUsername = localUsername
    }

    func projectMessages(events: [ConversationEvent], for chatUsername: String) -> [ChatMessage] {
        events
            .filter { $0.eventType == .messageCreated || $0.eventType == .attachmentAdded }
            .sorted(by: eventSort)
            .map { event in
                let localUsername = LocalAuthContext().currentUsername() ?? fallbackLocalUsername
                let isOutgoing = event.actorUsername.lowercased() == localUsername.lowercased()
                let direction: ChatMessage.Direction = isOutgoing ? .outgoing : .incoming
                let timer = MessageTimer(rawValue: event.payload.timerRaw ?? "") ?? .hour1
                let state: ChatMessage.SendState = {
                    switch event.payload.messageStateRaw {
                    case "sending": return .sending
                    case "failed": return .failed
                    default: return .sent
                    }
                }()

                let plaintextPreview = event.payload.plaintextPreview
                    ?? event.payload.attachmentFileName
                    ?? ""
                let ciphertext = event.payload.ciphertextPreview
                    ?? "event:\(event.objectRef?.id ?? event.id.uuidString)"

                return ChatMessage(
                    id: event.id,
                    chatUsername: chatUsername,
                    direction: direction,
                    ciphertext: ciphertext,
                    plaintextPreview: plaintextPreview,
                    createdAt: event.createdAt,
                    timer: timer,
                    state: state
                )
            }
    }

    func projectThread(events: [ConversationEvent], peerUsername: String) -> ChatThread? {
        guard let last = projectMessages(events: events, for: peerUsername).max(by: { $0.createdAt < $1.createdAt }) else {
            return nil
        }

        return ChatThread(
            id: stableThreadUUID("thread.projected.\(peerUsername)"),
            username: peerUsername,
            lastPreview: last.plaintextPreview,
            lastAt: last.createdAt
        )
    }

    private func eventSort(lhs: ConversationEvent, rhs: ConversationEvent) -> Bool {
        if lhs.logicalClock == rhs.logicalClock {
            if lhs.createdAt == rhs.createdAt {
                return lhs.id.uuidString < rhs.id.uuidString
            }
            return lhs.createdAt < rhs.createdAt
        }
        return lhs.logicalClock < rhs.logicalClock
    }
}

final class InMemoryConversationEventLog: ConversationEventLog {
    private let lock = NSLock()
    private var eventsByConversationId: [String: [ConversationEvent]] = [:]
    private var headsByConversationId: [String: ConversationLogHead] = [:]

    func append(_ event: ConversationEvent) async throws -> ConversationEventRef {
        let ref = ConversationEventRef(id: event.id.uuidString, contentAddress: nil, locator: event.id.uuidString, createdAt: event.createdAt)

        lock.withLock {
            var events = eventsByConversationId[event.conversationId, default: []]
            events.append(event)
            events.sort(by: Self.eventSort)
            eventsByConversationId[event.conversationId] = events

            headsByConversationId[event.conversationId] = ConversationLogHead(
                conversationId: event.conversationId,
                headRefs: [ref],
                updatedAt: Date()
            )
        }

        return ref
    }

    func fetchEvents(conversationId: String) async throws -> [ConversationEvent] {
        lock.withLock { eventsByConversationId[conversationId, default: []].sorted(by: Self.eventSort) }
    }

    func fetchHeads(conversationId: String) async throws -> ConversationLogHead {
        lock.withLock {
            headsByConversationId[conversationId]
            ?? ConversationLogHead(conversationId: conversationId, headRefs: [], updatedAt: Date())
        }
    }

    func mergeHeads(conversationId: String, incoming: [ConversationEventRef]) async throws {
        lock.withLock {
            let existing = headsByConversationId[conversationId]?.headRefs ?? []
            let merged = Dictionary(uniqueKeysWithValues: (existing + incoming).map { ($0.id, $0) }).map(\.value)
            headsByConversationId[conversationId] = ConversationLogHead(conversationId: conversationId, headRefs: merged, updatedAt: Date())
        }
    }

    func compactIfNeeded(conversationId: String) async throws {
        _ = conversationId
        // No-op for now. In-memory implementation intentionally keeps a full append-only stream.
    }

    private static func eventSort(lhs: ConversationEvent, rhs: ConversationEvent) -> Bool {
        if lhs.logicalClock == rhs.logicalClock {
            if lhs.createdAt == rhs.createdAt {
                return lhs.id.uuidString < rhs.id.uuidString
            }
            return lhs.createdAt < rhs.createdAt
        }
        return lhs.logicalClock < rhs.logicalClock
    }
}

final class CentralizedConversationEventLog: ConversationEventLog {
    private let backing = InMemoryConversationEventLog()

    func append(_ event: ConversationEvent) async throws -> ConversationEventRef {
        // Current backend has no explicit append-only conversation-log API.
        // We emulate append-only behavior locally while transport remains pointer/inbox based.
        try await backing.append(event)
    }

    func fetchEvents(conversationId: String) async throws -> [ConversationEvent] {
        try await backing.fetchEvents(conversationId: conversationId)
    }

    func fetchHeads(conversationId: String) async throws -> ConversationLogHead {
        try await backing.fetchHeads(conversationId: conversationId)
    }

    func mergeHeads(conversationId: String, incoming: [ConversationEventRef]) async throws {
        // Limited centralized reconciliation until backend supports canonical multi-head merge semantics.
        try await backing.mergeHeads(conversationId: conversationId, incoming: incoming)
    }

    func compactIfNeeded(conversationId: String) async throws {
        // No-op until snapshot/compaction strategy is introduced for centralized replay.
        try await backing.compactIfNeeded(conversationId: conversationId)
    }
}

final class DecentralizedConversationEventLog: ConversationEventLog {
    func append(_ event: ConversationEvent) async throws -> ConversationEventRef {
        _ = event
        // TODO: persist event as immutable content-addressed entry and return CID-like ConversationEventRef.
        throw MessageObjectStoreError.notImplemented
    }

    func fetchEvents(conversationId: String) async throws -> [ConversationEvent] {
        _ = conversationId
        // TODO: resolve event DAG/log from decentralized storage/index infrastructure.
        throw MessageObjectStoreError.notImplemented
    }

    func fetchHeads(conversationId: String) async throws -> ConversationLogHead {
        _ = conversationId
        // TODO: track multi-head state across devices/peers.
        throw MessageObjectStoreError.notImplemented
    }

    func mergeHeads(conversationId: String, incoming: [ConversationEventRef]) async throws {
        _ = conversationId
        _ = incoming
        // TODO: implement decentralized head merge semantics.
        throw MessageObjectStoreError.notImplemented
    }

    func compactIfNeeded(conversationId: String) async throws {
        _ = conversationId
        // TODO: implement snapshot/compaction over append-only decentralized logs.
        throw MessageObjectStoreError.notImplemented
    }
}

private func stableThreadUUID(_ rawValue: String) -> UUID {
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
