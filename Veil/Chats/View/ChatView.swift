//
//  ChatView.swift
//  Veil
//
//  Created by Salman Qureshi on 2/5/26.
//

import SwiftUI

struct ChatView: View {

    let username: String
    @StateObject private var vm: ChatViewModel
    private let attachmentService: AttachmentService

    @FocusState private var isComposerFocused: Bool
    @State private var showAttachmentOptions = false
    @State private var isRecordingVoiceNote = false

    init(
        username: String,
        repo: ChatRepository,
        attachmentService: AttachmentService = MockAttachmentService()
    ) {
        self.username = username
        self.attachmentService = attachmentService
        _vm = StateObject(wrappedValue: ChatViewModel(chatUsername: username, repo: repo))
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(vm.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                            .onTapGesture {
                                if message.state == .failed {
                                    vm.retryFailed(message)
                                }
                            }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .onAppear { scrollToBottom(proxy) }
            .onChange(of: vm.messages.count) { _, _ in scrollToBottom(proxy) }
            .onChange(of: isComposerFocused) { _, _ in scrollToBottom(proxy) }
            .safeAreaInset(edge: .bottom) {
                ChatComposerView(
                    vm: vm,
                    isFocused: $isComposerFocused,
                    showAttachmentOptions: $showAttachmentOptions,
                    isRecording: $isRecordingVoiceNote,
                    onSend: sendFromComposer,
                    onEmojiTap: { vm.draftText.append("🙂") },
                    onMicRelease: sendMockVoiceNote
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
            }
        }
        .navigationTitle(username)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Image(systemName: "shield.fill")
                    .accessibilityLabel("Verification status")
                Button { } label: {
                    Image(systemName: "lock")
                }
                .accessibilityLabel("Privacy controls")
            }
        }
        .sheet(isPresented: $vm.showTimerSelector) {
            MessageTimerSelectorView(
                selectedTimer: $vm.selectedTimer,
                makeDefault: $vm.makeDefaultForChat
            )
        }
        .confirmationDialog("Attachment", isPresented: $showAttachmentOptions) {
            Button("Attach Test Image (2.1 MB)") {
                sendAttachment(named: "test-image.jpg", bytes: 2_100_000, mime: "image/jpeg")
            }
            Button("Attach Large File (12 MB)") {
                sendAttachment(named: "large-file.bin", bytes: 12_000_000, mime: "application/octet-stream")
            }
            Button("Cancel", role: .cancel) { }
        }
    }

    private func sendFromComposer() {
        guard vm.canSend else { return }
        vm.sendTapped()
    }

    private func sendAttachment(named: String, bytes: Int, mime: String) {
        let draft = AttachmentDraft(fileName: named, bytes: bytes, mimeType: mime)
        Task {
            await vm.addAttachment(draft, svc: attachmentService)
        }
    }

    private func sendMockVoiceNote() {
        sendAttachment(named: "voice.m4a", bytes: 120_000, mime: "audio/m4a")
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        guard let last = vm.messages.last?.id else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(last, anchor: .bottom)
        }
    }
}


private struct ChatComposerView: View {

    @ObservedObject var vm: ChatViewModel
    var isFocused: FocusState<Bool>.Binding
    @Binding var showAttachmentOptions: Bool
    @Binding var isRecording: Bool
    @State private var micPressStartedAt: Date?

    let onSend: () -> Void
    let onEmojiTap: () -> Void
    let onMicRelease: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            if let status = vm.attachmentStatus {
                HStack(spacing: 8) {
                    Image(systemName: vm.isUploadingAttachment ? "arrow.trianglehead.2.clockwise" : "checkmark.shield")
                        .font(.system(size: 12, weight: .semibold))
                    Text(status)
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                }
                .foregroundStyle(.secondary)
            }

            if isRecording {
                Text("Recording… release to send voice note")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 10) {
                Button {
                    showAttachmentOptions = true
                } label: {
                    Image(systemName: "paperclip")
                }
                .disabled(vm.isUploadingAttachment)

                Button(action: onEmojiTap) {
                    Image(systemName: "face.smiling")
                }
                .accessibilityLabel("Insert emoji")

                TextField("Message", text: $vm.draftText, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .focused(isFocused)
                    .submitLabel(.send)
                    .onSubmit(onSend)

                Button {
                    vm.showTimerSelector = true
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "timer")
                        Text(vm.selectedTimer.rawValue)
                            .font(.system(size: 10, weight: .medium))
                    }
                }
                .accessibilityLabel("Message timer")

                Button(action: onSend) {
                    Image(systemName: "paperplane.circle.fill")
                        .font(.system(size: 28, weight: .semibold))
                }
                .disabled(!vm.canSend)
                .opacity(vm.canSend ? 1 : 0.4)
                .accessibilityLabel("Send")

                Image(systemName: "mic.fill")
                    .foregroundStyle(.secondary)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                guard micPressStartedAt == nil else { return }
                                micPressStartedAt = Date()
                                isRecording = true
                            }
                            .onEnded { _ in
                                let startedAt = micPressStartedAt
                                micPressStartedAt = nil

                                guard isRecording else { return }
                                isRecording = false

                                guard let startedAt,
                                      Date().timeIntervalSince(startedAt) >= 0.25 else { return }

                                onMicRelease()
                            }
                    )
                    .accessibilityLabel("Hold to record voice note")
            }
        }
        .onDisappear {
            isRecording = false
            micPressStartedAt = nil
        }
    }
}

#Preview {
    ChatView(username: "maya", repo: MockChatRepository(crypto: MockCryptoService()))
}
