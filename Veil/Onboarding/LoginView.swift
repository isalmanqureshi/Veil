//
//  LoginView.swift
//  Veil
//
//  Created by Salman Qureshi on 2/11/26.
//

import SwiftUI

struct LoginView: View {

    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var coordinator: AppCoordinator

    @State private var username = ""
    @State private var recoveryKey = ""
    @FocusState private var focusedField: Field?

    private enum Field {
        case username
        case recoveryKey
    }

    private var normalizedUsername: String {
        UsernameRules.normalize(username)
    }

    private var normalizedRecoveryKey: String {
        recoveryKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmit: Bool {
        UsernameRules.isValid(normalizedUsername) && !normalizedRecoveryKey.isEmpty
    }

    var body: some View {
        VStack(spacing: 16) {
            TextField("Username", text: $username)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .keyboardType(.asciiCapable)
                .focused($focusedField, equals: .username)
                .submitLabel(.next)
                .onSubmit { focusedField = .recoveryKey }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

            SecureField("Recovery key", text: $recoveryKey)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .focused($focusedField, equals: .recoveryKey)
                .submitLabel(.go)
                .onSubmit { signIn() }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

            if let error = auth.loginErrorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button("Sign in", action: signIn)
                .disabled(!canSubmit)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canSubmit ? Color.primary : Color.secondary)
                .foregroundColor(Color(.systemBackground))
                .cornerRadius(12)

            Spacer()
        }
        .padding(24)
        .navigationTitle("Sign in")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            focusedField = .username
        }
        .onChange(of: username) { newValue in
            let sanitized = UsernameRules.sanitize(newValue)
            if sanitized != newValue {
                username = sanitized
            }
        }
    }

    private func signIn() {
        guard canSubmit else { return }

        let ok = auth.login(username: normalizedUsername, recoveryKey: normalizedRecoveryKey)
        if ok {
            coordinator.path.removeAll()
        }
    }
}

#Preview {
    let coordinator = AppCoordinator()
    let environment = AppEnvironment()

    return LoginView()
        .environmentObject(coordinator)
        .environmentObject(AuthStore(authRepo: environment.authRepo))
}
