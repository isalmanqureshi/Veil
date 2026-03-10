import Foundation

struct LocalAuthContext {
    private let usernameKey = "veil.currentUser.username"
    private let deviceIdKey = "veil.currentDevice.id"

    func currentUsername() -> String? {
        UserDefaults.standard.string(forKey: usernameKey)
    }

    func currentDeviceId() -> String {
        if let existing = UserDefaults.standard.string(forKey: deviceIdKey) {
            return existing
        }

        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: deviceIdKey)
        return newId
    }
}
