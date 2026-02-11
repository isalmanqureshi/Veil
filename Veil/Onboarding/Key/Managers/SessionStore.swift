//
//  SessionStore.swift
//  Veil
//
//  Created by Salman Qureshi on 2/11/26.
//

import Foundation

import Foundation

struct RemotePreKeyBundle {
    let username: String

    // Identity
    let identitySigningPublicKey: Data    // Ed25519 pub
    let identityAgreementPublicKey: Data  // X25519 pub

    // Signed prekey
    let signedPreKeyId: UInt32
    let signedPreKeyPublicKey: Data       // X25519 pub
    let signedPreKeySignature: Data       // Ed25519 signature over (id || pub)

    // One-time prekey (optional)
    let oneTimePreKeyId: UInt32?
    let oneTimePreKeyPublicKey: Data?
}

struct SessionState: Codable, Equatable {
    let username: String
    let createdAt: Date

    // X3DH output
    let rootKey: Data

    // Ratchet placeholders (fill in later)
    var sendingChainKey: Data
    var receivingChainKey: Data
}


protocol SessionStore {
    func load(username: String) -> SessionState?
    func save(_ session: SessionState)
    func delete(username: String)
}

final class InMemorySessionStore: SessionStore {
    private var dict: [String: SessionState] = [:]

    func load(username: String) -> SessionState? { dict[username] }
    func save(_ session: SessionState) { dict[session.username] = session }
    func delete(username: String) { dict.removeValue(forKey: username) }
}
