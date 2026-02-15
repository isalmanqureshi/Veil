//
//  InboxViewModel.swift
//  Veil
//
//  Created by Salman Qureshi on 2/10/26.
//

import SwiftUI

@MainActor
final class InboxViewModel: ObservableObject {

    enum Tab: String, CaseIterable { case chats = "Chats", requests = "Requests" }

    @Published var selectedTab: Tab = .chats
    @Published var chats: [ChatThread] = []
    @Published var requests: [MessageRequestThread] = []

    private let chatRepo: ChatRepository
    private let requestsRepo: MessageRequestsRepository

    init(chatRepo: ChatRepository, requestsRepo: MessageRequestsRepository) {
        self.chatRepo = chatRepo
        self.requestsRepo = requestsRepo
        reload()
    }

    func reload() {
        chats = chatRepo.listChats().sorted(by: {
            if $0.lastAt == $1.lastAt { return $0.username < $1.username }
            return $0.lastAt > $1.lastAt
        })
        requests = requestsRepo.loadRequests().sorted(by: { $0.createdAt > $1.createdAt })
    }

    func accept(_ req: MessageRequestThread) -> String {
        let username = requestsRepo.accept(requestId: req.id)
        reload()
        return username
    }

    func ignore(_ req: MessageRequestThread) {
        requestsRepo.ignore(requestId: req.id)
        reload()
    }
}
