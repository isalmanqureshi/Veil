import SwiftUI

struct PasswordCreationView: View {
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var coordinator: AppCoordinator

    @State private var password = ""
    @State private var confirmPassword = ""

    private var isValidLength: Bool {
        password.trimmingCharacters(in: .whitespacesAndNewlines).count >= 8
    }

    private var passwordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }

    private var canContinue: Bool {
        isValidLength && passwordsMatch
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Set a password")
                .font(.system(size: 24, weight: .semibold))
                .padding(.top, 24)

            Text("Use this password for day-to-day sign in on this device.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            SecureField("Password", text: $password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

            SecureField("Confirm password", text: $confirmPassword)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

            Text(passwordValidationText)
                .font(.caption)
                .foregroundStyle(passwordValidationColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            Button("Continue", action: continueFlow)
                .disabled(!canContinue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canContinue ? Color.primary : Color.secondary)
                .foregroundColor(Color(.systemBackground))
                .cornerRadius(12)
        }
        .padding(24)
        .navigationTitle("Create password")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var passwordValidationText: String {
        if password.isEmpty && confirmPassword.isEmpty {
            return "Password must be at least 8 characters."
        }

        if !isValidLength {
            return "Password must be at least 8 characters."
        }

        if !passwordsMatch {
            return "Passwords do not match."
        }

        return "Password looks good."
    }

    private var passwordValidationColor: Color {
        canContinue ? .secondary : .red
    }

    private func continueFlow() {
        guard canContinue else { return }
        auth.setOnboardingPassword(password)
        auth.prepareRecoveryKeyIfNeeded()
        coordinator.push(.recoveryKey)
    }
}

#Preview {
    let coordinator = AppCoordinator()
    let environment = AppEnvironment()

    return PasswordCreationView()
        .environmentObject(coordinator)
        .environmentObject(AuthStore(authRepo: environment.authRepo, identitySyncService: environment.identitySyncService, deviceIdentityStore: environment.deviceIdentityStore))
}
