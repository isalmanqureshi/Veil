import Foundation

struct PreKeyBundleDTO: Codable {
    struct IdentityDTO: Codable {
        let signingPublicKeyB64: String
        let agreementPublicKeyB64: String
    }

    struct SignedPreKeyDTO: Codable {
        let id: UInt32
        let publicKeyB64: String
        let signatureB64: String
        let createdAt: Date
    }

    struct OneTimePreKeyDTO: Codable {
        let id: UInt32
        let publicKeyB64: String
        let createdAt: Date
    }

    let identity: IdentityDTO
    let signedPreKey: SignedPreKeyDTO
    let oneTimePreKeys: [OneTimePreKeyDTO]
}

struct RemotePreKeyBundleDTO: Codable {
    let username: String
    let identitySigningPublicKeyB64: String
    let identityAgreementPublicKeyB64: String
    let signedPreKeyId: UInt32
    let signedPreKeyPublicKeyB64: String
    let signedPreKeySignatureB64: String
    let oneTimePreKeyId: UInt32?
    let oneTimePreKeyPublicKeyB64: String?
}

struct MessageEnvelopeDTO: Codable {
    let version: Int
    let to: String
    let from: String?
    let payloadB64: String
}

struct MessageRequestDTO: Codable {
    let id: UUID
    let fromUsername: String
    let previewCiphertext: String
    let createdAt: Date
}

extension PreKeyBundleDTO {
    init(bundle: PreKeyBundle) {
        self.identity = .init(
            signingPublicKeyB64: bundle.identity.signingPublicKey.base64EncodedString(),
            agreementPublicKeyB64: bundle.identity.agreementPublicKey.base64EncodedString()
        )
        self.signedPreKey = .init(
            id: bundle.signedPreKey.id,
            publicKeyB64: bundle.signedPreKey.publicKey.base64EncodedString(),
            signatureB64: bundle.signedPreKey.signature.base64EncodedString(),
            createdAt: bundle.signedPreKey.createdAt
        )
        self.oneTimePreKeys = bundle.oneTimePreKeys.map {
            .init(id: $0.id, publicKeyB64: $0.publicKey.base64EncodedString(), createdAt: $0.createdAt)
        }
    }
}

extension RemotePreKeyBundleDTO {
    func toDomain() throws -> RemotePreKeyBundle {
        RemotePreKeyBundle(
            username: username,
            identitySigningPublicKey: try decode(identitySigningPublicKeyB64),
            identityAgreementPublicKey: try decode(identityAgreementPublicKeyB64),
            signedPreKeyId: signedPreKeyId,
            signedPreKeyPublicKey: try decode(signedPreKeyPublicKeyB64),
            signedPreKeySignature: try decode(signedPreKeySignatureB64),
            oneTimePreKeyId: oneTimePreKeyId,
            oneTimePreKeyPublicKey: try oneTimePreKeyPublicKeyB64.map(decode)
        )
    }

    private func decode(_ base64: String) throws -> Data {
        guard let data = Data(base64Encoded: base64) else { throw CryptoServiceError.malformedEnvelope }
        return data
    }
}
