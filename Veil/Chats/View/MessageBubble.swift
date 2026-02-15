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
            if message.direction == .incoming { bubble.alignmentGuide(.leading) { $0[.leading] } }
            if message.direction == .outgoing { Spacer() }
            bubble
            if message.direction == .incoming { Spacer() }
        }
    }

    private var bubble: some View {
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
                .foregroundStyle(message.direction == .outgoing ? Color.white : Color.primary)

            HStack(spacing: 8) {
                Text(message.timer.rawValue)
                    .font(.system(size: 12))
                    .foregroundStyle(secondaryTextColor)

                if message.state == .sending {
                    Text("Sending")
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
        .background(message.direction == .outgoing ? Color.accentColor : Color(.secondarySystemBackground))
        .cornerRadius(14)
    }

    private var displayText: String {
        if message.ciphertext.hasPrefix("attachment:") {
            return "📎 Attachment"
        }
        if message.ciphertext == "encrypting…" {
            return "Encrypting message…"
        }
        return "Encrypted message"
    }

    private var secondaryTextColor: Color {
        message.direction == .outgoing ? Color.white.opacity(0.85) : .secondary
    }
}


#Preview {
    MessageBubble(message: ChatMessage(id: UUID.init(), chatUsername: "jbgjhersd", direction: .incoming, ciphertext: "grersg", createdAt: Date.now, timer: .hour1, state: .sending))
}
