//
//  MessageRequestThread.swift
//  Veil
//
//  Created by Salman Qureshi on 2/10/26.
//
import Foundation

struct RequestSignals: Equatable {
    enum ProofOfWork: Equatable {
        case none
        case verified(difficulty: Int)        // “Did work” to send
        case required(difficulty: Int)        // You require it (policy)
    }

    enum RateLimit: Equatable {
        case none
        case light
        case heavy
        case throttled(until: Date)           // sender currently throttled
    }

    var pow: ProofOfWork = .none
    var rateLimit: RateLimit = .none
    var isFirstContact: Bool = true
    var confidenceNote: String? = nil        // optional 1-line calm note
}

struct MessageRequestThread: Identifiable, Equatable {
    let id: UUID
    let fromUsername: String
    let previewCiphertext: String
    let createdAt: Date
    /**
     To integrate TrustCenter signals later without refactoring everything, add an optional signals field.
     */
    var signals: RequestSignals = .init()
}

protocol MessageRequestsRepository {
    func loadRequests() -> [MessageRequestThread]
    func accept(requestId: UUID) -> String
    func ignore(requestId: UUID)
}

final class MockMessageRequestsRepository: MessageRequestsRepository {
    
    private var requests: [MessageRequestThread]
    private let chatRepo: MockChatRepository
    private var blockedUsernames: Set<String> = []
    
    init(chatRepo: MockChatRepository) {
        self.chatRepo = chatRepo
        //You can vary this per sender (e.g., “heavy” for spammy-looking usernames) deterministically.
        self.requests = [
            MessageRequestThread(
                id: UUID(uuidString: "99999999-8888-7777-6666-555555555555")!,
                fromUsername: "unknown_veil",
                previewCiphertext: "enc(you):?olleH",
                createdAt: Date().addingTimeInterval(-1800),
                signals: RequestSignals(
                    pow: .verified(difficulty: 18),
                    rateLimit: .light,
                    isFirstContact: true,
                    confidenceNote: "New sender • Rate-limited"
                )
            )
        ]
    }
    
    func loadRequests() -> [MessageRequestThread] {
        requests.filter { !blockedUsernames.contains($0.fromUsername) }
    }
    
    func accept(requestId: UUID) -> String {
        guard let req = requests.first(where: { $0.id == requestId }) else { return "" }
        requests.removeAll { $0.id == requestId }
        
        // Seed chat history deterministically on accept
        // chatRepo.ensureChatExists(username: req.fromUsername)
        _ = chatRepo.loadMessages(chatUsername: req.fromUsername)
        
        return req.fromUsername
    }
    
    func ignore(requestId: UUID) {
        requests.removeAll { $0.id == requestId }
    }
    
    // Added behaviors
    func block(requestId: UUID) {
        guard let req = requests.first(where: { $0.id == requestId }) else { return }
        blockedUsernames.insert(req.fromUsername)
        ignore(requestId: requestId)
    }
    
    func report(requestId: UUID, reason: String) {
        // MVP: treat as ignore + potential future TrustCenter log
        ignore(requestId: requestId)
    }
}

extension MessageRequestsRepository {
    
    /// Optional: remove request + mark sender blocked
    func block(requestId: UUID) {
        // default no-op (keeps existing implementations working)
        ignore(requestId: requestId)
    }
    
    /// Optional: remove request + record report
    func report(requestId: UUID, reason: String) {
        // default behavior: ignore the request
        ignore(requestId: requestId)
    }
}


