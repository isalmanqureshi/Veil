//
//  ChatRow.swift
//  Veil
//
//  Created by Salman Qureshi on 2/11/26.
//

import SwiftUI

struct ChatRow: View {

    let username: String
    let preview: String

    var body: some View {
        HStack(spacing: 12) {
            AvatarCircle(text: String(username.prefix(1)))

            VStack(alignment: .leading, spacing: 4) {
                Text(username)
                    .font(.system(size: 16, weight: .semibold))

                Text(preview)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

