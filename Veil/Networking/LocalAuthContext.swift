import Foundation

struct LocalAuthContext {
    private let usernameKey = DefaultsKey.username
    private let sessionSignedInKey = DefaultsKey.isSignedIn
    private let deviceIdentityStore: DeviceIdentityStore
    private let defaults: UserDefaults

    init(
        deviceIdentityStore: DeviceIdentityStore = DeviceIdentityStore(),
        defaults: UserDefaults = .standard
    ) {
        self.deviceIdentityStore = deviceIdentityStore
        self.defaults = defaults
    }

    func currentUsername() -> String? {
        defaults.string(forKey: usernameKey)
    }

    func currentSignedInUsername() -> String? {
        guard isSignedIn else { return nil }
        return currentUsername()
    }

    var isSignedIn: Bool {
        defaults.bool(forKey: sessionSignedInKey)
    }

    func currentDeviceId() -> String {
        deviceIdentityStore.currentDeviceId()
    }
}
