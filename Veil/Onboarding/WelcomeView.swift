//
//  ContentView.swift
//  Veil
//
//  Created by Salman Qureshi on 2/5/26.
//

import SwiftUI

struct WelcomeView: View {

    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var coordinator: AppCoordinator

    var body: some View {
        VStack {
            Spacer()

            Image(systemName: "shield.fill")
                .font(.system(size: 42))
                .foregroundStyle(.primary)
                .padding(.bottom, 24)

            Text("Private by default. Invisible by design.")
                .font(.system(size: 28, weight: .semibold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 12)

            Text("No phone number. No ads. No tracking.")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button(action: createAccount) {
                Text("Create Account")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .background(Color.primary)
            .foregroundColor(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            Button(action: signIn) {
                Text("Sign in")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .background(Color(.secondarySystemBackground))
            .foregroundStyle(.primary)
            .cornerRadius(12)
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            Button(action: { coordinator.push(.privacyPolicy) }) {
                Text("Learn how privacy works")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 24)
        }
    }

    private func createAccount() {
        auth.startOnboarding()
    }

    private func signIn() {
        coordinator.push(.login)
    }
}

#Preview {
    let coordinator = AppCoordinator()
    let environment = AppEnvironment()

    return WelcomeView()
        .environmentObject(coordinator)
        .environmentObject(environment)
        .environmentObject(TrustCenter(coordinator: coordinator))
        .environmentObject(AuthStore(authRepo: environment.authRepo))
}
