//
//  Redesign+StartChat.swift
//  Veil
//
//  Start a new conversation by username search.
//

import SwiftUI

extension Redesign {

    struct StartChatView: View {
        @State private var query = ""
        var knownUsernames: [String] = []
        var onSelect: (String) -> Void = { _ in }

        @FocusState private var isFocused: Bool

        private var normalizedQuery: String {
            query.lowercased()
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "@", with: "")
        }

        private var matches: [String] {
            guard !normalizedQuery.isEmpty else { return [] }
            return knownUsernames.filter { $0.localizedCaseInsensitiveContains(normalizedQuery) }
        }

        private var canMessageDirectly: Bool {
            normalizedQuery.count >= 3 && !knownUsernames.contains(normalizedQuery)
        }

        var body: some View {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                // Search field
                HStack(spacing: Theme.Spacing.s) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Theme.Colors.textSecondary)
                    TextField("Search any username", text: $query)
                        .font(Theme.Fonts.body)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFocused)
                }
                .padding(Theme.Spacing.m)
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                        .strokeBorder(isFocused ? Theme.Colors.accent : Theme.Colors.separator, lineWidth: 1)
                )
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.top, Theme.Spacing.s)

                // Results
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(matches, id: \.self) { username in
                            resultRow(username)
                            Divider().padding(.leading, 44 + Theme.Spacing.m * 2)
                        }

                        if canMessageDirectly {
                            resultRow(normalizedQuery, isNew: true)
                        }

                        if normalizedQuery.isEmpty {
                            privacyNote
                                .padding(.top, Theme.Spacing.xl)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.m)
                }
            }
            .background(Theme.Colors.background)
            .navigationTitle("New chat")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { isFocused = true }
        }

        private func resultRow(_ username: String, isNew: Bool = false) -> some View {
            Button {
                onSelect(username)
            } label: {
                HStack(spacing: Theme.Spacing.m) {
                    AvatarView(username: username, size: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("@\(username)")
                            .font(Theme.Fonts.headline)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        if isNew {
                            Text("Send a message request")
                                .font(Theme.Fonts.footnote)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }
                    Spacer()
                    Image(systemName: isNew ? "paperplane" : "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .padding(.vertical, Theme.Spacing.s + 2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }

        private var privacyNote: some View {
            VStack(spacing: Theme.Spacing.s) {
                Image(systemName: "at.circle")
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(Theme.Colors.accent)
                Text("Usernames only")
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text("Veil never touches your contacts or phone number. Search works only on exact usernames people choose to share.")
                    .font(Theme.Fonts.footnote)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.l)
        }
    }
}

#Preview("Start chat") {
    NavigationStack {
        Redesign.StartChatView(knownUsernames: ["maya", "aiden", "studio_ops"])
    }
}
