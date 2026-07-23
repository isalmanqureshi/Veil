//
//  Redesign+Welcome.swift
//  Veil
//
//  Value proposition: no phone number, E2EE, disappearing messages.
//

import SwiftUI

extension Redesign {

    struct WelcomeView: View {
        var onCreateAccount: () -> Void = {}
        var onSignIn: () -> Void = {}

        var body: some View {
            VStack(spacing: 0) {
                Spacer()

                // Mark
                Image(systemName: "circle.dotted.circle")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(Theme.Colors.accent)
                    .padding(.bottom, Theme.Spacing.l)

                Text("Veil")
                    .font(Theme.Fonts.display)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("Private messaging, minus the phone number.")
                    .font(Theme.Fonts.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, Theme.Spacing.xs)

                // Value props
                VStack(spacing: Theme.Spacing.m) {
                    valueRow(
                        symbol: "at",
                        title: "Just a username",
                        detail: "No phone number, no contacts upload, no real name."
                    )
                    valueRow(
                        symbol: "lock.shield",
                        title: "End-to-end encrypted",
                        detail: "Only you and the person you message can read it."
                    )
                    valueRow(
                        symbol: "timer",
                        title: "Messages disappear",
                        detail: "Every message deletes itself on a schedule you set."
                    )
                }
                .padding(.top, Theme.Spacing.xl)
                .padding(.horizontal, Theme.Spacing.l)

                Spacer()
                Spacer()

                // Actions — thumb zone
                VStack(spacing: Theme.Spacing.s) {
                    Button("Create my username", action: onCreateAccount)
                        .buttonStyle(.veilPrimary)
                    Button("I already have an account", action: onSignIn)
                        .buttonStyle(.veilQuiet)
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.bottom, Theme.Spacing.m)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Colors.background)
        }

        private func valueRow(symbol: String, title: String, detail: String) -> some View {
            HStack(alignment: .top, spacing: Theme.Spacing.m) {
                Image(systemName: symbol)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Theme.Colors.accent)
                    .frame(width: 40, height: 40)
                    .background(Theme.Colors.accentSoft)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Fonts.headline)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text(detail)
                        .font(Theme.Fonts.footnote)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .combine)
        }
    }
}

#Preview("Welcome") {
    Redesign.WelcomeView()
}

#Preview("Welcome · dark") {
    Redesign.WelcomeView()
        .preferredColorScheme(.dark)
}
