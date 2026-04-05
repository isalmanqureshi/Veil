import Foundation

final class NetworkAuthRepository: AuthRepository {
    private let local: AuthRepository
    private let usersService: UsersService
    private let preKeysService: PreKeysService
    private let keyManager: KeyManager
    private let authContext: LocalAuthContext

    init(
        local: AuthRepository,
        usersService: UsersService,
        preKeysService: PreKeysService,
        keyManager: KeyManager = KeyManager(),
        authContext: LocalAuthContext = LocalAuthContext()
    ) {
        self.local = local
        self.usersService = usersService
        self.preKeysService = preKeysService
        self.keyManager = keyManager
        self.authContext = authContext
    }

    func loadCurrentUser() -> UserIdentity? {
        local.loadCurrentUser()
    }

    func prepareRecoveryKey() throws -> (recoveryKey: String, seed: Data) {
        try local.prepareRecoveryKey()
    }

    func createUser(username: String, seed: Data, recoveryKey: String) -> UserIdentity {
        let user = local.createUser(username: username, seed: seed, recoveryKey: recoveryKey)
        Task {
            await publishIdentityIfPossible(username: username, seed: seed)
        }
        return user
    }

    func restoreUser(username: String, recoveryKey: String) -> UserIdentity? {
        guard let user = local.restoreUser(username: username, recoveryKey: recoveryKey) else { return nil }
        let seed = try? RecoveryKeyGenerator.decode(recoveryKey)

        Task {
            await publishIdentityIfPossible(username: username, seed: seed)
        }

        return user
    }

    func clear() {
        local.clear()
    }

    private func publishIdentityIfPossible(username: String, seed: Data?) async {
        do {
            if let seed {
                try keyManager.bootstrapIdentityIfNeeded(seed: seed)
            }

            let bundle = try keyManager.makePreKeyBundle(oneTimeCount: 20)
            let deviceId = authContext.currentDeviceId()

            _ = try await usersService.register(bundle.asRegisterDTO(username: username, deviceId: deviceId))
            _ = try await preKeysService.publish(bundle.asPublishDTO(username: username, deviceId: deviceId))
        } catch {
            #if DEBUG
            print("Network auth sync skipped due to error: \(error)")
            #endif
        }
    }
}
