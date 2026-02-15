//
//  EmptyInboxView.swift
//  Veil
//
//  Created by Salman Qureshi on 2/5/26.
//

import SwiftUI

struct EmptyInboxView: View {

    let onStartChat: () -> Void
    let onShareUsername: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Spacer()

            Text("No conversations yet")
                .font(.system(size: 28, weight: .bold))

            Button(action: onStartChat) {
                Text("Start a Chat")
                    .font(.system(size: 17, weight: .semibold))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
            }
            .background(Color.primary)
            .foregroundColor(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Button(action: onShareUsername) {
                Text("Share your username")
                    .font(.system(size: 17))
                    .foregroundStyle(.blue)
            }
            .padding(.top, 6)

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    EmptyInboxView(onStartChat: {}, onShareUsername: {})
}
