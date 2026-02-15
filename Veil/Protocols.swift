//
//  Protocols.swift
//  Veil
//
//  Created by Salman Qureshi on 2/10/26.
//
import SwiftUI

private func stableUUID(_ rawValue: String) -> UUID {
    UUID(uuidString: rawValue) ?? UUID()
}

protocol IdentityRepository {
    func currentUser() -> UserIdentity
    func validateUsername(_ username: String) -> Bool
}


protocol TrustRepository {
    func activeWarnings() -> [TrustWarning]
}


final class MockIdentityRepository: IdentityRepository {

    private let mockUser = UserIdentity(
        id: stableUUID("AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"),
        username: "lorem_user",
        recoveryKey: "lorem-ipsum-dolor-sit-amet",
        isVerified: false
    )

    func currentUser() -> UserIdentity {
        mockUser
    }

    func validateUsername(_ username: String) -> Bool {
        UsernameRules.isValid(username)
    }
}

//
//final class MockChatRepository: ChatRepository {
//
//    private let mockChats: [Chat] = [
//        Chat(
//            id: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
//            peerUsername: "alice",
//            defaultTimer: .day1,
//            isVerified: true
//        )
//    ]
//
//    func chats() -> [Chat] {
//        mockChats
//    }
//
//    func startChat(with username: String) -> Chat {
//        Chat(
//            id: UUID(),
//            peerUsername: username,
//            defaultTimer: .day1,
//            isVerified: false
//        )
//    }
//}


final class MockTrustRepository: TrustRepository {

    func activeWarnings() -> [TrustWarning] {
        [
            TrustWarning(
                title: "New device detected",
                message: "A new device signed in to your account."
            ),
            TrustWarning(
                title: "Screenshot detected",
                message: "Content may now exist outside protected chat."
            )
        ]
    }
}

