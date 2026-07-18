//
//  Redesign+Onboarding.swift
//  Veil
//
//  Onboarding flow: username → password → recovery key.
//  The recovery-key screen is the "write this down" moment — important,
//  but reassuring rather than stressful.
//

import SwiftUI
import UIKit

// MARK: - Username creation

extension Redesign {

    struct UsernameCreationView: View {
        @State private var username = ""
        var onContinue: (String) -> Void = { _ in }

        @FocusState private var isFocused: Bool

        private var normalized: String {
            username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        }

        private var isValid: Bool {
            normalized.count >= 3 && normalized.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
        }

        var body: some View {
            OnboardingScaffold(
                step: "1 of 3",
                title: "Pick your username",
                subtitle: "This is how people find you. It's the only identity Veil ever knows."
            ) {
                HStack(spacing: 0) {
                    Text("@")
                        .font(Theme.Fonts.title)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .padding(.leading, Theme.Spacing.m)
                    TextField("username", text: $username)
                        .font(Theme.Fonts.title)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFocused)
                        .padding(Theme.Spacing.m)
                }
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                        .strokeBorder(isFocused ? Theme.Colors.accent : Theme.Colors.separator, lineWidth: 1)
                )

                Text("3+ characters. Letters, numbers, and underscores.")
                    .font(Theme.Fonts.footnote)
                    .foregroundStyle(Theme.Colors.textSecondary)
            } action: {
                Button("Continue") { onContinue(normalized) }
                    .buttonStyle(.veilPrimary)
                    .disabled(!isValid)
            }
        }
    }

    // MARK: - Password creation

    struct PasswordCreationView: View {
        @State private var password = ""
        var onContinue: (String) -> Void = { _ in }

        private var isValid: Bool { password.count >= 8 }

        var body: some View {
            OnboardingScaffold(
                step: "2 of 3",
                title: "Set a password",
                subtitle: "It unlocks Veil on this device. It never leaves your phone."
            ) {
                SecureField("Password", text: $password)
                    .textFieldStyle(.veil)
                    .textContentType(.newPassword)

                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isValid ? Theme.Colors.trustInfo : Theme.Colors.textSecondary)
                    Text("At least 8 characters")
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .font(Theme.Fonts.footnote)
                .animation(.easeOut(duration: 0.15), value: isValid)
            } action: {
                Button("Continue") { onContinue(password) }
                    .buttonStyle(.veilPrimary)
                    .disabled(!isValid)
            }
        }
    }

    // MARK: - Recovery key

    struct RecoveryKeyView: View {
        let recoveryKey: String
        var onFinish: () -> Void = {}

        @State private var hasSavedKey = false
        @State private var justCopied = false

        var body: some View {
            OnboardingScaffold(
                step: "3 of 3",
                title: "Your recovery key",
                subtitle: "This is the one key to your account. Write it down or store it somewhere safe — Veil can't recover it for you."
            ) {
                // The key itself: calm, legible, monospaced.
                VStack(spacing: Theme.Spacing.m) {
                    Text(recoveryKey)
                        .font(Theme.Fonts.mono)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .textSelection(.enabled)

                    Button {
                        UIPasteboard.general.string = recoveryKey
                        withAnimation(.easeOut(duration: 0.15)) { justCopied = true }
                        Task {
                            try? await Task.sleep(for: .seconds(2))
                            withAnimation { justCopied = false }
                        }
                    } label: {
                        Label(justCopied ? "Copied" : "Copy key",
                              systemImage: justCopied ? "checkmark" : "doc.on.doc")
                            .font(Theme.Fonts.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.Colors.accent)
                    .accessibilityLabel("Copy recovery key")
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.l)
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                        .strokeBorder(Theme.Colors.accentSoft, lineWidth: 2)
                )

                HStack(alignment: .top, spacing: Theme.Spacing.s) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(Theme.Colors.trustInfo)
                    Text("Anyone with this key can restore your account, so keep it private. You'll only see it once.")
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(Theme.Fonts.footnote)

                Toggle(isOn: $hasSavedKey) {
                    Text("I've saved my recovery key")
                        .font(Theme.Fonts.callout)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
                .tint(Theme.Colors.accent)
                .padding(.top, Theme.Spacing.s)
            } action: {
                Button("Finish setup", action: onFinish)
                    .buttonStyle(.veilPrimary)
                    .disabled(!hasSavedKey)
            }
        }
    }

    // MARK: - Shared scaffold

    /// Shared onboarding layout: step marker, title, subtitle, content, pinned action.
    struct OnboardingScaffold<Content: View, Action: View>: View {
        let step: String
        let title: String
        let subtitle: String
        @ViewBuilder let content: () -> Content
        @ViewBuilder let action: () -> Action

        var body: some View {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                Text(step.uppercased())
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.accent)
                    .padding(.top, Theme.Spacing.l)

                Text(title)
                    .font(Theme.Fonts.display)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(subtitle)
                    .font(Theme.Fonts.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                content()
                    .padding(.top, Theme.Spacing.s)

                Spacer(minLength: 0)

                action()
                    .padding(.bottom, Theme.Spacing.m)
            }
            .padding(.horizontal, Theme.Spacing.l)
            .background(Theme.Colors.background)
        }
    }
}

#Preview("Username") {
    Redesign.UsernameCreationView()
}

#Preview("Password") {
    Redesign.PasswordCreationView()
}

#Preview("Recovery key") {
    Redesign.RecoveryKeyView(recoveryKey: Redesign.Mock.recoveryKey)
}

#Preview("Recovery key · dark") {
    Redesign.RecoveryKeyView(recoveryKey: Redesign.Mock.recoveryKey)
        .preferredColorScheme(.dark)
}
