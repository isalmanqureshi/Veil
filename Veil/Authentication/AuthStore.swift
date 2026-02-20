//
//  AuthStore.swift
//  Veil
//
//  Created by Salman Qureshi on 2/11/26.
//

import SwiftUI

@MainActor
final class AuthStore: ObservableObject {

    @Published private(set) var state: AuthState = .signedOut
    @Published var onboardingUsername: String = ""
    @Published private(set) var onboardingRecoveryKey: String = ""
    @Published private(set) var onboardingErrorMessage: String?
    @Published private(set) var loginErrorMessage: String?

    private var onboardingSeed: Data?
    private let authRepo: AuthRepository

    init(authRepo: AuthRepository) {
        self.authRepo = authRepo
        bootstrap()
    }

    func bootstrap() {
        if let user = authRepo.loadCurrentUser() {
            state = .signedIn(user: user)
        } else {
            state = .signedOut
        }
    }

    func startOnboarding() {
        onboardingUsername = ""
        onboardingRecoveryKey = ""
        onboardingSeed = nil
        onboardingErrorMessage = nil
        loginErrorMessage = nil
        state = .onboarding
    }

    func prepareRecoveryKeyIfNeeded() {
        guard onboardingRecoveryKey.isEmpty else { return }

        do {
            let prepared = try authRepo.prepareRecoveryKey()
            onboardingRecoveryKey = prepared.recoveryKey
            onboardingSeed = prepared.seed
        } catch {
            onboardingErrorMessage = "Couldn’t generate a recovery key right now. Please try again."
        }
    }

    func finishOnboarding() {
        onboardingErrorMessage = nil

        let normalizedUsername = UsernameRules.normalize(onboardingUsername)

        guard UsernameRules.isValid(normalizedUsername) else {
            onboardingErrorMessage = "Choose a valid username before finishing setup."
            return
        }

        guard let seed = onboardingSeed, !onboardingRecoveryKey.isEmpty else {
            onboardingErrorMessage = "Recovery key is missing. Please go back and try again."
            return
        }

        do {
            let user = authRepo.createUser(
                username: normalizedUsername,
                seed: seed,
                recoveryKey: onboardingRecoveryKey
            )

            let km = KeyManager()
            try km.bootstrapIdentityIfNeeded(seed: seed)
            _ = try km.makePreKeyBundle(oneTimeCount: 20)

            onboardingUsername = ""
            onboardingRecoveryKey = ""
            onboardingSeed = nil
            state = .signedIn(user: user)
        } catch {
            onboardingErrorMessage = "Couldn’t finish setup right now. Please try again."
        }
    }

    func signOut() {
        authRepo.clear()
        onboardingUsername = ""
        onboardingRecoveryKey = ""
        onboardingSeed = nil
        loginErrorMessage = nil
        onboardingErrorMessage = nil
        state = .signedOut
    }

    func login(username: String, recoveryKey: String) -> Bool {
        loginErrorMessage = nil

        let normalizedUsername = UsernameRules.normalize(username)
        let normalizedRecoveryKey = recoveryKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard UsernameRules.isValid(normalizedUsername) else {
            loginErrorMessage = "Enter a valid username."
            return false
        }

        guard let seed = try? RecoveryKeyGenerator.decode(normalizedRecoveryKey) else {
            loginErrorMessage = "Recovery key format is invalid."
            return false
        }

        guard let user = authRepo.restoreUser(username: normalizedUsername, recoveryKey: normalizedRecoveryKey) else {
            loginErrorMessage = "Couldn’t sign in. Check your username and recovery key."
            return false
        }

        do {
            let km = KeyManager()
            try km.bootstrapIdentityIfNeeded(seed: seed)
            _ = try km.makePreKeyBundle(oneTimeCount: 20)
        } catch {
            loginErrorMessage = "Couldn’t initialize secure session. Try again."
            return false
        }

        state = .signedIn(user: user)
        return true
    }
}
