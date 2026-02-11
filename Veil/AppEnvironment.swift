//
//  AppEnvironment.swift
//  Veil
//
//  Created by Salman Qureshi on 2/10/26.
//
import SwiftUI
/**
 Screen                  Data Source
 Welcome                Static
 Username               MockIdentityRepository
 Recovery Key         MockIdentityRepository
 Inbox                      MockChatRepository
 Start Chat               MockChatRepository
 Chat                        MockChatRepository
 Status                       Static
 Privacy Dashboard    Static
 Group Creation          MockGroupRepository
 Trust Warnings          MockTrustRepository

 Every run → same behavior.
 */

final class AppEnvironment: ObservableObject {

    let identityRepo: IdentityRepository
    let crypto: CryptoService
    let trustRepo: TrustRepository
    let chatRepo: ChatRepository
    let requestsRepo: MessageRequestsRepository

    init(
        identityRepo: IdentityRepository = MockIdentityRepository(),
        crypto: CryptoService = MockCryptoService(),
        trustRepo: TrustRepository = MockTrustRepository()
    ) {
        self.identityRepo = identityRepo
        self.trustRepo = trustRepo
        self.crypto = crypto
        
        let chat = MockChatRepository(crypto: crypto)
        self.chatRepo = chat
        self.requestsRepo = MockMessageRequestsRepository(chatRepo: chat)
    }
}
