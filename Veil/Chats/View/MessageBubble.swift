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
            Text(message.ciphertext) // in real app you'd decrypt for display
                .font(.system(size: 15))

            HStack(spacing: 8) {
                Text(message.timer.rawValue)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                if message.state == .sending {
                    Text("Sending")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                } else if message.state == .failed {
                    Text("Tap to retry")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
}


#Preview {
    MessageBubble(message: ChatMessage(id: UUID.init(), chatUsername: "jbgjhersd", direction: .incoming, ciphertext: "grersg", createdAt: Date.now, timer: .hour1, state: .sending))
}
