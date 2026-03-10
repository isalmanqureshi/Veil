import SwiftUI
import UIKit
import UserNotifications

@MainActor
final class AppEnvironment: ObservableObject {

    let config: BackendConfig

    let authRepo: AuthRepository
    let identityRepo: IdentityRepository
    let crypto: CryptoService
    let trustRepo: TrustRepository
    let chatRepo: ChatRepository
    let requestsRepo: MessageRequestsRepository
    let purchaseProvider: PurchaseProvider
    let entitlements: EntitlementsStore
    let identitySyncService: IdentitySyncService
    let deviceIdentityStore: DeviceIdentityStore
    let notificationCoordinator: PushNotificationCoordinator

    let httpClient: HTTPClient?
    let usersService: UsersService?
    let preKeysService: PreKeysService?
    let messagesService: MessagesService?
    let requestsService: RequestsService?
    let devicePushTokenService: DevicePushTokenService

    private let poller: MessagePoller?
    private let preKeySyncManager: PreKeySyncManager?
    private var isAppActive = false
    private var isSignedIn = false

    init(
        config: BackendConfig = .default,
        authRepo: AuthRepository? = nil,
        identityRepo: IdentityRepository = MockIdentityRepository(),
        crypto: CryptoService = MockCryptoService(),
        trustRepo: TrustRepository = MockTrustRepository(),
        purchaseProvider: PurchaseProvider = FallbackPurchaseProvider()
    ) {
        self.config = config
        self.identityRepo = identityRepo
        self.trustRepo = trustRepo
        self.crypto = crypto
        self.purchaseProvider = purchaseProvider
        self.entitlements = EntitlementsStore(purchaseProvider: purchaseProvider)
        self.deviceIdentityStore = DeviceIdentityStore()

        if config.useMockBackend {
            self.httpClient = nil
            self.usersService = nil
            self.preKeysService = nil
            self.messagesService = nil
            self.requestsService = nil
            self.devicePushTokenService = NoopDevicePushTokenService()

            let finalAuthRepo = authRepo ?? MockAuthRepository()
            let chat = MockChatRepository(crypto: crypto)
            self.authRepo = finalAuthRepo
            self.identitySyncService = NoopIdentitySyncService()
            self.chatRepo = chat
            self.requestsRepo = MockMessageRequestsRepository(chatRepo: chat)
            self.poller = nil
            self.preKeySyncManager = nil
        } else {
            let httpClient = HTTPClient(config: config)
            let usersService = NetworkUsersService(httpClient: httpClient)
            let preKeysService = NetworkPreKeysService(httpClient: httpClient)
            let messagesService = NetworkMessagesService(httpClient: httpClient)
            let requestsService = NetworkRequestsService(httpClient: httpClient)

            let localAuth = authRepo ?? MockAuthRepository()
            let chatRepo = NetworkChatRepository(crypto: crypto, messagesService: messagesService, preKeysService: preKeysService)
            let requestsRepo = NetworkMessageRequestsRepository(service: requestsService, chatRepo: chatRepo)

            self.httpClient = httpClient
            self.usersService = usersService
            self.preKeysService = preKeysService
            self.messagesService = messagesService
            self.requestsService = requestsService
            self.devicePushTokenService = NetworkDevicePushTokenService(httpClient: httpClient)
            self.authRepo = localAuth
            self.identitySyncService = NetworkIdentitySyncService(usersService: usersService, preKeysService: preKeysService)
            self.chatRepo = chatRepo
            self.requestsRepo = requestsRepo
            self.poller = MessagePoller(
                messagesService: messagesService,
                chatRepository: chatRepo,
                requestsRepository: requestsRepo,
                pollIntervalSeconds: config.pollIntervalSeconds
            )
            self.preKeySyncManager = PreKeySyncManager(
                preKeysService: preKeysService,
                maintenanceIntervalSeconds: config.preKeyMaintenanceIntervalSeconds,
                maxSignedPreKeyAgeDays: config.signedPreKeyMaxAgeDays,
                oneTimePreKeyMinimumCount: config.oneTimePreKeyMinimumCount,
                oneTimePreKeyTargetCount: config.oneTimePreKeyTargetCount
            )
        }

        let tokenStore = PushTokenStore()
        let tokenSyncService = PushTokenSyncService(
            tokenStore: tokenStore,
            pushTokenService: devicePushTokenService
        )
        self.notificationCoordinator = PushNotificationCoordinator(
            tokenStore: tokenStore,
            tokenSyncService: tokenSyncService
        )
        self.notificationCoordinator.configureRefreshHandler { [weak self] in
            guard let self else { return false }
            return await self.refreshInboxFromPush()
        }
    }

    func setSignedIn(_ signedIn: Bool) {
        isSignedIn = signedIn
        updatePollingState()
        if signedIn {
            Task {
                await notificationCoordinator.requestAuthorizationIfNeeded()
                await notificationCoordinator.syncTokenIfPossible()
            }
        }
    }

    func setAppActive(_ active: Bool) {
        isAppActive = active
        updatePollingState()
        if active {
            notificationCoordinator.registerForRemoteNotifications()
        }
    }


    func syncPreKeysIfNeeded() {
        Task {
            await preKeySyncManager?.syncIfNeeded()
        }
    }

    func refreshInboxFromPush() async -> Bool {
        await poller?.refreshNow() ?? false
    }

    private func updatePollingState() {
        if isSignedIn && isAppActive {
            poller?.start()
            preKeySyncManager?.startMaintenance()
            Task {
                await preKeySyncManager?.syncIfNeeded()
            }
        } else {
            poller?.stop()
            preKeySyncManager?.stopMaintenance()
        }
    }
}

final class PushTokenStore {
    private let defaults: UserDefaults
    private let tokenKey = "veil.push.apns.token"
    private let tokenSyncedKey = "veil.push.apns.token.synced"
    private let tokenSyncedUserKey = "veil.push.apns.token.synced.username"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func save(tokenData: Data) {
        defaults.set(tokenData, forKey: tokenKey)
    }

    func hasTokenChanged(_ tokenData: Data) -> Bool {
        guard let existing = defaults.data(forKey: tokenKey) else { return true }
        return existing != tokenData
    }

    func currentTokenData() -> Data? {
        defaults.data(forKey: tokenKey)
    }

    func currentTokenHex() -> String? {
        guard let tokenData = currentTokenData() else { return nil }
        return tokenData.map { String(format: "%02.2hhx", $0) }.joined()
    }

    func shouldSync(tokenHex: String, username: String) -> Bool {
        defaults.string(forKey: tokenSyncedKey) != tokenHex || defaults.string(forKey: tokenSyncedUserKey) != username
    }

    func markSynced(tokenHex: String, username: String) {
        defaults.set(tokenHex, forKey: tokenSyncedKey)
        defaults.set(username, forKey: tokenSyncedUserKey)
    }
}

final class PushTokenSyncService {
    private let tokenStore: PushTokenStore
    private let pushTokenService: DevicePushTokenService
    private let authContext: LocalAuthContext

    init(
        tokenStore: PushTokenStore,
        pushTokenService: DevicePushTokenService,
        authContext: LocalAuthContext = LocalAuthContext()
    ) {
        self.tokenStore = tokenStore
        self.pushTokenService = pushTokenService
        self.authContext = authContext
    }

    func updateToken(_ tokenData: Data) async {
        if tokenStore.hasTokenChanged(tokenData) {
            tokenStore.save(tokenData: tokenData)
        }
        await syncCurrentTokenIfPossible()
    }

    func syncCurrentTokenIfPossible() async {
        guard let username = authContext.currentUsername(),
              let tokenHex = tokenStore.currentTokenHex()
        else {
            return
        }

        guard tokenStore.shouldSync(tokenHex: tokenHex, username: username) else {
            return
        }

        do {
            _ = try await pushTokenService.registerToken(
                .init(
                    username: username,
                    deviceId: authContext.currentDeviceId(),
                    token: tokenHex,
                    platform: "ios"
                )
            )
            tokenStore.markSynced(tokenHex: tokenHex, username: username)
        } catch {
            print("Push token sync failed for iOS device: \(error.localizedDescription)")
        }
    }
}

@MainActor
final class PushNotificationCoordinator: NSObject, UNUserNotificationCenterDelegate {
    static let shared = PushNotificationCoordinator(
        tokenStore: PushTokenStore(),
        tokenSyncService: PushTokenSyncService(
            tokenStore: PushTokenStore(),
            pushTokenService: NoopDevicePushTokenService()
        )
    )

    private let tokenStore: PushTokenStore
    private let tokenSyncService: PushTokenSyncService
    private var refreshHandler: (() async -> Bool)?

    init(tokenStore: PushTokenStore, tokenSyncService: PushTokenSyncService) {
        self.tokenStore = tokenStore
        self.tokenSyncService = tokenSyncService
        super.init()
        UNUserNotificationCenter.current().delegate = self
        PushNotificationCoordinator.sharedBridge = self
    }

    private static var sharedBridge: PushNotificationCoordinator?

    static func bridge() -> PushNotificationCoordinator {
        sharedBridge ?? shared
    }

    func configureRefreshHandler(_ refreshHandler: @escaping () async -> Bool) {
        self.refreshHandler = refreshHandler
    }

    func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            _ = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
        case .denied, .authorized, .provisional, .ephemeral:
            break
        @unknown default:
            break
        }
    }

    func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    func didRegisterForRemoteNotifications(deviceToken: Data) {
        Task {
            await tokenSyncService.updateToken(deviceToken)
        }
    }

    func didFailToRegisterForRemoteNotifications(error: Error) {
        print("APNs registration unavailable: \(error.localizedDescription)")
    }

    func syncTokenIfPossible() async {
        await tokenSyncService.syncCurrentTokenIfPossible()
    }

    func handleRemoteNotification(userInfo: [AnyHashable: Any], completion: @escaping (UIBackgroundFetchResult) -> Void) {
        Task {
            let refreshed = await refreshHandler?() ?? false
            completion(refreshed ? .newData : .noData)
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        Task { @MainActor in
            _ = await self.refreshHandler?()
            completionHandler([.banner, .badge, .sound])
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            _ = await self.refreshHandler?()
            completionHandler()
        }
    }
}
