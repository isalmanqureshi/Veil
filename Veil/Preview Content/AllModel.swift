//
//  AllModel.swift
//  Veil
//
//  Created by Salman Qureshi on 2/10/26.
//

import SwiftUI
// MARK: Identity

struct UserIdentity: Identifiable, Equatable {
    let id: UUID
    var username: String
    let recoveryKey: String
    var isVerified: Bool
}

struct DeviceInfo: Identifiable {
    let id: UUID
    let name: String
    let lastActive: Date
    let isTrusted: Bool
}

// MARK: Chat

struct Chat: Identifiable {
    let id: UUID
    let peerUsername: String
    let defaultTimer: MessageTimer
    let isVerified: Bool
}

// MARK: Group

//struct Group: Identifiable {
//    let id: UUID
//    let name: String
//    let members: [String]
//    let policy: GroupPolicy
//}
//
//struct GroupPolicy {
//    let canPost: Bool
//    let dmAllowed: Bool
//    let anonymousMembers: Bool
//    let ephemeralOnly: Bool
//}

struct TrustWarning: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
