//
//  Redesign+Chat.swift
//  Veil
//
//  Chat thread: encrypted-conversation header, message bubbles, composer,
//  disappearing-timer sheet. The view model mocks send/retry locally so the
//  screen is fully interactive in previews — no networking, no crypto.
//

import SwiftUI

extension Redesign {

    // MARK: - View model

    @MainActor
    final class ChatViewModel: ObservableObject {
        @Published var messages: [ChatMessage]
        @Published var draft = ""
        @Published var selectedTimer: MessageTimer = .hour1
        @Published var showTimerSheet = false

        let peerUsername: String

        init(peerUsername: String, messages: [ChatMessage]) {
            self.peerUsername = peerUsername
            self.messages = messages.sorted(by: { $0.createdAt < $1.createdAt })
        }

        func send() {
            let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return }
            draft = ""

            let optimistic = ChatMessage(
                id: UUID(),
                chatUsername: peerUsername,
                direction: .outgoing,
                ciphertext: "encrypting…",
                plaintextPreview: text,
                createdAt: .now,
                timer: selectedTimer,
                state: .sending
            )
            messages.append(optimistic)

            // Mock delivery: flip to .sent shortly after (real app: repository call).
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(1.2))
                self?.markSent(optimistic.id)
            }
        }

        func retry(_ message: ChatMessage) {
            guard message.state == .failed,
                  let index = messages.firstIndex(where: { $0.id == message.id }) else { return }
            messages[index].state = .sending
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(1))
                self?.markSent(message.id)
            }
        }

        private func markSent(_ id: UUID) {
            guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
            messages[index].state = .sent
        }
    }

    // MARK: - Screen

    struct ChatView: View {
        @StateObject private var vm: ChatViewModel

        init(peerUsername: String, messages: [ChatMessage]) {
            _vm = StateObject(wrappedValue: ChatViewModel(peerUsername: peerUsername, messages: messages))
        }

        var body: some View {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.s) {
                        encryptionHeader
                            .padding(.top, Theme.Spacing.m)

                        if vm.messages.isEmpty {
                            EmptyState.emptyChat
                                .padding(.top, Theme.Spacing.xl)
                        }

                        ForEach(vm.messages) { message in
                            MessageBubble(message: message) {
                                vm.retry(message)
                            }
                            .id(message.id)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.bottom, Theme.Spacing.s)
                }
                .scrollDismissesKeyboard(.interactively)
                .onAppear { scrollToBottom(proxy, animated: false) }
                .onChange(of: vm.messages.last?.id) { _, _ in scrollToBottom(proxy, animated: true) }
            }
            .background(Theme.Colors.background)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ComposerBar(
                    text: $vm.draft,
                    timer: vm.selectedTimer,
                    onTimerTap: { vm.showTimerSheet = true },
                    onSend: { vm.send() }
                )
            }
            .sheet(isPresented: $vm.showTimerSheet) {
                TimerSelectorSheet(selected: $vm.selectedTimer)
            }
            .navigationTitle("@\(vm.peerUsername)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(Theme.Colors.trustInfo)
                        .accessibilityLabel("This conversation is end-to-end encrypted")
                }
            }
        }

        /// Quiet capsule at the top of every thread — trust stated once, calmly.
        private var encryptionHeader: some View {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "lock.fill")
                    .font(.caption2)
                Text("End-to-end encrypted · messages disappear after \(vm.selectedTimer.rawValue)")
                    .font(Theme.Fonts.caption)
            }
            .foregroundStyle(Theme.Colors.textSecondary)
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.vertical, Theme.Spacing.s)
            .background(Theme.Colors.surface)
            .clipShape(Capsule())
            .accessibilityElement(children: .combine)
        }

        private func scrollToBottom(_ proxy: ScrollViewProxy, animated: Bool) {
            guard let last = vm.messages.last?.id else { return }
            if animated {
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(last, anchor: .bottom)
                }
            } else {
                proxy.scrollTo(last, anchor: .bottom)
            }
        }
    }
}

#Preview("Chat") {
    NavigationStack {
        Redesign.ChatView(peerUsername: "maya", messages: Redesign.Mock.messages(for: "maya"))
    }
}

#Preview("Chat · empty") {
    NavigationStack {
        Redesign.ChatView(peerUsername: "new_friend", messages: [])
    }
}

#Preview("Chat · dark") {
    NavigationStack {
        Redesign.ChatView(peerUsername: "maya", messages: Redesign.Mock.messages(for: "maya"))
    }
    .preferredColorScheme(.dark)
}
