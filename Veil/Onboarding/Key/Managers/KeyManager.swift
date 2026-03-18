//
//  KeyManager.swift
//  Veil
//
//  Created by Salman Qureshi on 2/11/26.
//

import Foundation
import SwiftUI
import CryptoKit

enum KeyManagerError: Error {
    case invalidSeedLength
    case keychainFailure
    case missingIdentity
    case corruptedKeyMaterial
}

final class KeyManager {

    // MARK: - Storage

    private let keychain: KeychainStore
    private let service: String

    // MARK: - Keychain accounts

    private let acctIdentitySignPriv = "identity.sign.priv"
    private let acctIdentityAgreePriv = "identity.agree.priv"

    private let acctSignedPreKeyId = "prekey.signed.id"
    private let acctSignedPreKeyPriv = "prekey.signed.priv"
    private let acctSignedPreKeySig = "prekey.signed.sig"
    private let acctSignedPreKeyCreated = "prekey.signed.created"

    private let acctOneTimePreKeys = "prekey.otk.json"
    private let acctOneTimePreKeyPrivPrefix = "prekey.otk.priv." // + id
    private let acctOneTimePreKeyCreatedPrefix = "prekey.otk.created." // + id

    // MARK: - Init

    init(keychain: KeychainStore = KeychainStore(), service: String = "veil.keys") {
        self.keychain = keychain
        self.service = service
    }

    // MARK: - Identity bootstrap (call after onboarding/login)

    /// Must be called once after you have the 32-byte identity seed (from RecoveryKey).
    func bootstrapIdentityIfNeeded(seed: Data) throws {
        guard seed.count == 32 else { throw KeyManagerError.invalidSeedLength }

        // If already exists, do nothing
        if try keychain.load(service: service, account: acctIdentitySignPriv) != nil,
           try keychain.load(service: service, account: acctIdentityAgreePriv) != nil {
            return
        }

        // Derive deterministic key material
        let signPrivRaw = hkdf32(seed: seed, info: "veil.identity.ed25519")
        let agreePrivRaw = hkdf32(seed: seed, info: "veil.identity.x25519")

        // Validate by constructing keys (will throw if invalid raw)
        _ = try Curve25519.Signing.PrivateKey(rawRepresentation: signPrivRaw)
        _ = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: agreePrivRaw)

        // Store raw private keys (device-only Keychain via your KeychainStore config)
        try keychain.save(signPrivRaw, service: service, account: acctIdentitySignPriv)
        try keychain.save(agreePrivRaw, service: service, account: acctIdentityAgreePriv)
    }

    func loadIdentityPublicKeys() throws -> IdentityKeyPair {
        let signPriv = try loadIdentitySigningPrivateKey()
        let agreePriv = try loadIdentityAgreementPrivateKey()

        return IdentityKeyPair(
            signingPublicKey: signPriv.publicKey.rawRepresentation,
            agreementPublicKey: agreePriv.publicKey.rawRepresentation
        )
    }

    // MARK: - Signed prekey

    /// Ensure a signed prekey exists; rotate if older than `maxAgeDays`.
    func ensureSignedPreKey(maxAgeDays: Int = 30) throws -> SignedPreKey {
        if let existing = try loadSignedPreKey() {
            let age = Date().timeIntervalSince(existing.createdAt)
            let maxAge = Double(maxAgeDays) * 24 * 60 * 60
            if age < maxAge { return existing }
        }
        return try rotateSignedPreKey()
    }

    func rotateSignedPreKey() throws -> SignedPreKey {
        let signingPriv = try loadIdentitySigningPrivateKey()

        let spkPriv = Curve25519.KeyAgreement.PrivateKey()
        let spkPubRaw = spkPriv.publicKey.rawRepresentation

        let id = UInt32.random(in: 1...UInt32.max)

        var toSign = Data()
        toSign.append(contentsOf: withUnsafeBytes(of: id.bigEndian, Array.init))
        toSign.append(spkPubRaw)

        // CryptoKit: signature(for:) returns Data and can throw
        let signature = try signingPriv.signature(for: toSign)
        let createdAt = Date()

        try keychain.save(Data(String(id).utf8), service: service, account: acctSignedPreKeyId)
        try keychain.save(spkPriv.rawRepresentation, service: service, account: acctSignedPreKeyPriv)
        try keychain.save(signature, service: service, account: acctSignedPreKeySig)
        try keychain.save(Data(String(createdAt.timeIntervalSince1970).utf8),
                          service: service, account: acctSignedPreKeyCreated)

        return SignedPreKey(id: id, publicKey: spkPubRaw, signature: signature, createdAt: createdAt)
    }


    // MARK: - One-time prekeys

    /// Ensures there are at least `minCount` one-time prekeys available.
    func ensureOneTimePreKeys(minCount: Int = 20) throws -> [OneTimePreKey] {
        let existing = try loadOneTimePreKeys()
        if existing.count >= minCount { return existing }

        let need = max(0, minCount - existing.count)
        let newKeys = try generateOneTimePreKeys(count: need)

        let merged = existing + newKeys
        try persistOneTimePreKeyIndex(merged)
        return merged
    }

    func generateOneTimePreKeys(count: Int) throws -> [OneTimePreKey] {
        guard count > 0 else { return [] }

        let existing = try Set(loadOneTimePreKeys().map(\.id))
        var usedIds = existing
        var out: [OneTimePreKey] = []
        out.reserveCapacity(count)

        while out.count < count {
            let id = UInt32.random(in: 1...UInt32.max)
            guard !usedIds.contains(id) else { continue }

            let priv = Curve25519.KeyAgreement.PrivateKey()
            let pub = priv.publicKey.rawRepresentation
            let createdAt = Date()

            try keychain.save(priv.rawRepresentation, service: service, account: acctOneTimePreKeyPrivPrefix + "\(id)")
            try keychain.save(Data(String(createdAt.timeIntervalSince1970).utf8), service: service, account: acctOneTimePreKeyCreatedPrefix + "\(id)")

            out.append(OneTimePreKey(id: id, publicKey: pub, createdAt: createdAt))
            usedIds.insert(id)
        }

        return out
    }

    /// When a server delivers an OTK id, mark it consumed.
    func consumeOneTimePreKey(id: UInt32) throws {
        var current = try loadOneTimePreKeys()
        current.removeAll { $0.id == id }
        try persistOneTimePreKeyIndex(current)

        // delete priv + created
        keychain.delete(service: service, account: acctOneTimePreKeyPrivPrefix + "\(id)")
        keychain.delete(service: service, account: acctOneTimePreKeyCreatedPrefix + "\(id)")
    }

    // MARK: - PreKey bundle (what you publish to server)

    func makePreKeyBundle(oneTimeCount: Int = 20) throws -> PreKeyBundle {
        let identity = try loadIdentityPublicKeys()
        let spk = try ensureSignedPreKey()
        let otks = try ensureOneTimePreKeys(minCount: oneTimeCount)
        return PreKeyBundle(identity: identity, signedPreKey: spk, oneTimePreKeys: otks)
    }


    func currentSignedPreKey() throws -> SignedPreKey? {
        try loadSignedPreKey()
    }

    func oneTimePreKeyCount() throws -> Int {
        try loadOneTimePreKeys().count
    }

    func eraseLocalKeyMaterial() {
        keychain.delete(service: service, account: acctIdentitySignPriv)
        keychain.delete(service: service, account: acctIdentityAgreePriv)
        keychain.delete(service: service, account: acctSignedPreKeyId)
        keychain.delete(service: service, account: acctSignedPreKeyPriv)
        keychain.delete(service: service, account: acctSignedPreKeySig)
        keychain.delete(service: service, account: acctSignedPreKeyCreated)
        keychain.delete(service: service, account: acctOneTimePreKeys)
        keychain.deleteAll(service: service, accountPrefix: acctOneTimePreKeyPrivPrefix)
        keychain.deleteAll(service: service, accountPrefix: acctOneTimePreKeyCreatedPrefix)
    }

    // MARK: - Internal loads

    private func loadIdentitySigningPrivateKey() throws -> Curve25519.Signing.PrivateKey {
        guard let raw = try keychain.load(service: service, account: acctIdentitySignPriv) else {
            throw KeyManagerError.missingIdentity
        }
        return try Curve25519.Signing.PrivateKey(rawRepresentation: raw)
    }

    func loadIdentityAgreementPrivateKey() throws -> Curve25519.KeyAgreement.PrivateKey {
        guard let raw = try keychain.load(service: service, account: acctIdentityAgreePriv) else {
            throw KeyManagerError.missingIdentity
        }
        return try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: raw)
    }

    private func loadSignedPreKey() throws -> SignedPreKey? {
        guard
            let idStr = try keychain.loadString(service: service, account: acctSignedPreKeyId),
            let id = UInt32(idStr),
            let privRaw = try keychain.load(service: service, account: acctSignedPreKeyPriv),
            let sig = try keychain.load(service: service, account: acctSignedPreKeySig),
            let createdStr = try keychain.loadString(service: service, account: acctSignedPreKeyCreated),
            let createdTs = TimeInterval(createdStr)
        else { return nil }

        let priv = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: privRaw)
        return SignedPreKey(
            id: id,
            publicKey: priv.publicKey.rawRepresentation,
            signature: sig,
            createdAt: Date(timeIntervalSince1970: createdTs)
        )
    }

    private func loadOneTimePreKeys() throws -> [OneTimePreKey] {
        guard let data = try keychain.load(service: service, account: acctOneTimePreKeys) else { return [] }
        return (try? JSONDecoder().decode([OneTimePreKey].self, from: data)) ?? []
    }

    private func persistOneTimePreKeyIndex(_ keys: [OneTimePreKey]) throws {
        let data = try JSONEncoder().encode(keys)
        try keychain.save(data, service: service, account: acctOneTimePreKeys)
    }

    // MARK: - HKDF helper (32 bytes)

    private func hkdf32(seed: Data, info: String) -> Data {
        let ikm = SymmetricKey(data: seed)
        let salt = Data("veil.hkdf.salt".utf8)

        let out = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: ikm,
            salt: salt,
            info: Data(info.utf8),
            outputByteCount: 32
        )
        return out.withUnsafeBytes { Data($0) }
    }
}


//extension KeyManager {
//    func loadIdentityAgreementPrivateKey_forSession() throws -> Curve25519.KeyAgreement.PrivateKey {
//        // move your existing private loader to internal or duplicate logic here
//        guard let raw = try KeychainStore().load(service: "veil.keys", account: "identity.agree.priv") else {
//            throw KeyManagerError.missingIdentity
//        }
//        return try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: raw)
//    }
//}

extension KeyManager {
    func loadIdentityAgreementPrivateKey_forSession() throws -> Curve25519.KeyAgreement.PrivateKey {
        // Best: change loadIdentityAgreementPrivateKey() from private -> internal and call it.
               try loadIdentityAgreementPrivateKey()
    }
}

