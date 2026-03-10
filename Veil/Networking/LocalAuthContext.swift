import Foundation

struct LocalAuthContext {
    private let usernameKey = "veil.currentUser.username"
    private let deviceIdentityStore: DeviceIdentityStore

    init(deviceIdentityStore: DeviceIdentityStore = DeviceIdentityStore()) {
        self.deviceIdentityStore = deviceIdentityStore
    }

    func currentUsername() -> String? {
        UserDefaults.standard.string(forKey: usernameKey)
    }

    func currentDeviceId() -> String {
        deviceIdentityStore.currentDeviceId()
    }
}
