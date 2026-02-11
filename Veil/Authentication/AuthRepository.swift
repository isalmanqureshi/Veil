//
//  AuthRepository.swift
//  Veil
//
//  Created by Salman Qureshi on 2/11/26.
//
import Foundation

protocol AuthRepository {
    func loadCurrentUser() -> UserIdentity?
    func createUser(username: String) -> UserIdentity
    func restoreUser(username: String, recoveryKey: String) -> UserIdentity?
    func clear()
}


final class MockAuthRepository: AuthRepository {

    private let keyUser = "veil.currentUser.username"
    private let keyRecovery = "veil.currentUser.recoveryKey"

    func loadCurrentUser() -> UserIdentity? {
        guard
            let username = UserDefaults.standard.string(forKey: keyUser),
            let recoveryKey = UserDefaults.standard.string(forKey: keyRecovery)
        else { return nil }

        return UserIdentity(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE") ?? UUID(),
            username: username,
            recoveryKey: recoveryKey,
            isVerified: false
        )
    }

    func createUser(username: String) -> UserIdentity {
        // Deterministic-ish recovery key for MVP (replace with real keygen later)
        let recoveryKey = "veil-\(username)-recovery-key"

        UserDefaults.standard.set(username, forKey: keyUser)
        UserDefaults.standard.set(recoveryKey, forKey: keyRecovery)

        return UserIdentity(
            id: UUID(),
            username: username,
            recoveryKey: recoveryKey,
            isVerified: false
        )
    }

    func restoreUser(username: String, recoveryKey: String) -> UserIdentity? {
        // In real life: decrypt sealed identity blob. For MVP: match stored.
        guard
            let storedUser = UserDefaults.standard.string(forKey: keyUser),
            let storedKey = UserDefaults.standard.string(forKey: keyRecovery),
            storedUser == username,
            storedKey == recoveryKey
        else { return nil }

        return loadCurrentUser()
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: keyUser)
        UserDefaults.standard.removeObject(forKey: keyRecovery)
    }
}
