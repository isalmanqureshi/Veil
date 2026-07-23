//
//  RedesignStyles.swift
//  Veil
//
//  Reusable styles built from Theme tokens: buttons, text fields, surfaces.
//

import SwiftUI

// MARK: - Buttons

/// Filled accent button for the single primary action on a screen.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Fonts.headline)
            .foregroundStyle(Theme.Colors.onAccent)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .background(Theme.Colors.accent)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

/// Quiet secondary button — tinted text, soft wash on press.
struct QuietButtonStyle: ButtonStyle {
    var tint: Color = Theme.Colors.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Fonts.headline)
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .background(configuration.isPressed ? tint.opacity(0.1) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var veilPrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == QuietButtonStyle {
    static var veilQuiet: QuietButtonStyle { QuietButtonStyle() }
    /// Quiet style in the calm-critical tint, for "remove account"-grade actions.
    static var veilQuietCritical: QuietButtonStyle { QuietButtonStyle(tint: Theme.Colors.trustCritical) }
}

// MARK: - Text fields

/// Filled, rounded text field used across onboarding/auth.
struct VeilFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(Theme.Fonts.body)
            .padding(.horizontal, Theme.Spacing.m)
            .frame(minHeight: 52)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                    .strokeBorder(Theme.Colors.separator, lineWidth: 1)
            )
    }
}

extension TextFieldStyle where Self == VeilFieldStyle {
    static var veil: VeilFieldStyle { VeilFieldStyle() }
}

// MARK: - Surfaces & chips

extension View {
    /// Wraps content in a padded surface card with subtle elevation.
    func surfaceCard(padding: CGFloat = Theme.Spacing.m) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .shadow(color: Theme.Shadows.cardColor, radius: Theme.Shadows.cardRadius, y: Theme.Shadows.cardY)
    }

    /// Small tinted capsule chip (trust badges, timer labels).
    func chip(tint: Color) -> some View {
        self
            .font(Theme.Fonts.caption)
            .foregroundStyle(tint)
            .padding(.horizontal, Theme.Spacing.s)
            .padding(.vertical, Theme.Spacing.xs)
            .background(tint.opacity(0.12))
            .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview("Styles") {
    VStack(spacing: Theme.Spacing.m) {
        Button("Create my username") {}
            .buttonStyle(.veilPrimary)
        Button("I already have an account") {}
            .buttonStyle(.veilQuiet)
        Button("Remove account from this device") {}
            .buttonStyle(.veilQuietCritical)
        TextField("@username", text: .constant(""))
            .textFieldStyle(.veil)
        Text("Secure by default")
            .surfaceCard()
        HStack {
            Text("First contact").chip(tint: Theme.Colors.trustInfo)
            Text("Rate limited").chip(tint: Theme.Colors.trustWarning)
        }
    }
    .padding(Theme.Spacing.l)
    .background(Theme.Colors.background)
}
