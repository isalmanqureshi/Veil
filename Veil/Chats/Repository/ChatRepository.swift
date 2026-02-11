//
//  ChatRepository.swift
//  Veil
//
//  Created by Salman Qureshi on 2/10/26.
//
import SwiftUI

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

final class MockChatRepository: ChatRepository {

    private let crypto: CryptoService
    private var store: [String: [ChatMessage]] = [:]
    private var failFirstSendForChat: Set<String> = ["gfhjj"] // deterministic “first send fails”

    init(crypto: CryptoService) {
        self.crypto = crypto
    }

    func loadMessages(chatUsername: String) -> [ChatMessage] {
        if let existing = store[chatUsername] { return existing }

        // Deterministic seed messages
        let seeded: [ChatMessage] = [
            ChatMessage(
                id: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
                chatUsername: chatUsername,
                direction: .incoming,
                ciphertext: "enc(\(chatUsername)):!olleH",
                createdAt: Date().addingTimeInterval(-3600),
                timer: .hour1,
                state: .sent
            )
        ]
        store[chatUsername] = seeded
        return seeded
    }

    func sendMessage(chatUsername: String, plaintext: String, timer: MessageTimer) async throws -> ChatMessage {
        // Simulate transient failure once per specified chat (silent retry handled in VM)
        if failFirstSendForChat.contains(chatUsername) {
            failFirstSendForChat.remove(chatUsername)
            throw SendError.transient
        }

        try await Task.sleep(nanoseconds: 200_000_000)

        let ciphertext = crypto.encrypt(plaintext: plaintext, for: chatUsername)
        let msg = ChatMessage(
            id: UUID(),
            chatUsername: chatUsername,
            direction: .outgoing,
            ciphertext: ciphertext,
            createdAt: Date(),
            timer: timer,
            state: .sent
        )
        store[chatUsername, default: []].append(msg)
        return msg
    }
}

extension MockChatRepository {
    //If we want truly stable UUIDs without hash randomness, just store a dedicated threadIdByUsername dictionary in the repo. For now, this is okay for mock UI.
    
    func listChats() -> [ChatThread] {
        // Derive threads from store. Deterministic sort by last message date desc.
        store
            .compactMap { (username, msgs) -> ChatThread? in
                guard let last = msgs.max(by: { $0.createdAt < $1.createdAt }) else { return nil }
                return ChatThread(
                    id: UUID(),               // fine for mock
                    username: username,
                    lastPreview: last.ciphertext,
                    lastAt: last.createdAt
                )
            }
            .sorted(by: { $0.lastAt > $1.lastAt })
    }
}
//extension MockChatRepository {
//    
//    func ensureChatExists(username: String) {
//        _ = loadMessages(chatUsername: username)
//    }
//}
