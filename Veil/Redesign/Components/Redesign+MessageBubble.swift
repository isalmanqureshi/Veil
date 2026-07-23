//
//  Redesign+MessageBubble.swift
//  Veil
//
//  Message bubble bound to the existing ChatMessage. Renders all three
//  SendStates (.sending/.sent/.failed) and the disappearing-timer indicator.
//

import SwiftUI

extension Redesign {

    struct MessageBubble: View {
        let message: ChatMessage
        var onRetry: (() -> Void)? = nil

        private var isOutgoing: Bool { message.direction == .outgoing }

        var body: some View {
            HStack(spacing: 0) {
                if isOutgoing { Spacer(minLength: 48) }

                VStack(alignment: isOutgoing ? .trailing : .leading, spacing: Theme.Spacing.xs) {
                    bubble
                    metaLine
                }

                if !isOutgoing { Spacer(minLength: 48) }
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilitySummary)
        }

        // MARK: Bubble body

        private var bubble: some View {
            Text(message.plaintextPreview)
                .font(Theme.Fonts.body)
                .foregroundStyle(isOutgoing ? Theme.Colors.onAccent : Theme.Colors.textPrimary)
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.vertical, 10)
                .background(bubbleBackground)
                .clipShape(bubbleShape)
                .overlay {
                    if message.state == .failed {
                        bubbleShape.strokeBorder(Theme.Colors.trustCritical.opacity(0.55), lineWidth: 1)
                    }
                }
                .opacity(message.state == .sending ? 0.65 : 1)
                .onTapGesture {
                    if message.state == .failed { onRetry?() }
                }
        }

        private var bubbleBackground: Color {
            if isOutgoing {
                return message.state == .failed
                    ? Theme.Colors.bubbleOutgoing.opacity(0.45)
                    : Theme.Colors.bubbleOutgoing
            }
            return Theme.Colors.bubbleIncoming
        }

        /// Rounded with a tightened corner toward the sender, WhatsApp/Signal-style.
        private var bubbleShape: UnevenRoundedRectangle {
            let r = Theme.Radius.bubble
            let tight: CGFloat = 6
            return UnevenRoundedRectangle(
                topLeadingRadius: r,
                bottomLeadingRadius: isOutgoing ? r : tight,
                bottomTrailingRadius: isOutgoing ? tight : r,
                topTrailingRadius: r,
                style: .continuous
            )
        }

        // MARK: Meta line (time • timer • state)

        private var metaLine: some View {
            HStack(spacing: Theme.Spacing.xs) {
                if message.state == .failed {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption2)
                    Text("Not sent — tap to retry")
                        .font(Theme.Fonts.caption)
                } else {
                    Text(message.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(Theme.Fonts.caption)

                    Image(systemName: message.timer.symbolName)
                        .font(.caption2)
                    Text(message.timer.rawValue)
                        .font(Theme.Fonts.caption)

                    if isOutgoing {
                        Image(systemName: stateSymbol)
                            .font(.caption2)
                    }
                }
            }
            .foregroundStyle(message.state == .failed ? Theme.Colors.trustCritical : Theme.Colors.textSecondary)
            .padding(.horizontal, Theme.Spacing.xs)
        }

        private var stateSymbol: String {
            switch message.state {
            case .sending: return "clock"
            case .sent: return "checkmark"
            case .failed: return "exclamationmark.circle"
            }
        }

        private var accessibilitySummary: String {
            let who = isOutgoing ? "You" : "@\(message.chatUsername)"
            let state: String
            switch message.state {
            case .sending: state = "sending"
            case .sent: state = "sent"
            case .failed: state = "failed to send, double-tap to retry"
            }
            return "\(who): \(message.plaintextPreview). \(state). Disappears after \(message.timer.rawValue)."
        }
    }
}

#Preview("Message bubbles") {
    ScrollView {
        VStack(spacing: Theme.Spacing.s) {
            ForEach(Redesign.Mock.messages(for: "maya")) { message in
                Redesign.MessageBubble(message: message)
            }
        }
        .padding(Theme.Spacing.m)
    }
    .background(Theme.Colors.background)
}
