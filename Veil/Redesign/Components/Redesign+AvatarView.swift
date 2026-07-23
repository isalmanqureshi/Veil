//
//  Redesign+AvatarView.swift
//  Veil
//
//  Username-derived avatar: deterministic gradient + initials.
//  No photos by default — Veil identities are usernames, not faces.
//

import SwiftUI

extension Redesign {

    struct AvatarView: View {
        let username: String
        var size: CGFloat = 48

        var body: some View {
            ZStack {
                Circle()
                    .fill(gradient)
                Text(initials)
                    .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: size, height: size)
            .accessibilityHidden(true) // the row/screen provides the username
        }

        private var initials: String {
            String(username.replacingOccurrences(of: "_", with: " ")
                .split(separator: " ")
                .prefix(2)
                .compactMap { $0.first.map(String.init)?.uppercased() }
                .joined())
        }

        /// Deterministic hue from the username so a contact always looks the same.
        private var gradient: LinearGradient {
            let hue = Double(stableHash(username) % 360) / 360.0
            let top = Color(hue: hue, saturation: 0.45, brightness: 0.72)
            let bottom = Color(hue: hue, saturation: 0.55, brightness: 0.52)
            return LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom)
        }

        private func stableHash(_ value: String) -> UInt32 {
            // FNV-1a — stable across launches, unlike Hasher.
            var hash: UInt32 = 2_166_136_261
            for byte in value.utf8 {
                hash ^= UInt32(byte)
                hash = hash &* 16_777_619
            }
            return hash
        }
    }
}

#Preview("Avatars") {
    HStack(spacing: Theme.Spacing.m) {
        Redesign.AvatarView(username: "maya")
        Redesign.AvatarView(username: "aiden", size: 40)
        Redesign.AvatarView(username: "studio_ops", size: 64)
        Redesign.AvatarView(username: "unknown_veil")
    }
    .padding()
    .background(Theme.Colors.background)
}
