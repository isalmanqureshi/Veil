//
//  UsernameCreationView.swift
//  Veil
//
//  Created by Salman Qureshi on 2/5/26.
//

import SwiftUI

struct UsernameCreationView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var auth: AuthStore

    @State private var username: String = ""
    @FocusState private var isUsernameFieldFocused: Bool

    private var normalizedUsername: String {
        UsernameRules.normalize(username)
    }

    private var isValid: Bool {
        UsernameRules.isValid(normalizedUsername)
    }

    private var helperText: String {
        if normalizedUsername.isEmpty {
            return "Use \(UsernameRules.minLength)–\(UsernameRules.maxLength) characters. Letters, numbers, underscores only."
        }

        if isValid {
            return "Looks good."
        }

        return "Invalid format. Use \(UsernameRules.minLength)–\(UsernameRules.maxLength) characters with lowercase letters, numbers, or _."
    }

    private var helperColor: Color {
        isValid || normalizedUsername.isEmpty ? .secondary : .red
    }

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 20) {
                Text("Choose a username")
                    .font(.system(size: 20, weight: .semibold))

                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        TextField("username", text: $username)
                            .font(.system(size: 16))
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .keyboardType(.asciiCapable)
                            .focused($isUsernameFieldFocused)
                            .submitLabel(.done)
                            .onSubmit { continueIfValid() }

                        Button(action: generateUsername) {
                            Image(systemName: "shuffle")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("Generate username")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)

                    HStack {
                        Text(helperText)
                            .font(.caption)
                            .foregroundStyle(helperColor)

                        Spacer()

                        Text("\(normalizedUsername.count)/\(UsernameRules.maxLength)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text("This is how others find you. It’s not tied to your real identity.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(
                color: Color.black.opacity(0.06),
                radius: 12,
                x: 0,
                y: 4
            )
            .padding(.horizontal, 24)

            Spacer()

            Button(action: continueIfValid) {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .disabled(!isValid)
            .background(isValid ? Color.primary : Color.secondary)
            .foregroundColor(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .onAppear {
            if username.isEmpty {
                generateUsername()
            }

            isUsernameFieldFocused = true
        }
        .onChange(of: username) { newValue in
            let sanitized = UsernameRules.sanitize(newValue)
            if sanitized != newValue {
                username = sanitized
            }
        }
    }

    private func continueIfValid() {
        guard isValid else { return }

        auth.onboardingUsername = normalizedUsername
        auth.prepareRecoveryKeyIfNeeded()
        coordinator.push(.recoveryKey)
    }

    private func generateUsername() {
        let candidates = [
            "quiet_signal_24",
            "solid_river_37",
            "swift_orbit_52",
            "clear_harbor_68",
            "frost_field_73"
        ]

        let preferredLength = 14
        let next = candidates
            .first(where: { $0 != normalizedUsername && abs($0.count - preferredLength) < 4 })
            ?? candidates.first
            ?? "quiet_signal_24"

        username = UsernameRules.sanitize(next)
    }
}

#Preview {
    let coordinator = AppCoordinator()
    let environment = AppEnvironment()

    return UsernameCreationView()
        .environmentObject(coordinator)
        .environmentObject(AuthStore(authRepo: environment.authRepo))
}
