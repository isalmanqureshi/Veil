//
//  ChatViewModel.swift
//  Veil
//
//  Created by Salman Qureshi on 2/10/26.
//

import Foundation
import SwiftUI
/*
 In real encryption you won’t keep plaintext; you’d re-encrypt from original local draft before clearing or store it encrypted locally. For mock, this is fine.
 */
@MainActor
final class ChatViewModel: ObservableObject {

    @Published var messages: [ChatMessage] = []
    @Published var draftText: String = ""
    @Published var selectedTimer: MessageTimer = .hour1
    @Published var makeDefaultForChat: Bool = false
    @Published var showTimerSelector: Bool = false
    @Published var isUploadingAttachment: Bool = false
    @Published var attachmentStatus: String?

    private let chatUsername: String
    private let repo: ChatRepository
    private var pendingOutgoingPlaintext: [UUID: String] = [:]

    init(chatUsername: String, repo: ChatRepository) {
        self.chatUsername = chatUsername
        self.repo = repo
        self.messages = repo.loadMessages(chatUsername: chatUsername)
    }

    var canSend: Bool {
        !draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        // timer is always selected (default .hour1)
    }

    func sendTapped() {
        guard canSend else { return }

        let text = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        draftText = ""

        // Insert local "sending" bubble immediately (ciphertext placeholder)
        let local = ChatMessage(
            id: UUID(),
            chatUsername: chatUsername,
            direction: .outgoing,
            ciphertext: "encrypting…",
            plaintextPreview: text,
            createdAt: Date(),
            timer: selectedTimer,
            state: .sending
        )
        messages.append(local)
        pendingOutgoingPlaintext[local.id] = text

        Task {
            await sendWithSilentRetry(localId: local.id, plaintext: text)
        }
    }

    private func sendWithSilentRetry(localId: UUID, plaintext: String) async {
        do {
            let sent = try await repo.sendMessage(
                chatUsername: chatUsername,
                plaintext: plaintext,
                timer: selectedTimer
            )
            replace(localId: localId, with: sent)

        } catch {
            // Silent retry once (no user-facing error yet)
            do {
                try await Task.sleep(nanoseconds: 600_000_000) // 600ms backoff
                let sent = try await repo.sendMessage(
                    chatUsername: chatUsername,
                    plaintext: plaintext,
                    timer: selectedTimer
                )
                replace(localId: localId, with: sent)
            } catch {
                markFailed(localId: localId)
            }
        }
    }

    private func replace(localId: UUID, with sent: ChatMessage) {
        guard let idx = messages.firstIndex(where: { $0.id == localId }) else { return }
        messages[idx] = sent
        pendingOutgoingPlaintext.removeValue(forKey: localId)
    }

    private func markFailed(localId: UUID) {
        guard let idx = messages.firstIndex(where: { $0.id == localId }) else { return }
        var m = messages[idx]
        m.state = .failed
        messages[idx] = m
    }

    func retryFailed(_ message: ChatMessage) {
        guard message.state == .failed else { return }
        guard let plaintext = pendingOutgoingPlaintext[message.id] else { return }
        // “Silent retry” on tap; no big banners
        if let idx = messages.firstIndex(where: { $0.id == message.id }) {
            messages[idx].state = .sending
        }
        Task {
            await sendWithSilentRetry(localId: message.id, plaintext: plaintext)
        }
    }
    /**
     TO:DO - Attachment requirements (how to wire, mock-first)
     When you implement attachments, enforce these steps in order:

     Validate size (<= maxBytes)

     Strip metadata (EXIF)

     Encrypt locally

     Upload encrypted blob

     Send message referencing upload id/URL
     */
    func addAttachment(_ attachment: AttachmentDraft, svc: AttachmentService) async {
        guard attachment.bytes <= svc.maxBytes else {
            attachmentStatus = "Attachment exceeds \(svc.maxBytes / (1024 * 1024)) MB limit"
            return
        }

        isUploadingAttachment = true
        attachmentStatus = "Preparing attachment…"
        let stripped = svc.stripMetadata(attachment)
        attachmentStatus = "Encrypting attachment…"
        let encrypted = svc.encryptForUpload(stripped, recipient: chatUsername)

        do {
            let uploadRef = try await svc.upload(encrypted)
            attachmentStatus = "Attachment uploaded securely"

            let attachmentMessage = ChatMessage(
                id: UUID(),
                chatUsername: chatUsername,
                direction: .outgoing,
                ciphertext: "attachment:\(uploadRef)",
                plaintextPreview: attachment.fileName,
                createdAt: Date(),
                timer: selectedTimer,
                state: .sent
            )
            messages.append(attachmentMessage)
        } catch {
            attachmentStatus = "Attachment upload failed"
        }

        isUploadingAttachment = false
    }
}
