//
//  Redesign+Inbox.swift
//  Veil
//
//  Inbox with Chats / Requests segments. Binds to the existing
//  ChatThread and MessageRequestThread models via a lightweight view model.
//

import SwiftUI

extension Redesign {

    // MARK: - View model

    @MainActor
    final class InboxViewModel: ObservableObject {
        @Published var threads: [ChatThread]
        @Published var requests: [MessageRequestThread]

        init(threads: [ChatThread], requests: [MessageRequestThread]) {
            self.threads = threads.sorted(by: { $0.lastAt > $1.lastAt })
            self.requests = requests.sorted(by: { $0.createdAt > $1.createdAt })
        }

        func accept(_ request: MessageRequestThread) {
            requests.removeAll { $0.id == request.id }
            threads.insert(
                ChatThread(id: request.id, username: request.fromUsername,
                           lastPreview: "Request accepted", lastAt: .now),
                at: 0
            )
        }

        func ignore(_ request: MessageRequestThread) {
            requests.removeAll { $0.id == request.id }
        }
    }

    // MARK: - Screen

    struct InboxView: View {
        @StateObject private var vm: InboxViewModel
        @State private var selectedTab = "chats"

        var onOpenChat: (String) -> Void = { _ in }
        var onOpenRequest: (MessageRequestThread) -> Void = { _ in }
        var onStartChat: () -> Void = {}
        var onOpenTrustCenter: () -> Void = {}

        init(
            threads: [ChatThread],
            requests: [MessageRequestThread],
            onOpenChat: @escaping (String) -> Void = { _ in },
            onOpenRequest: @escaping (MessageRequestThread) -> Void = { _ in },
            onStartChat: @escaping () -> Void = {},
            onOpenTrustCenter: @escaping () -> Void = {}
        ) {
            _vm = StateObject(wrappedValue: InboxViewModel(threads: threads, requests: requests))
            self.onOpenChat = onOpenChat
            self.onOpenRequest = onOpenRequest
            self.onStartChat = onStartChat
            self.onOpenTrustCenter = onOpenTrustCenter
        }

        var body: some View {
            VStack(spacing: 0) {
                SegmentedTabs(
                    segments: [
                        .init(id: "chats", title: "Chats"),
                        .init(id: "requests", title: "Requests", badgeCount: vm.requests.count)
                    ],
                    selectedID: $selectedTab
                )
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.vertical, Theme.Spacing.s)

                if selectedTab == "chats" {
                    chatsList
                } else {
                    requestsList
                }
            }
            .background(Theme.Colors.background)
            .navigationTitle("Veil")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onOpenTrustCenter) {
                        Image(systemName: "shield")
                            .foregroundStyle(Theme.Colors.trustInfo)
                    }
                    .accessibilityLabel("Trust Center")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onStartChat) {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(Theme.Colors.accent)
                    }
                    .accessibilityLabel("Start a chat")
                }
            }
        }

        // MARK: Chats

        @ViewBuilder
        private var chatsList: some View {
            if vm.threads.isEmpty {
                EmptyState.emptyInbox(onStartChat: onStartChat)
            } else {
                List {
                    ForEach(Array(vm.threads.enumerated()), id: \.element.id) { index, thread in
                        ChatRow(thread: thread, hasUnread: index == 0)
                            .listRowBackground(Theme.Colors.background)
                            .listRowSeparatorTint(Theme.Colors.separator)
                            .onTapGesture { onOpenChat(thread.username) }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }

        // MARK: Requests

        @ViewBuilder
        private var requestsList: some View {
            if vm.requests.isEmpty {
                EmptyState.emptyRequests
            } else {
                List {
                    Section {
                        ForEach(vm.requests) { request in
                            RequestRow(request: request)
                                .listRowBackground(Theme.Colors.background)
                                .listRowSeparatorTint(Theme.Colors.separator)
                                .onTapGesture { onOpenRequest(request) }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button("Ignore") { vm.ignore(request) }
                                        .tint(Theme.Colors.textSecondary)
                                    Button("Accept") { vm.accept(request) }
                                        .tint(Theme.Colors.trustInfo)
                                }
                        }
                    } footer: {
                        Text("Senders aren't told whether you've seen their request.")
                            .font(Theme.Fonts.footnote)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }
}

#Preview("Inbox") {
    NavigationStack {
        Redesign.InboxView(threads: Redesign.Mock.threads, requests: Redesign.Mock.requests)
    }
}

#Preview("Inbox · empty") {
    NavigationStack {
        Redesign.InboxView(threads: [], requests: [])
    }
}

#Preview("Inbox · dark") {
    NavigationStack {
        Redesign.InboxView(threads: Redesign.Mock.threads, requests: Redesign.Mock.requests)
    }
    .preferredColorScheme(.dark)
}
