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
    private var inFlightMessageIds: Set<UUID> = []

    init(chatUsername: String, repo: ChatRepository) {
        self.chatUsername = chatUsername
        self.repo = repo
        self.messages = Self.sortedMessages(repo.loadMessages(chatUsername: chatUsername))
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
        let timer = selectedTimer
        let local = ChatMessage(
            id: UUID(),
            chatUsername: chatUsername,
            direction: .outgoing,
            ciphertext: "encrypting…",
            plaintextPreview: text,
            createdAt: Date(),
            timer: timer,
            state: .sending
        )
        messages.append(local)
        messages = Self.sortedMessages(messages)
        pendingOutgoingPlaintext[local.id] = text
        inFlightMessageIds.insert(local.id)

        Task {
            await sendWithSilentRetry(localId: local.id, plaintext: text, timer: timer)
        }
    }

    private func sendWithSilentRetry(localId: UUID, plaintext: String, timer: MessageTimer) async {
        defer { inFlightMessageIds.remove(localId) }

        do {
            let sent = try await repo.sendMessage(
                chatUsername: chatUsername,
                plaintext: plaintext,
                timer: timer
            )
            replace(localId: localId, with: sent)

        } catch {
            // Silent retry once (no user-facing error yet)
            do {
                try await Task.sleep(nanoseconds: 600_000_000) // 600ms backoff
                let sent = try await repo.sendMessage(
                    chatUsername: chatUsername,
                    plaintext: plaintext,
                    timer: timer
                )
                replace(localId: localId, with: sent)
            } catch {
                markFailed(localId: localId)
            }
        }
    }

    private func replace(localId: UUID, with sent: ChatMessage) {
        guard let idx = messages.firstIndex(where: { $0.id == localId }) else {
            messages.append(sent)
            messages = Self.sortedMessages(messages)
            return
        }

        let optimistic = messages[idx]
        let merged = ChatMessage(
            id: optimistic.id,
            chatUsername: sent.chatUsername,
            direction: sent.direction,
            ciphertext: sent.ciphertext,
            plaintextPreview: sent.plaintextPreview,
            createdAt: sent.createdAt,
            timer: sent.timer,
            state: sent.state
        )
        messages[idx] = merged
        messages = Self.sortedMessages(messages)
        pendingOutgoingPlaintext.removeValue(forKey: localId)
    }

    private func markFailed(localId: UUID) {
        guard let idx = messages.firstIndex(where: { $0.id == localId }) else { return }
        var m = messages[idx]
        m.state = .failed
        messages[idx] = m
        messages = Self.sortedMessages(messages)
    }

    func retryFailed(_ message: ChatMessage) {
        guard message.state == .failed else { return }
        guard !inFlightMessageIds.contains(message.id) else { return }
        guard let plaintext = pendingOutgoingPlaintext[message.id] else { return }
        // “Silent retry” on tap; no big banners
        if let idx = messages.firstIndex(where: { $0.id == message.id }) {
            messages[idx].state = .sending
        }
        inFlightMessageIds.insert(message.id)
        Task {
            await sendWithSilentRetry(localId: message.id, plaintext: plaintext, timer: message.timer)
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
            messages = Self.sortedMessages(messages)
        } catch {
            attachmentStatus = "Attachment upload failed"
        }

        isUploadingAttachment = false
    }

    private static func sortedMessages(_ source: [ChatMessage]) -> [ChatMessage] {
        source.sorted {
            if $0.createdAt == $1.createdAt {
                return $0.id.uuidString < $1.id.uuidString
            }
            return $0.createdAt < $1.createdAt
        }
    }
}
