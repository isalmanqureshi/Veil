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
        state = .onboarding
    }

    func prepareRecoveryKeyIfNeeded() {
        guard onboardingRecoveryKey.isEmpty else { return }
        let prepared = authRepo.prepareRecoveryKey()
        onboardingRecoveryKey = prepared.recoveryKey
        onboardingSeed = prepared.seed
    }

    func finishOnboarding() {
        guard !onboardingUsername.isEmpty,
              let seed = onboardingSeed,
              !onboardingRecoveryKey.isEmpty else { return }
        
        do {
            let user = authRepo.createUser(
                username: onboardingUsername,
                seed: seed,
                recoveryKey: onboardingRecoveryKey
            )
            
            let km = KeyManager()
            try km.bootstrapIdentityIfNeeded(seed: seed)
            _ = try km.makePreKeyBundle(oneTimeCount: 20)
            
            state = .signedIn(user: user)
        } catch {
            // MVP: keep user in onboarding and show a calm error UI
            // e.g. publish an error string
        }
    }


    func signOut() {
        authRepo.clear()
        state = .signedOut
    }

    func login(username: String, recoveryKey: String) -> Bool {
        guard let seed = try? RecoveryKeyGenerator.decode(recoveryKey) else { return false }

        guard let user = authRepo.restoreUser(username: username, recoveryKey: recoveryKey) else {
            return false
        }

        do {
            let km = KeyManager()
            try km.bootstrapIdentityIfNeeded(seed: seed)
            _ = try km.makePreKeyBundle(oneTimeCount: 20)
        } catch {
            return false
        }

        state = .signedIn(user: user)
        return true
    }
}
