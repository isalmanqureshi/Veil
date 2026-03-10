//
//  AppEnvironment.swift
//  Veil
//
//  Created by Salman Qureshi on 2/10/26.
//
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

    let httpClient: HTTPClient?
    let preKeyService: PreKeyService?
    let messageService: MessageService?
    let requestsService: RequestsService?

    private let poller: MessagePoller?
    private var isAppActive = false
    private var isSignedIn = false

    init(
        config: BackendConfig = .default,
        authRepo: AuthRepository = MockAuthRepository(),
        identityRepo: IdentityRepository = MockIdentityRepository(),
        crypto: CryptoService = MockCryptoService(),
        trustRepo: TrustRepository = MockTrustRepository()
    ) {
        self.config = config
        self.authRepo = authRepo
        self.identityRepo = identityRepo
        self.trustRepo = trustRepo
        self.crypto = crypto

        if config.useMock {
            self.httpClient = nil
            self.preKeyService = nil
            self.messageService = nil
            self.requestsService = nil

            let chat = MockChatRepository(crypto: crypto)
            self.chatRepo = chat
            self.requestsRepo = MockMessageRequestsRepository(chatRepo: chat)
            self.poller = nil
        } else {
            let httpClient = HTTPClient(config: config)
            let preKeyService = NetworkPreKeyService(httpClient: httpClient)
            let messageService = NetworkMessageService(httpClient: httpClient)
            let requestsService = NetworkRequestsService(httpClient: httpClient)

            let chatRepo = NetworkChatRepository(
                crypto: crypto,
                messageService: messageService,
                preKeyService: preKeyService
            )
            let requestsRepo = NetworkMessageRequestsRepository(
                service: requestsService,
                chatRepo: chatRepo
            )

            self.httpClient = httpClient
            self.preKeyService = preKeyService
            self.messageService = messageService
            self.requestsService = requestsService
            self.chatRepo = chatRepo
            self.requestsRepo = requestsRepo
            self.poller = MessagePoller(
                messageService: messageService,
                chatRepository: chatRepo,
                requestsRepository: requestsRepo
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
