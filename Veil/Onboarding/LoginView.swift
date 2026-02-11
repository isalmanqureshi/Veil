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
    @State private var showError = false

    var body: some View {
        VStack(spacing: 16) {

            TextField("Username", text: $username)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

            TextField("Recovery key", text: $recoveryKey)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

            if showError {
                Text("Couldn’t sign in. Check your username and recovery key.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Button("Sign in") {
                let ok = auth.login(username: username, recoveryKey: recoveryKey)
                if ok { coordinator.path.removeAll() }
            }
            .disabled(username.isEmpty || recoveryKey.isEmpty)
            .frame(maxWidth: .infinity)
            .padding()
            .background((username.isEmpty || recoveryKey.isEmpty) ? Color.secondary : Color.primary)
            .foregroundColor(Color(.systemBackground))
            .cornerRadius(12)

            Spacer()
        }
        .padding(24)
        .navigationTitle("Sign in")
        .navigationBarTitleDisplayMode(.inline)
    }
}


#Preview {
    LoginView()
}
