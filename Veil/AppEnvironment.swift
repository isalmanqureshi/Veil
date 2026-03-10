import SwiftUI

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

    let httpClient: HTTPClient?
    let usersService: UsersService?
    let preKeysService: PreKeysService?
    let messagesService: MessagesService?
    let requestsService: RequestsService?

    private let poller: MessagePoller?
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

            let finalAuthRepo = authRepo ?? MockAuthRepository()
            let chat = MockChatRepository(crypto: crypto)
            self.authRepo = finalAuthRepo
            self.identitySyncService = NoopIdentitySyncService()
            self.chatRepo = chat
            self.requestsRepo = MockMessageRequestsRepository(chatRepo: chat)
            self.poller = nil
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
        }
    }

    func setSignedIn(_ signedIn: Bool) {
        isSignedIn = signedIn
        updatePollingState()
    }

    func setAppActive(_ active: Bool) {
        isAppActive = active
        updatePollingState()
    }

    private func updatePollingState() {
        guard let poller else { return }
        if isSignedIn && isAppActive {
            poller.start()
        } else {
            poller.stop()
        }
    }
}
