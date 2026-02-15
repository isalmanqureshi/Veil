//
//  MessageBubble.swift
//  Veil
//
//  Created by Salman Qureshi on 2/10/26.
//

import SwiftUI

struct MessageBubble: View {

    let message: ChatMessage

    var body: some View {
        HStack {
            if isOutgoing { Spacer(minLength: 36) }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text("Encrypted")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Text(displayText)
                    .font(.system(size: 15))
                    .foregroundStyle(isOutgoing ? Color.white : Color.primary)

                HStack(spacing: 8) {
                    Text(message.timer.rawValue)
                        .font(.system(size: 12))
                        .foregroundStyle(secondaryTextColor)

                    if message.state == .sending {
                        ProgressView()
                            .controlSize(.mini)
                            .tint(secondaryTextColor)
                        Text("Sending…")
                            .font(.system(size: 12))
                            .foregroundStyle(secondaryTextColor)
                    } else if message.state == .failed {
                        Text("Tap to retry")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(secondaryTextColor)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .leading)
            .background(isOutgoing ? Color.accentColor : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            if !isOutgoing { Spacer(minLength: 36) }
        }
    }

    private var isOutgoing: Bool {
        message.direction == .outgoing
    }

    private var displayText: String {
        if message.ciphertext.hasPrefix("attachment:") {
            return "📎 \(message.plaintextPreview)"
        }
        if message.ciphertext == "encrypting…" {
            return "Encrypting message…"
        }
        return message.plaintextPreview
    }

    private var secondaryTextColor: Color {
        isOutgoing ? Color.white.opacity(0.85) : .secondary
    }
}

#Preview {
    MessageBubble(
        message: ChatMessage(
            id: UUID(),
            chatUsername: "maya",
            direction: .outgoing,
            ciphertext: "seed",
            plaintextPreview: "On my way 🙂",
            createdAt: .now,
            timer: .hour1,
            state: .sending
        )
    )
}
