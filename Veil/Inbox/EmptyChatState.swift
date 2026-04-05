//
//  EmptyChatState.swift
//  Veil
//
//  Created by Salman Qureshi on 2/11/26.
//

import SwiftUI

struct EmptyChatsState: View {

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
            .background(Color.black)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Button(action: onShareUsername) {
                Text("Share your username")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.blue)
            }
            .padding(.top, 6)

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}
