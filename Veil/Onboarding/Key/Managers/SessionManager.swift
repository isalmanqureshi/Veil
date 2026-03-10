//
//  SessionManager.swift
//  Veil
//
//  Created by Salman Qureshi on 2/11/26.
//

import Foundation
import CryptoKit

enum SessionError: Error {
    case invalidRemoteBundle
    case signatureInvalid
    case missingOneTimePreKey
    case cryptoFailure
}
//X3DH-style handshake
final class SessionManager {

    private let keyManager: KeyManager
    private let store: SessionStore

    init(keyManager: KeyManager = KeyManager(),
         store: SessionStore = InMemorySessionStore()) {
        self.keyManager = keyManager
        self.store = store
    }

    // MARK: - Initiator side (you start a chat)

    /// Establish a new session using remote prekey bundle.
    /// Returns the derived SessionState and saves it.
    func establishSessionAsInitiator(remote: RemotePreKeyBundle) throws -> SessionState {
        // 1) Verify remote signed prekey signature with remote identity signing key
        try verifySignedPreKey(remote: remote)

        // 2) Generate ephemeral key (X25519)
        let ek = Curve25519.KeyAgreement.PrivateKey()

        // 3) Load local identity agreement private key
        // We don’t expose it publicly from KeyManager, so add a method OR do DH inside KeyManager.
        // For skeleton, we’ll add a KeyManager helper below (see section 2.4).
        let ikA = try keyManager.loadIdentityAgreementPrivateKey_forSession()

        // Remote keys
        let remoteIKB = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: remote.identityAgreementPublicKey)
        let remoteSPKB = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: remote.signedPreKeyPublicKey)

        // 4) Compute DH outputs (X3DH-ish)
        // DH1 = DH(IK_A, SPK_B)
        let dh1 = try ikA.sharedSecretFromKeyAgreement(with: remoteSPKB)

        // DH2 = DH(EK_A, IK_B)
        let dh2 = try ek.sharedSecretFromKeyAgreement(with: remoteIKB)

        // DH3 = DH(EK_A, SPK_B)
        let dh3 = try ek.sharedSecretFromKeyAgreement(with: remoteSPKB)

        // DH4 = DH(EK_A, OTK_B) optional
        var dh4Data = Data()
        if let otkPub = remote.oneTimePreKeyPublicKey {
            let remoteOTKB = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: otkPub)
            let dh4 = try ek.sharedSecretFromKeyAgreement(with: remoteOTKB)
            dh4Data = dh4.ssData
        }

        // 5) Combine secrets into a single input key material
        let ikm = dh1.ssData + dh2.ssData + dh3.ssData + dh4Data

        // 6) Derive root key + initial chain keys (placeholders for Double Ratchet)
        let (rootKey, ckSend, ckRecv) = deriveInitialKeys(ikm: ikm, info: "veil.x3dh.v1")

        let session = SessionState(
            username: remote.username,
            createdAt: Date(),
            remoteOneTimePreKeyId: remote.oneTimePreKeyId,
            rootKey: rootKey,
            sendingChainKey: ckSend,
            receivingChainKey: ckRecv,
            sendCount: 0,
            recvCount: 0
        )

        store.save(session)
        return session
    }

    func session(for username: String) -> SessionState? {
        store.load(username: username)
    }

    func saveSession(_ session: SessionState) {
        store.save(session)
    }

    func decryptAndPersist(ciphertext: String, from username: String, crypto: CryptoService = MockCryptoService()) -> String? {
        guard var session = store.load(username: username) else { return nil }
        guard let plaintext = try? crypto.decrypt(ciphertext: ciphertext, for: username, session: &session) else {
            return nil
        }
        store.save(session)
        return plaintext
    }

    // MARK: - Helpers
    
    private func verifySignedPreKey(remote: RemotePreKeyBundle) throws {
        let signPub = try Curve25519.Signing.PublicKey(rawRepresentation: remote.identitySigningPublicKey)

        var msg = Data()
        msg.append(contentsOf: withUnsafeBytes(of: remote.signedPreKeyId.bigEndian, Array.init))
        msg.append(remote.signedPreKeyPublicKey)

        // Ed25519 signature is raw Data in CryptoKit
        let sig = remote.signedPreKeySignature

        guard signPub.isValidSignature(sig, for: msg) else {
            throw SessionError.signatureInvalid
        }
    }

    private func deriveInitialKeys(ikm: Data, info: String) -> (Data, Data, Data) {
        let salt = Data("veil.session.salt".utf8)
        let ikmKey = SymmetricKey(data: ikm)

        let okm = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: ikmKey,
            salt: salt,
            info: Data(info.utf8),
            outputByteCount: 96
        )

        let out = okm.withUnsafeBytes { Data($0) }
        let root = out.subdata(in: 0..<32)
        let ckSend = out.subdata(in: 32..<64)
        let ckRecv = out.subdata(in: 64..<96)
        return (root, ckSend, ckRecv)
    }
    
    //TO:DO
    /**
     Right now you pass kmRemote: KeyManager. In practice, you can only create remote bundles if you have remote key material. For local testing, create a second KeyManager with a different seed and bootstrap it, then make bundle.

     Example test flow:

     bootstrap local KeyManager with local seed

     bootstrap “remote” KeyManager with remote seed

     bundle = remote.makePreKeyBundle

     establishSessionAsInitiator(remote: bundleAsRemote)
     */
    func mockRemoteBundle(for username: String, kmRemote: KeyManager) throws -> RemotePreKeyBundle {
        let bundle = try kmRemote.makePreKeyBundle(oneTimeCount: 1)
        return RemotePreKeyBundle(
            username: username,
            identitySigningPublicKey: bundle.identity.signingPublicKey,
            identityAgreementPublicKey: bundle.identity.agreementPublicKey,
            signedPreKeyId: bundle.signedPreKey.id,
            signedPreKeyPublicKey: bundle.signedPreKey.publicKey,
            signedPreKeySignature: bundle.signedPreKey.signature,
            oneTimePreKeyId: bundle.oneTimePreKeys.first?.id,
            oneTimePreKeyPublicKey: bundle.oneTimePreKeys.first?.publicKey
        )
    }
}

// MARK: - SharedSecret extraction

private extension SharedSecret {
    var ssData: Data { withUnsafeBytes { Data($0) } }
}

extension SessionManager {
    @discardableResult
    func debugCryptoRoundTrip(username: String = "debug_peer") -> Bool {
        do {
            let remote = KeyManager(service: "veil.keys.remote.debug.\(username)")
            let seed = Data(SHA256.hash(data: Data("veil.remote.debug.\(username)".utf8)))
            try remote.bootstrapIdentityIfNeeded(seed: seed)
            let bundle = try mockRemoteBundle(for: username, kmRemote: remote)
            var session = try establishSessionAsInitiator(remote: bundle)
            let crypto = MockCryptoService()
            let cipher = try crypto.encrypt(plaintext: "hello", for: username, session: &session)
            let plain = try crypto.decrypt(ciphertext: cipher, for: username, session: &session)
            return plain == "hello"
        } catch {
            return false
        }
    }

    @discardableResult
    func debugChainRoundTrip(username: String = "debug_peer_chain") -> Bool {
        do {
            let remote = KeyManager(service: "veil.keys.remote.debug.\(username)")
            let seed = Data(SHA256.hash(data: Data("veil.remote.debug.\(username)".utf8)))
            try remote.bootstrapIdentityIfNeeded(seed: seed)
            let bundle = try mockRemoteBundle(for: username, kmRemote: remote)
            var senderSession = try establishSessionAsInitiator(remote: bundle)

            var receiverSession = senderSession
            receiverSession.receivingChainKey = senderSession.sendingChainKey
            receiverSession.recvCount = 0
            receiverSession.skippedMessageKeys = []

            let crypto = MockCryptoService()
            let c0 = try crypto.encrypt(plaintext: "zero", for: username, session: &senderSession)
            let c1 = try crypto.encrypt(plaintext: "one", for: username, session: &senderSession)
            let c2 = try crypto.encrypt(plaintext: "two", for: username, session: &senderSession)

            let p2 = try crypto.decrypt(ciphertext: c2, for: username, session: &receiverSession)
            let p0 = try crypto.decrypt(ciphertext: c0, for: username, session: &receiverSession)
            let p1 = try crypto.decrypt(ciphertext: c1, for: username, session: &receiverSession)

            return p2 == "two"
                && p0 == "zero"
                && p1 == "one"
                && senderSession.sendCount == 3
                && receiverSession.recvCount == 3
                && receiverSession.skippedMessageKeys.isEmpty
        } catch {
            return false
        }
    }
}
