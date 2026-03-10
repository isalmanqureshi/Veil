import Foundation

struct RegisterUserRequestDTO: Codable {
    let username: String
    let deviceId: String
    let identitySigningPublicKeyB64: String
    let identityAgreementPublicKeyB64: String
    let signedPreKeyId: UInt32
    let signedPreKeyPublicKeyB64: String
    let signedPreKeySignatureB64: String
    let oneTimePreKeys: [OneTimePreKeyDTO]
}

struct RegisterUserResponseDTO: Codable {
    let username: String
    let registered: Bool
}

struct OneTimePreKeyDTO: Codable {
    let id: UInt32
    let publicKeyB64: String
}

struct PublishPreKeysRequestDTO: Codable {
    let username: String
    let deviceId: String
    let signedPreKeyId: UInt32
    let signedPreKeyPublicKeyB64: String
    let signedPreKeySignatureB64: String
    let oneTimePreKeys: [OneTimePreKeyDTO]
}

struct PublishPreKeysResponseDTO: Codable {
    let published: Bool
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

struct SendMessageRequestDTO: Codable {
    let fromUsername: String
    let toUsername: String
    let deviceId: String
    let payloadB64: String
    let envelopeVersion: Int
    let oneTimePreKeyId: UInt32?
    let timer: String?
    let clientMessageId: String
}

struct SendMessageResponseDTO: Codable {
    let accepted: Bool
    let serverMessageId: String
}

struct InboxEnvelopeDTO: Codable {
    let serverMessageId: String
    let fromUsername: String
    let toUsername: String
    let deviceId: String
    let payloadB64: String
    let envelopeVersion: Int
    let queuedAt: Date
    let timer: String?
}

struct InboxResponseDTO: Codable {
    let messages: [InboxEnvelopeDTO]
}

struct AckMessagesRequestDTO: Codable {
    let username: String
    let deviceId: String
    let messageIds: [String]
}

struct AckMessagesResponseDTO: Codable {
    let ackedCount: Int
}

struct MessageRequestDTO: Codable {
    let id: UUID
    let fromUsername: String
    let previewCiphertext: String
    let createdAt: Date
    let signals: RequestSignalsDTO?
}

struct RequestSignalsDTO: Codable {
    let isFirstContact: Bool?
    let confidenceNote: String?
}

struct RequestsListResponseDTO: Codable {
    let requests: [MessageRequestDTO]
}

struct AcceptRequestRequestDTO: Codable {
    let requestId: UUID
    let username: String
}

struct AcceptRequestResponseDTO: Codable {
    let fromUsername: String
}

struct IgnoreRequestRequestDTO: Codable {
    let requestId: UUID
    let username: String
}

struct IgnoreRequestResponseDTO: Codable {
    let ignored: Bool
}

struct BlockRequestRequestDTO: Codable {
    let requestId: UUID
    let username: String
}

struct BlockRequestResponseDTO: Codable {
    let blocked: Bool
}

struct ReportRequestRequestDTO: Codable {
    let requestId: UUID
    let username: String
    let reason: String
}

struct ReportRequestResponseDTO: Codable {
    let reported: Bool
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

extension PreKeyBundle {
    func asRegisterDTO(username: String, deviceId: String) -> RegisterUserRequestDTO {
        RegisterUserRequestDTO(
            username: username,
            deviceId: deviceId,
            identitySigningPublicKeyB64: identity.signingPublicKey.base64EncodedString(),
            identityAgreementPublicKeyB64: identity.agreementPublicKey.base64EncodedString(),
            signedPreKeyId: signedPreKey.id,
            signedPreKeyPublicKeyB64: signedPreKey.publicKey.base64EncodedString(),
            signedPreKeySignatureB64: signedPreKey.signature.base64EncodedString(),
            oneTimePreKeys: oneTimePreKeys.map { .init(id: $0.id, publicKeyB64: $0.publicKey.base64EncodedString()) }
        )
    }

    func asPublishDTO(username: String, deviceId: String) -> PublishPreKeysRequestDTO {
        PublishPreKeysRequestDTO(
            username: username,
            deviceId: deviceId,
            signedPreKeyId: signedPreKey.id,
            signedPreKeyPublicKeyB64: signedPreKey.publicKey.base64EncodedString(),
            signedPreKeySignatureB64: signedPreKey.signature.base64EncodedString(),
            oneTimePreKeys: oneTimePreKeys.map { .init(id: $0.id, publicKeyB64: $0.publicKey.base64EncodedString()) }
        )
    }
}
