import Foundation

struct DeviceIdentityStore {
    private let deviceIdKey: String
    private let userDefaults: UserDefaults

    init(deviceIdKey: String = "veil.currentDevice.id", userDefaults: UserDefaults = .standard) {
        self.deviceIdKey = deviceIdKey
        self.userDefaults = userDefaults
    }

    func currentDeviceId() -> String {
        if let existing = userDefaults.string(forKey: deviceIdKey), !existing.isEmpty {
            return existing
        }

        let newId = UUID().uuidString
        userDefaults.set(newId, forKey: deviceIdKey)
        return newId
    }
}
