//
//  AvatarCircle.swift
//  Veil
//
//  Created by Salman Qureshi on 2/11/26.
//

import SwiftUI

struct AvatarCircle: View {
    let text: String

    var body: some View {
        ZStack {
            Circle().fill(Color(.secondarySystemBackground))
            Text(text.uppercased())
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .frame(width: 40, height: 40)
    }
}
