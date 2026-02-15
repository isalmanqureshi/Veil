//
//  AuthRepository.swift
//  Veil
//
//  Created by Salman Qureshi on 2/11/26.
//
import Foundation

protocol AuthRepository {
    func loadCurrentUser() -> UserIdentity?
    func prepareRecoveryKey() -> (recoveryKey: String, seed: Data)
    func createUser(username: String, seed: Data, recoveryKey: String) -> UserIdentity
    func restoreUser(username: String, recoveryKey: String) -> UserIdentity?
    func clear()
}

final class MockAuthRepository: AuthRepository {

    private let keyUser = "veil.currentUser.username"
    private let service = "veil.identity"
    private let accountSeed = "identitySeed"

    private let keychain = KeychainStore()

    func loadCurrentUser() -> UserIdentity? {
        guard let username = UserDefaults.standard.string(forKey: keyUser) else { return nil }
        guard let seed = try? keychain.load(service: service, account: accountSeed), seed != nil else { return nil }

        // We don't store recoveryKey; user must keep it. For MVP we can derive display key again if needed.
        return UserIdentity(id: UUID(), username: username, recoveryKey: "stored-on-device", isVerified: false)
    }

    func prepareRecoveryKey() -> (recoveryKey: String, seed: Data) {
        let key = RecoveryKeyGenerator.generate()
        guard let seed = try? RecoveryKeyGenerator.decode(key) else {
            return (key, Data())
        }
        return (key, seed)
    }

    func createUser(username: String, seed: Data, recoveryKey: String) -> UserIdentity {
        // Persist local identity seed + username
        UserDefaults.standard.set(username, forKey: keyUser)
        try? keychain.save(seed, service: service, account: accountSeed)

        return UserIdentity(id: UUID(), username: username, recoveryKey: recoveryKey, isVerified: false)
    }

    func restoreUser(username: String, recoveryKey: String) -> UserIdentity? {
        guard let seed = try? RecoveryKeyGenerator.decode(recoveryKey) else { return nil }

        // Persist restored identity to device
        UserDefaults.standard.set(username, forKey: keyUser)
        try? keychain.save(seed, service: service, account: accountSeed)

        return UserIdentity(id: UUID(), username: username, recoveryKey: recoveryKey, isVerified: false)
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: keyUser)
        keychain.delete(service: service, account: accountSeed)
    }
}


//
//final class MockAuthRepository: AuthRepository {
//
//    private let keyUser = "veil.currentUser.username"
//    private let keyRecovery = "veil.currentUser.recoveryKey"
//
//    func loadCurrentUser() -> UserIdentity? {
//        guard
//            let username = UserDefaults.standard.string(forKey: keyUser),
//            let recoveryKey = UserDefaults.standard.string(forKey: keyRecovery)
//        else { return nil }
//
//        return UserIdentity(
//            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE") ?? UUID(),
//            username: username,
//            recoveryKey: recoveryKey,
//            isVerified: false
//        )
//    }
//
//    func createUser(username: String) -> UserIdentity {
//        // Deterministic-ish recovery key for MVP (replace with real keygen later)
//        let recoveryKey = "veil-\(username)-recovery-key"
//
//        UserDefaults.standard.set(username, forKey: keyUser)
//        UserDefaults.standard.set(recoveryKey, forKey: keyRecovery)
//
//        return UserIdentity(
//            id: UUID(),
//            username: username,
//            recoveryKey: recoveryKey,
//            isVerified: false
//        )
//    }
//
//    func restoreUser(username: String, recoveryKey: String) -> UserIdentity? {
//        // In real life: decrypt sealed identity blob. For MVP: match stored.
//        guard
//            let storedUser = UserDefaults.standard.string(forKey: keyUser),
//            let storedKey = UserDefaults.standard.string(forKey: keyRecovery),
//            storedUser == username,
//            storedKey == recoveryKey
//        else { return nil }
//
//        return loadCurrentUser()
//    }
//
//    func clear() {
//        UserDefaults.standard.removeObject(forKey: keyUser)
//        UserDefaults.standard.removeObject(forKey: keyRecovery)
//    }
//}
