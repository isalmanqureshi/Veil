//
//  MessageRequestThread.swift
//  Veil
//
//  Created by Salman Qureshi on 2/10/26.
//
import Foundation

struct MessageRequestThread: Identifiable, Equatable {
    let id: UUID
    let fromUsername: String
    let previewCiphertext: String
    let createdAt: Date
}

protocol MessageRequestsRepository {
    func loadRequests() -> [MessageRequestThread]
    func accept(requestId: UUID) -> String
    func ignore(requestId: UUID)
}

final class MockMessageRequestsRepository: MessageRequestsRepository {

    private var requests: [MessageRequestThread]
    private let chatRepo: MockChatRepository

    init(chatRepo: MockChatRepository) {
        self.chatRepo = chatRepo
        self.requests = [
            MessageRequestThread(
                id: UUID(uuidString: "99999999-8888-7777-6666-555555555555")!,
                fromUsername: "unknown_veil",
                previewCiphertext: "enc(you):?olleH",
                createdAt: Date().addingTimeInterval(-1800)
            )
        ]
    }

    func loadRequests() -> [MessageRequestThread] {
        requests
    }

    func accept(requestId: UUID) -> String {
        guard let req = requests.first(where: { $0.id == requestId }) else { return "" }
        requests.removeAll { $0.id == requestId }

        // Seed chat history deterministically on accept
        _ = chatRepo.loadMessages(chatUsername: req.fromUsername)
        return req.fromUsername
    }

    func ignore(requestId: UUID) {
        requests.removeAll { $0.id == requestId }
    }
}

