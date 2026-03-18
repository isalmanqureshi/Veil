import Foundation
import Combine

@MainActor
final class PreKeySyncManager: ObservableObject {
    @Published private(set) var lastSyncAt: Date?
    @Published private(set) var lastError: String?

    private let keyManager: KeyManager
    private let preKeysService: PreKeysService
    private let authContext: LocalAuthContext
    private let maxSignedPreKeyAgeDays: Int
    private let oneTimePreKeyMinimumCount: Int
    private let oneTimePreKeyTargetCount: Int
    private let maintenanceIntervalNanoseconds: UInt64

    private var maintenanceTask: Task<Void, Never>?

    init(
        keyManager: KeyManager = KeyManager(),
        preKeysService: PreKeysService,
        authContext: LocalAuthContext = LocalAuthContext(),
        maintenanceIntervalSeconds: TimeInterval,
        maxSignedPreKeyAgeDays: Int,
        oneTimePreKeyMinimumCount: Int,
        oneTimePreKeyTargetCount: Int
    ) {
        self.keyManager = keyManager
        self.preKeysService = preKeysService
        self.authContext = authContext
        self.maxSignedPreKeyAgeDays = maxSignedPreKeyAgeDays
        self.oneTimePreKeyMinimumCount = oneTimePreKeyMinimumCount
        self.oneTimePreKeyTargetCount = oneTimePreKeyTargetCount
        self.maintenanceIntervalNanoseconds = UInt64(max(maintenanceIntervalSeconds, 60) * 1_000_000_000)
    }

    func startMaintenance() {
        guard maintenanceTask == nil else { return }
        maintenanceTask = Task { [maintenanceIntervalNanoseconds] in
            while !Task.isCancelled {
                await syncIfNeeded()

                do {
                    try await Task.sleep(nanoseconds: maintenanceIntervalNanoseconds)
                } catch {
                    break
                }
            }
        }
    }

    func stopMaintenance() {
        maintenanceTask?.cancel()
        maintenanceTask = nil
    }

    func syncIfNeeded() async {
        guard let username = authContext.currentSignedInUsername() else { return }

        let deviceId = authContext.currentDeviceId()

        do {
            let previousSignedPreKey = try keyManager.currentSignedPreKey()
            let ensuredSignedPreKey = try keyManager.ensureSignedPreKey(maxAgeDays: maxSignedPreKeyAgeDays)
            let signedPreKeyRotated = previousSignedPreKey?.id != ensuredSignedPreKey.id

            let previousOneTimeCount = try keyManager.oneTimePreKeyCount()
            let didReplenishOneTimePreKeys = previousOneTimeCount < oneTimePreKeyMinimumCount
            if didReplenishOneTimePreKeys {
                _ = try keyManager.ensureOneTimePreKeys(minCount: oneTimePreKeyTargetCount)
            }

            if signedPreKeyRotated || didReplenishOneTimePreKeys {
                let bundle = try keyManager.makePreKeyBundle(oneTimeCount: oneTimePreKeyTargetCount)
                _ = try await preKeysService.publish(bundle.asPublishDTO(username: username, deviceId: deviceId))
            }

            lastSyncAt = Date()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func replenishOneTimePreKeysIfNeeded() async {
        await syncIfNeeded()
    }

    func rotateSignedPreKeyIfNeeded() async {
        await syncIfNeeded()
    }
}
