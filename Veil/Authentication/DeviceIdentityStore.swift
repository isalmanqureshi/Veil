import Foundation

struct DeviceIdentityStore {
    private let deviceIdKey: String
    private let keychain: KeychainStore
    private let service = "veil.device"

    init(deviceIdKey: String = "veil.currentDevice.id", keychain: KeychainStore = KeychainStore()) {
        self.deviceIdKey = deviceIdKey
        self.keychain = keychain
    }

    func currentDeviceId() -> String {
        if let existing = try? keychain.loadString(service: service, account: deviceIdKey), !existing.isEmpty {
            return existing
        }

        let newId = UUID().uuidString
        try? keychain.saveString(newId, service: service, account: deviceIdKey)
        return newId
    }

    func clear() {
        keychain.delete(service: service, account: deviceIdKey)
    }
}
