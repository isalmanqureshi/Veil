//
//  RedesignTheme.swift
//  Veil
//
//  Design-system tokens for the Veil redesign.
//  Semantic colors (light/dark adaptive), type scale, spacing, radii, shadows.
//  One confident accent; color is reserved for meaning (trust states, timers).
//

import SwiftUI
import UIKit

/// Namespace for the redesigned UI layer. Redesign screens/components live as
/// nested types (`Redesign.InboxView`, `Redesign.ChatRow`, …) so they can
/// compile alongside the existing views until they are swapped in.
enum Redesign {}

// MARK: - Theme

enum Theme {

    // MARK: Colors (semantic, light/dark adaptive)

    enum Colors {
        /// App canvas — a whisper of violet-warmed gray, pure near-black in dark.
        static let background = Color(light: UIColor(hex: 0xF7F6FB), dark: UIColor(hex: 0x0E0E14))
        /// Cards, rows, sheets.
        static let surface = Color(light: UIColor(hex: 0xFFFFFF), dark: UIColor(hex: 0x1A1A23))
        /// Raised surfaces: composer, floating controls, selected chips.
        static let surfaceElevated = Color(light: UIColor(hex: 0xFFFFFF), dark: UIColor(hex: 0x23232E))
        /// Primary text.
        static let textPrimary = Color(light: UIColor(hex: 0x17171F), dark: UIColor(hex: 0xF2F2F7))
        /// Secondary text, timestamps, captions.
        static let textSecondary = Color(light: UIColor(hex: 0x6E6E7A), dark: UIColor(hex: 0x9A9AA6))
        /// Hairlines and separators.
        static let separator = Color(light: UIColor(hex: 0xE7E6EE), dark: UIColor(hex: 0x2B2B36))

        /// The one accent: Veil violet. Outgoing bubbles, primary actions, focus.
        static let accent = Color(light: UIColor(hex: 0x5551E8), dark: UIColor(hex: 0x8B8AF5))
        /// Text/icons placed on top of the accent.
        static let onAccent = Color(light: UIColor(hex: 0xFFFFFF), dark: UIColor(hex: 0x14141B))
        /// Soft accent wash for chips, selected states, highlights.
        static let accentSoft = Color(light: UIColor(hex: 0xEDEDFD), dark: UIColor(hex: 0x2A2A45))

        // Trust palette — calm, never alarmist.
        /// Reassuring signals: verified, proof-of-work, encrypted.
        static let trustInfo = Color(light: UIColor(hex: 0x2F9E8F), dark: UIColor(hex: 0x4CC7B7))
        /// Gentle caution: rate limits, screenshots, new devices.
        static let trustWarning = Color(light: UIColor(hex: 0xB7791F), dark: UIColor(hex: 0xE0A64E))
        /// Serious but quiet: identity changes, destructive actions.
        static let trustCritical = Color(light: UIColor(hex: 0xB4485B), dark: UIColor(hex: 0xE3728A))

        /// Incoming message bubble.
        static let bubbleIncoming = Color(light: UIColor(hex: 0xFFFFFF), dark: UIColor(hex: 0x23232E))
        /// Outgoing message bubble (the accent — messages you send carry the brand).
        static let bubbleOutgoing = accent
    }

    // MARK: Type scale (relative to Dynamic Type styles)

    enum Fonts {
        /// Hero moments: welcome, recovery key.
        static let display = Font.system(.largeTitle, design: .rounded, weight: .bold)
        /// Screen titles rendered in-content.
        static let title = Font.system(.title2, design: .rounded, weight: .semibold)
        /// Row titles, buttons.
        static let headline = Font.system(.headline, weight: .semibold)
        /// Message text, body copy.
        static let body = Font.system(.body)
        /// Previews, secondary rows.
        static let callout = Font.system(.callout)
        /// Timestamps, helper text.
        static let footnote = Font.system(.footnote)
        /// Badges, tiny metadata.
        static let caption = Font.system(.caption, weight: .medium)
        /// Recovery key, ciphertext.
        static let mono = Font.system(.callout, design: .monospaced)
    }

    // MARK: Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
    }

    // MARK: Radii

    enum Radius {
        static let bubble: CGFloat = 18
        static let card: CGFloat = 16
        static let control: CGFloat = 14
        static let chip: CGFloat = 8
    }

    // MARK: Shadows

    enum Shadows {
        /// Subtle card elevation. Invisible-ish in dark mode by design.
        static let cardColor = Color.black.opacity(0.06)
        static let cardRadius: CGFloat = 12
        static let cardY: CGFloat = 4
    }
}

// MARK: - Adaptive color helpers

private extension Color {
    init(light: UIColor, dark: UIColor) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

// MARK: - Token gallery preview

#Preview("Theme tokens") {
    ScrollView {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            Text("Veil").font(Theme.Fonts.display).foregroundStyle(Theme.Colors.textPrimary)
            Text("Calm, private messaging").font(Theme.Fonts.title).foregroundStyle(Theme.Colors.textPrimary)
            Text("Body copy sits quietly on the canvas.").font(Theme.Fonts.body).foregroundStyle(Theme.Colors.textPrimary)
            Text("Secondary detail and timestamps.").font(Theme.Fonts.footnote).foregroundStyle(Theme.Colors.textSecondary)

            HStack(spacing: Theme.Spacing.s) {
                swatch(Theme.Colors.accent, "accent")
                swatch(Theme.Colors.trustInfo, "info")
                swatch(Theme.Colors.trustWarning, "warning")
                swatch(Theme.Colors.trustCritical, "critical")
            }

            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Theme.Colors.surface)
                .frame(height: 72)
                .shadow(color: Theme.Shadows.cardColor, radius: Theme.Shadows.cardRadius, y: Theme.Shadows.cardY)
                .overlay(Text("surface card").font(Theme.Fonts.footnote).foregroundStyle(Theme.Colors.textSecondary))
        }
        .padding(Theme.Spacing.l)
    }
    .background(Theme.Colors.background)
}

private func swatch(_ color: Color, _ name: String) -> some View {
    VStack(spacing: 4) {
        RoundedRectangle(cornerRadius: 8).fill(color).frame(width: 56, height: 40)
        Text(name).font(.caption2).foregroundStyle(Theme.Colors.textSecondary)
    }
}
