//
//  AbuseSignal.swift
//  Veil
//
//  Created by Salman Qureshi on 2/10/26.
//
import SwiftUI

struct AbuseSignal {
    let type: SignalType
    let timestamp: Date
    let context: SignalContext

    enum SignalType {
        case outboundRequest
        case blockedByPeer
        case reportedByPeer
        case rapidMessageBurst
        case inviteAbuse
        case screenshotDetected
        case identityChanged
        case deviceAdded
    }

    struct SignalContext {
        let peerCount: Int?
        let timeWindow: TimeInterval?
        let viaInvite: Bool?
    }
}

