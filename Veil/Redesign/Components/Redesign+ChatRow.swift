//
//  Redesign+ChatRow.swift
//  Veil
//
//  Inbox row for an active conversation. Binds to the existing ChatThread.
//

import SwiftUI

extension Redesign {

    struct ChatRow: View {
        let thread: ChatThread
        var hasUnread: Bool = false

        var body: some View {
            HStack(spacing: Theme.Spacing.m) {
                AvatarView(username: thread.username)

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("@\(thread.username)")
                        .font(Theme.Fonts.headline)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1)

                    Text(thread.lastPreview)
                        .font(Theme.Fonts.callout)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: Theme.Spacing.s)

                VStack(alignment: .trailing, spacing: Theme.Spacing.xs) {
                    Text(Redesign.compactTimestamp(thread.lastAt))
                        .font(Theme.Fonts.footnote)
                        .foregroundStyle(hasUnread ? Theme.Colors.accent : Theme.Colors.textSecondary)

                    if hasUnread {
                        Circle()
                            .fill(Theme.Colors.accent)
                            .frame(width: 10, height: 10)
                            .accessibilityLabel("Unread messages")
                    } else {
                        // keep vertical rhythm stable
                        Circle().fill(.clear).frame(width: 10, height: 10)
                    }
                }
            }
            .padding(.vertical, Theme.Spacing.s + 2)
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
        }
    }
}

#Preview("Chat rows") {
    VStack(spacing: 0) {
        ForEach(Array(Redesign.Mock.threads.enumerated()), id: \.element.id) { index, thread in
            Redesign.ChatRow(thread: thread, hasUnread: index == 0)
                .padding(.horizontal, Theme.Spacing.m)
            Divider().padding(.leading, 48 + Theme.Spacing.m * 2)
        }
    }
    .background(Theme.Colors.surface)
    .padding()
    .background(Theme.Colors.background)
}
