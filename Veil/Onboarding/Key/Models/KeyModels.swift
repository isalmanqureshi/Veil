//
//  KeyModels.swift
//  Veil
//
//  Created by Salman Qureshi on 2/11/26.
//

import Foundation
import CryptoKit

struct IdentityKeyPair: Equatable {
    let signingPublicKey: Data          // Ed25519 public raw
    let agreementPublicKey: Data        // X25519 public raw
}

struct SignedPreKey: Identifiable, Equatable {
    let id: UInt32
    let publicKey: Data                 // X25519 public raw
    let signature: Data                 // Ed25519 signature over (id || publicKey)
    let createdAt: Date
}

struct OneTimePreKey: Identifiable, Equatable, Codable {
    let id: UInt32
    let publicKey: Data                 // X25519 public raw
    let createdAt: Date
}

struct PreKeyBundle: Equatable {
    let identity: IdentityKeyPair
    let signedPreKey: SignedPreKey
    let oneTimePreKeys: [OneTimePreKey]
}
