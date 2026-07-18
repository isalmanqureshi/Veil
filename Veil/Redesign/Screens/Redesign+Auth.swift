//
//  Redesign+Auth.swift
//  Veil
//
//  Sign-in flows: password login, recovery-key login, password reset.
//

import SwiftUI

extension Redesign {

    // MARK: - Login

    struct LoginView: View {
        @State private var username = ""
        @State private var password = ""
        var errorMessage: String? = nil
        var onLogin: (String, String) -> Void = { _, _ in }
        var onForgot: () -> Void = {}

        private var canSubmit: Bool { !username.isEmpty && !password.isEmpty }

        var body: some View {
            AuthScaffold(
                title: "Welcome back",
                subtitle: "Sign in with your username and password."
            ) {
                TextField("@username", text: $username)
                    .textFieldStyle(.veil)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("Password", text: $password)
                    .textFieldStyle(.veil)
                    .textContentType(.password)

                if let errorMessage {
                    InlineNotice(text: errorMessage)
                }
            } action: {
                VStack(spacing: Theme.Spacing.s) {
                    Button("Sign in") { onLogin(username, password) }
                        .buttonStyle(.veilPrimary)
                        .disabled(!canSubmit)
                    Button("Use my recovery key instead", action: onForgot)
                        .buttonStyle(.veilQuiet)
                }
            }
        }
    }

    // MARK: - Recovery login

    struct RecoveryLoginView: View {
        @State private var username = ""
        @State private var recoveryKey = ""
        var errorMessage: String? = nil
        var onRecover: (String, String) -> Void = { _, _ in }

        private var canSubmit: Bool { !username.isEmpty && !recoveryKey.isEmpty }

        var body: some View {
            AuthScaffold(
                title: "Recover your account",
                subtitle: "Enter your username and the recovery key you saved when you set up Veil."
            ) {
                TextField("@username", text: $username)
                    .textFieldStyle(.veil)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                TextField("xxxx-xxxx-xxxx-…", text: $recoveryKey, axis: .vertical)
                    .font(Theme.Fonts.mono)
                    .lineLimit(2...4)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(Theme.Spacing.m)
                    .background(Theme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                            .strokeBorder(Theme.Colors.separator, lineWidth: 1)
                    )

                if let errorMessage {
                    InlineNotice(text: errorMessage)
                }

                HStack(alignment: .top, spacing: Theme.Spacing.s) {
                    Image(systemName: "lock.shield")
                        .foregroundStyle(Theme.Colors.trustInfo)
                    Text("Your key is checked on this device only — it's never sent anywhere.")
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(Theme.Fonts.footnote)
            } action: {
                Button("Recover account") { onRecover(username, recoveryKey) }
                    .buttonStyle(.veilPrimary)
                    .disabled(!canSubmit)
            }
        }
    }

    // MARK: - Reset password

    struct ResetPasswordView: View {
        @State private var newPassword = ""
        var errorMessage: String? = nil
        var onReset: (String) -> Void = { _ in }

        private var isValid: Bool { newPassword.count >= 8 }

        var body: some View {
            AuthScaffold(
                title: "Set a new password",
                subtitle: "Account recovered. Choose a new password for this device."
            ) {
                SecureField("New password", text: $newPassword)
                    .textFieldStyle(.veil)
                    .textContentType(.newPassword)

                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isValid ? Theme.Colors.trustInfo : Theme.Colors.textSecondary)
                    Text("At least 8 characters")
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .font(Theme.Fonts.footnote)

                if let errorMessage {
                    InlineNotice(text: errorMessage)
                }
            } action: {
                Button("Save and continue") { onReset(newPassword) }
                    .buttonStyle(.veilPrimary)
                    .disabled(!isValid)
            }
        }
    }

    // MARK: - Shared bits

    /// Gentle inline error — informative tint, no shouting.
    struct InlineNotice: View {
        let text: String

        var body: some View {
            HStack(alignment: .top, spacing: Theme.Spacing.s) {
                Image(systemName: "info.circle")
                Text(text).fixedSize(horizontal: false, vertical: true)
            }
            .font(Theme.Fonts.footnote)
            .foregroundStyle(Theme.Colors.trustCritical)
            .padding(Theme.Spacing.s + 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.trustCritical.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous))
        }
    }

    struct AuthScaffold<Content: View, Action: View>: View {
        let title: String
        let subtitle: String
        @ViewBuilder let content: () -> Content
        @ViewBuilder let action: () -> Action

        var body: some View {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                Text(title)
                    .font(Theme.Fonts.display)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .padding(.top, Theme.Spacing.xl)

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

#Preview("Login") {
    Redesign.LoginView()
}

#Preview("Login · error") {
    Redesign.LoginView(errorMessage: "That password didn't match. Try again, or use your recovery key.")
}

#Preview("Recovery login") {
    Redesign.RecoveryLoginView()
}

#Preview("Reset password") {
    Redesign.ResetPasswordView()
}
