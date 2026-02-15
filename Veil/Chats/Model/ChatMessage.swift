//
//  ChatMessage.swift
//  Veil
//
//  Created by Salman Qureshi on 2/10/26.
//
import SwiftUI

struct ChatMessage: Identifiable, Equatable {
    enum Direction { case outgoing, incoming }
    enum SendState { case sending, sent, failed }

    let id: UUID
    let chatUsername: String
    let direction: Direction
    let ciphertext: String          // store ciphertext (mock)
    let plaintextPreview: String
    let createdAt: Date
    let timer: MessageTimer
    var state: SendState
}

struct AttachmentDraft {
    let id = UUID()
    let fileName: String
    let bytes: Int
    let mimeType: String
}

struct ChatThread: Identifiable, Equatable {
    let id: UUID
    let username: String
    let lastPreview: String
    let lastAt: Date
}
