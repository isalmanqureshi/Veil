//
//  SessionStore.swift
//  Veil
//
//  Created by Salman Qureshi on 2/11/26.
//

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

struct SkippedKey: Codable, Equatable {
    let counter: UInt32
    let key: Data
}

struct SessionState: Codable, Equatable {
    let username: String
    let createdAt: Date

    // X3DH output
    let rootKey: Data

    // Ratchet placeholders (fill in later)
    var sendingChainKey: Data
    var receivingChainKey: Data
    var sendCount: UInt32 = 0
    var recvCount: UInt32 = 0
    var skippedMessageKeys: [SkippedKey] = []
}

extension SessionState {
    func skippedKey(for counter: UInt32) -> Data? {
        skippedMessageKeys.first(where: { $0.counter == counter })?.key
    }

    mutating func upsertSkippedKey(counter: UInt32, key: Data, capacity: Int) {
        skippedMessageKeys.removeAll(where: { $0.counter == counter })
        skippedMessageKeys.append(SkippedKey(counter: counter, key: key))
        skippedMessageKeys.sort { $0.counter < $1.counter }
        trimSkippedKeys(capacity: capacity)
    }

    mutating func removeSkippedKey(for counter: UInt32) {
        skippedMessageKeys.removeAll(where: { $0.counter == counter })
    }

    mutating func trimSkippedKeys(capacity: Int) {
        guard skippedMessageKeys.count > capacity else { return }
        skippedMessageKeys = Array(skippedMessageKeys.suffix(capacity))
    }
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
