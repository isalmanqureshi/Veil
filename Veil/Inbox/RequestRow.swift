//
//  RequestRow.swift
//  Veil
//
//  Created by Salman Qureshi on 2/11/26.
//

import SwiftUI
import SwiftUI

struct RequestRow: View {

    let request: MessageRequestThread
    let onIgnore: () -> Void
    let onAccept: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack(spacing: 12) {
                AvatarCircle(text: String(request.fromUsername.prefix(1)))

                VStack(alignment: .leading, spacing: 4) {
                    Text(request.fromUsername)
                        .font(.system(size: 16, weight: .semibold))

                    Text(request.previewCiphertext)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    // Optional: calm context line (for abuse resistance later)
                    // Text("New request • Not in your contacts")
                    //   .font(.system(size: 12))
                    //   .foregroundStyle(.secondary)
                }

                Spacer()

                Text(request.createdAt, style: .relative)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button(action: onIgnore) {
                    Text("Ignore")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button(action: onAccept) {
                    Text("Accept")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .background(Color.primary)
                .foregroundColor(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(.vertical, 8)
    }
}
