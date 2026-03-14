import SwiftUI

struct ResetPasswordView: View {
    @EnvironmentObject private var auth: AuthStore

    @State private var newPassword = ""
    @State private var confirmPassword = ""

    private var isValidLength: Bool {
        newPassword.trimmingCharacters(in: .whitespacesAndNewlines).count >= 8
    }

    private var passwordsMatch: Bool {
        !newPassword.isEmpty && newPassword == confirmPassword
    }

    private var canSubmit: Bool {
        isValidLength && passwordsMatch
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Reset password")
                .font(.system(size: 24, weight: .semibold))
                .padding(.top, 24)

            Text("Recovery key verified. Set a new password for normal sign in.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            SecureField("New password", text: $newPassword)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

            SecureField("Confirm new password", text: $confirmPassword)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

            if let error = auth.loginErrorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()

            Button("Save password", action: save)
                .disabled(!canSubmit)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canSubmit ? Color.primary : Color.secondary)
                .foregroundColor(Color(.systemBackground))
                .cornerRadius(12)
        }
        .padding(24)
        .navigationTitle("New password")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func save() {
        guard canSubmit else { return }
        _ = auth.resetPassword(newPassword: newPassword)
    }
}

#Preview {
    let environment = AppEnvironment()
    let auth = AuthStore(authRepo: environment.authRepo, identitySyncService: environment.identitySyncService, deviceIdentityStore: environment.deviceIdentityStore)
    return ResetPasswordView()
        .environmentObject(auth)
}
