//
//  AuthStore.swift
//  Veil
//
//  Created by Salman Qureshi on 2/11/26.
//

import SwiftUI

enum BackendSyncState: Equatable {
    case idle
    case syncing
    case synced
    case failed(message: String)
}

@MainActor
final class AuthStore: ObservableObject {

    @Published private(set) var state: AuthState = .signedOut
    @Published private(set) var onboardingUsername: String = ""
    @Published private(set) var onboardingPassword: String = ""
    @Published private(set) var onboardingRecoveryKey: String = ""
    @Published private(set) var onboardingErrorMessage: String?
    @Published private(set) var loginErrorMessage: String?
    @Published private(set) var backendSyncState: BackendSyncState = .idle

    private var onboardingSeed: Data?
    private let authRepo: AuthRepository
    private let passwordManager: PasswordManager
    private let identitySyncService: IdentitySyncService
    private let deviceIdentityStore: DeviceIdentityStore
    private let localDataWiper: LocalDataWiping
    private let defaults: UserDefaults
    private let sessionKey = DefaultsKey.isSignedIn
    private var backendSyncTask: Task<Void, Never>?

    init(
        authRepo: AuthRepository,
        passwordManager: PasswordManager = PasswordManager(),
        identitySyncService: IdentitySyncService = NoopIdentitySyncService(),
        deviceIdentityStore: DeviceIdentityStore = DeviceIdentityStore(),
        localDataWiper: LocalDataWiping? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.authRepo = authRepo
        self.passwordManager = passwordManager
        self.identitySyncService = identitySyncService
        self.deviceIdentityStore = deviceIdentityStore
        self.defaults = defaults
        self.localDataWiper = localDataWiper ?? LocalDataWiper(
            authRepository: authRepo,
            passwordManager: passwordManager,
            defaults: defaults
        )
        bootstrap()
    }

    func bootstrap() {
        guard let user = authRepo.loadCurrentUser() else {
            state = .signedOut
            return
        }

        state = isSessionSignedIn() ? .signedIn(user: user) : .signedOut
    }

    func startOnboarding() {
        onboardingUsername = ""
        onboardingPassword = ""
        onboardingRecoveryKey = ""
        onboardingSeed = nil
        onboardingErrorMessage = nil
        loginErrorMessage = nil
        state = .onboarding
    }

    func setOnboardingUsername(_ username: String) {
        onboardingUsername = UsernameRules.normalize(username)
    }

    func setOnboardingPassword(_ password: String) {
        onboardingPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
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

        guard onboardingPassword.count >= 8 else {
            onboardingErrorMessage = "Set a password with at least 8 characters."
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

            try passwordManager.setPassword(onboardingPassword)

            onboardingUsername = ""
            onboardingPassword = ""
            onboardingRecoveryKey = ""
            onboardingSeed = nil
            setSessionSignedIn(true)
            state = .signedIn(user: user)
            triggerBackendSync(for: normalizedUsername)
        } catch {
            onboardingErrorMessage = "Couldn’t finish setup right now. Please try again."
        }
    }

    func signOut() {
        backendSyncTask?.cancel()
        backendSyncTask = nil
        onboardingUsername = ""
        onboardingPassword = ""
        onboardingRecoveryKey = ""
        onboardingSeed = nil
        loginErrorMessage = nil
        onboardingErrorMessage = nil
        backendSyncState = .idle
        setSessionSignedIn(false)
        state = .signedOut
    }

    func eraseLocalData() {
        localDataWiper.wipeAllLocalData()
        signOut()
    }

    func login(username: String, password: String) -> Bool {
        loginErrorMessage = nil

        let normalizedUsername = UsernameRules.normalize(username)
        let normalizedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard UsernameRules.isValid(normalizedUsername) else {
            loginErrorMessage = "Enter a valid username."
            return false
        }

        guard let user = authRepo.loadCurrentUser(), user.username == normalizedUsername else {
            loginErrorMessage = "This account isn’t available on this device."
            return false
        }

        guard passwordManager.verifyPassword(normalizedPassword) else {
            loginErrorMessage = "Incorrect password."
            return false
        }

        setSessionSignedIn(true)
        state = .signedIn(user: user)
        triggerBackendSync(for: normalizedUsername)
        return true
    }

    func recoverAccount(username: String, recoveryKey: String) -> Bool {
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
            loginErrorMessage = "Couldn’t recover account. Check your username and recovery key."
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

        setSessionSignedIn(false)
        state = .requiresPasswordReset(user: user)
        return true
    }

    func resetPassword(newPassword: String) -> Bool {
        let normalizedPassword = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedPassword.count >= 8 else {
            loginErrorMessage = "Password must be at least 8 characters."
            return false
        }

        guard case .requiresPasswordReset(let user) = state else {
            loginErrorMessage = "Recover your account before resetting password."
            return false
        }

        do {
            try passwordManager.setPassword(normalizedPassword)
            loginErrorMessage = nil
            setSessionSignedIn(true)
            state = .signedIn(user: user)
            triggerBackendSync(for: user.username)
            return true
        } catch {
            loginErrorMessage = "Couldn’t save your new password. Try again."
            return false
        }
    }

    func retryPendingSync() async {
        guard case .signedIn(let user) = state else { return }
        await syncIdentityAndPreKeys(username: user.username)
    }

    private func triggerBackendSync(for username: String) {
        backendSyncTask?.cancel()
        backendSyncTask = Task {
            await syncIdentityAndPreKeys(username: username)
        }
    }

    private func syncIdentityAndPreKeys(username: String) async {
        if Task.isCancelled { return }
        backendSyncState = .syncing
        let deviceId = deviceIdentityStore.currentDeviceId()

        do {
            try await identitySyncService.sync(username: username, deviceId: deviceId)
            if Task.isCancelled { return }
            backendSyncState = .synced
        } catch {
            if Task.isCancelled { return }
            backendSyncState = .failed(message: error.localizedDescription)
        }
    }

    private func setSessionSignedIn(_ isSignedIn: Bool) {
        defaults.set(isSignedIn, forKey: sessionKey)
    }

    private func isSessionSignedIn() -> Bool {
        defaults.bool(forKey: sessionKey)
    }
}
