//
//  Redesign+EmptyStates.swift
//  Veil
//
//  Calm empty states: empty inbox, empty requests, empty chat.
//

import SwiftUI

extension Redesign {

    struct EmptyState: View {
        let symbolName: String
        let title: String
        let message: String
        var actionTitle: String? = nil
        var action: () -> Void = {}

        var body: some View {
            VStack(spacing: Theme.Spacing.m) {
                Image(systemName: symbolName)
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(Theme.Colors.accent)
                    .frame(width: 76, height: 76)
                    .background(Theme.Colors.accentSoft)
                    .clipShape(Circle())

                VStack(spacing: Theme.Spacing.xs) {
                    Text(title)
                        .font(Theme.Fonts.title)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text(message)
                        .font(Theme.Fonts.callout)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                if let actionTitle {
                    Button(actionTitle, action: action)
                        .buttonStyle(.veilPrimary)
                        .frame(maxWidth: 260)
                        .padding(.top, Theme.Spacing.s)
                }
            }
            .padding(Theme.Spacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

        // MARK: Presets

        static func emptyInbox(onStartChat: @escaping () -> Void) -> EmptyState {
            EmptyState(
                symbolName: "bubble.left.and.bubble.right",
                title: "No conversations yet",
                message: "Start a chat with any username.\nNo phone number needed — ever.",
                actionTitle: "Start a chat",
                action: onStartChat
            )
        }

        static var emptyRequests: EmptyState {
            EmptyState(
                symbolName: "tray",
                title: "No requests",
                message: "When someone new messages you,\nit waits here until you decide."
            )
        }

        static var emptyChat: EmptyState {
            EmptyState(
                symbolName: "lock.shield",
                title: "Say hello",
                message: "Messages here are end-to-end encrypted\nand disappear on your schedule."
            )
        }
    }
}

#Preview("Empty inbox") {
    Redesign.EmptyState.emptyInbox(onStartChat: {})
        .background(Theme.Colors.background)
}

#Preview("Empty requests") {
    Redesign.EmptyState.emptyRequests
        .background(Theme.Colors.background)
}

#Preview("Empty chat") {
    Redesign.EmptyState.emptyChat
        .background(Theme.Colors.background)
}
