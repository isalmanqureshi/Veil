import SwiftUI

struct RecoveryLoginView: View {
    @EnvironmentObject private var auth: AuthStore

    @State private var username = ""
    @State private var recoveryKey = ""

    private var normalizedUsername: String {
        UsernameRules.normalize(username)
    }

    private var canSubmit: Bool {
        UsernameRules.isValid(normalizedUsername) && !recoveryKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 16) {
            TextField("Username", text: $username)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

            SecureField("Recovery key", text: $recoveryKey)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

            if let error = auth.loginErrorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button("Recover account", action: recover)
                .disabled(!canSubmit)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canSubmit ? Color.primary : Color.secondary)
                .foregroundColor(Color(.systemBackground))
                .cornerRadius(12)

            Spacer()
        }
        .padding(24)
        .navigationTitle("Recover account")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: username) { newValue in
            let sanitized = UsernameRules.sanitize(newValue)
            if sanitized != newValue {
                username = sanitized
            }
        }
    }

    private func recover() {
        guard canSubmit else { return }
        _ = auth.recoverAccount(username: normalizedUsername, recoveryKey: recoveryKey)
    }
}

#Preview {
    let environment = AppEnvironment()
    return RecoveryLoginView()
        .environmentObject(AuthStore(authRepo: environment.authRepo, identitySyncService: environment.identitySyncService, deviceIdentityStore: environment.deviceIdentityStore))
}
