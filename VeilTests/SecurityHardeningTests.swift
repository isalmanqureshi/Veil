import XCTest
@testable import Veil

final class SecurityHardeningTests: XCTestCase {

    func testLocalDataWipeClearsDeviceIdentityAndPushTokenArtifacts() {
        let testKeychain = KeychainStore()
        let deviceStore = DeviceIdentityStore(deviceIdKey: "veil.test.device.id.\(UUID().uuidString)", keychain: testKeychain)
        let pushStore = PushTokenStore(keychain: testKeychain)
        let defaults = UserDefaults(suiteName: "veil.tests.wipe.\(UUID().uuidString)")!

        let authRepo = TestAuthRepository()
        let keyManager = KeyManager(keychain: testKeychain, service: "veil.tests.keys.\(UUID().uuidString)")
        let passwordManager = PasswordManager(keychain: testKeychain)

        defaults.set(true, forKey: "veil.session.isSignedIn")
        defaults.set("legacy-device-id", forKey: "veil.currentDevice.id")

        let initialDeviceId = deviceStore.currentDeviceId()
        XCTAssertFalse(initialDeviceId.isEmpty)

        let tokenData = Data([0x01, 0x02, 0x03, 0x04])
        pushStore.save(tokenData: tokenData)
        pushStore.markSynced(tokenHex: "01020304", username: "alice")

        let wiper = LocalDataWiper(
            authRepository: authRepo,
            passwordManager: passwordManager,
            keyManager: keyManager,
            pushTokenStore: pushStore,
            deviceIdentityStore: deviceStore,
            defaults: defaults
        )

        wiper.wipeAllLocalData()

        XCTAssertTrue(authRepo.didClear)
        XCTAssertNil(pushStore.currentTokenData())
        XCTAssertTrue(pushStore.shouldSync(tokenHex: "01020304", username: "alice"))
        XCTAssertNil(defaults.object(forKey: "veil.session.isSignedIn"))
        XCTAssertNil(defaults.object(forKey: "veil.currentDevice.id"))

        let regeneratedDeviceId = deviceStore.currentDeviceId()
        XCTAssertFalse(regeneratedDeviceId.isEmpty)
        XCTAssertNotEqual(initialDeviceId, regeneratedDeviceId)
    }

    #if DEBUG
    func testHTTPClientRedactsSensitiveKeysInDebugBodyLogging() throws {
        let raw: [String: String] = [
            "payloadB64": "ciphertext",
            "token": "push_token",
            "password": "hunter2",
            "recoveryKey": "abcd-efgh",
            "seed": "seed-bytes",
            "signature": "sig-bytes",
            "previewCiphertext": "preview",
            "username": "alice"
        ]
        let body = try JSONSerialization.data(withJSONObject: raw, options: [])

        guard let redacted = HTTPClient.redactedJSONObject(from: body) else {
            return XCTFail("Expected redacted JSON")
        }

        XCTAssertEqual(redacted["username"] as? String, "alice")
        XCTAssertEqual(redacted["payloadB64"] as? String, "<redacted>")
        XCTAssertEqual(redacted["token"] as? String, "<redacted>")
        XCTAssertEqual(redacted["password"] as? String, "<redacted>")
        XCTAssertEqual(redacted["recoveryKey"] as? String, "<redacted>")
        XCTAssertEqual(redacted["seed"] as? String, "<redacted>")
        XCTAssertEqual(redacted["signature"] as? String, "<redacted>")
        XCTAssertEqual(redacted["previewCiphertext"] as? String, "<redacted>")
    }
    #endif
}

private final class TestAuthRepository: AuthRepository {
    private(set) var didClear = false

    func loadCurrentUser() -> UserIdentity? { nil }

    func prepareRecoveryKey() throws -> (recoveryKey: String, seed: Data) {
        ("", Data())
    }

    func createUser(username: String, seed: Data, recoveryKey: String) -> UserIdentity {
        UserIdentity(id: UUID(), username: username, recoveryKey: recoveryKey, isVerified: false)
    }

    func restoreUser(username: String, recoveryKey: String) -> UserIdentity? {
        UserIdentity(id: UUID(), username: username, recoveryKey: recoveryKey, isVerified: false)
    }

    func clear() {
        didClear = true
    }
}
