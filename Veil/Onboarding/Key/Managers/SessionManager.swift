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
            rootKey: rootKey,
            sendingChainKey: ckSend,
            receivingChainKey: ckRecv
        )

        store.save(session)
        return session
    }

    func session(for username: String) -> SessionState? {
        store.load(username: username)
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


