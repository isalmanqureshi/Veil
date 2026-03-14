import Foundation

protocol LocalDataWiping {
    func wipeAllLocalData()
}

final class LocalDataWiper: LocalDataWiping {
    private let authRepository: AuthRepository
    private let passwordManager: PasswordManager
    private let keyManager: KeyManager
    private let pushTokenStore: PushTokenStore
    private let defaults: UserDefaults

    private let sessionSignedInKey = "veil.session.isSignedIn"
    private let currentDeviceIdKey = "veil.currentDevice.id"

    init(
        authRepository: AuthRepository,
        passwordManager: PasswordManager = PasswordManager(),
        keyManager: KeyManager = KeyManager(),
        pushTokenStore: PushTokenStore = PushTokenStore(),
        defaults: UserDefaults = .standard
    ) {
        self.authRepository = authRepository
        self.passwordManager = passwordManager
        self.keyManager = keyManager
        self.pushTokenStore = pushTokenStore
        self.defaults = defaults
    }

    func wipeAllLocalData() {
        authRepository.clear()
        passwordManager.clearPassword()
        keyManager.eraseLocalKeyMaterial()
        pushTokenStore.clear()

        defaults.removeObject(forKey: sessionSignedInKey)
        defaults.removeObject(forKey: currentDeviceIdKey)
    }
}
