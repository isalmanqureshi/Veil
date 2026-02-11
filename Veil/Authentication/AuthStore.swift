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
        state = .onboarding
    }

    func finishOnboarding(username: String) {
        let user = authRepo.createUser(username: username)
        state = .signedIn(user: user)
    }

    func signOut() {
        authRepo.clear()
        state = .signedOut
    }

    func login(username: String, recoveryKey: String) -> Bool {
        if let user = authRepo.restoreUser(username: username, recoveryKey: recoveryKey) {
            state = .signedIn(user: user)
            return true
        }
        return false
    }
}
