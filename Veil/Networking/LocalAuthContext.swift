import Foundation

struct LocalAuthContext {
    private let usernameKey = "veil.currentUser.username"
    private let sessionSignedInKey = "veil.session.isSignedIn"
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
