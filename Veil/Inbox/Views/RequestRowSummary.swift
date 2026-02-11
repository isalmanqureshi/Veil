//
//  RequestRowSummary.swift
//  Veil
//
//  Created by Salman Qureshi on 2/11/26.
//

import SwiftUI

struct RequestRowSummary: View {

    let request: MessageRequestThread

    var body: some View {
        HStack(spacing: 12) {
            AvatarCircle(text: String(request.fromUsername.prefix(1)))

            VStack(alignment: .leading, spacing: 4) {
                Text(request.fromUsername)
                    .font(.system(size: 16, weight: .semibold))

                Text(request.previewCiphertext)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(request.createdAt, style: .relative)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}
