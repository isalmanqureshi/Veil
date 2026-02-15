//
//  Untitled.swift
//  Veil
//
//  Created by Salman Qureshi on 2/10/26.
//
import Foundation
import CryptoKit

protocol CryptoService {
    func encrypt(plaintext: String, for recipient: String, session: SessionState) throws -> String
    func decrypt(ciphertext: String, for recipient: String, session: SessionState) throws -> String
}

struct EncryptedMessageEnvelope: Codable {
    let version: Int
    let recipient: String
    let nonce: String
    let ciphertext: String
    let tag: String
}

enum CryptoServiceError: Error {
    case invalidChainKey
    case malformedEnvelope
    case invalidCiphertext
}

final class AuthenticatedCryptoService: CryptoService {
    func encrypt(plaintext: String, for recipient: String, session: SessionState) throws -> String {
        guard session.sendingChainKey.count == 32 else {
            throw CryptoServiceError.invalidChainKey
        }

        let key = SymmetricKey(data: session.sendingChainKey)
        let nonce = AES.GCM.Nonce()
        let payload = Data(plaintext.utf8)
        let sealed = try AES.GCM.seal(payload, using: key, nonce: nonce)

        let envelope = EncryptedMessageEnvelope(
            version: 1,
            recipient: recipient,
            nonce: Data(nonce).base64EncodedString(),
            ciphertext: sealed.ciphertext.base64EncodedString(),
            tag: sealed.tag.base64EncodedString()
        )

        let encoded = try JSONEncoder().encode(envelope)
        return encoded.base64EncodedString()
    }

    func decrypt(ciphertext: String, for recipient: String, session: SessionState) throws -> String {
        guard let envelopeData = Data(base64Encoded: ciphertext) else {
            throw CryptoServiceError.malformedEnvelope
        }

        let envelope = try JSONDecoder().decode(EncryptedMessageEnvelope.self, from: envelopeData)
        guard envelope.recipient == recipient else {
            throw CryptoServiceError.invalidCiphertext
        }

        let nonceData = Data(base64Encoded: envelope.nonce)
        let encryptedData = Data(base64Encoded: envelope.ciphertext)
        let tagData = Data(base64Encoded: envelope.tag)
        guard let nonceData, let encryptedData, let tagData else {
            throw CryptoServiceError.malformedEnvelope
        }

        let nonce = try AES.GCM.Nonce(data: nonceData)
        let box = try AES.GCM.SealedBox(nonce: nonce, ciphertext: encryptedData, tag: tagData)

        // For mock UI we allow opening with either chain key, so sender and receiver previews can render.
        let candidateKeys = [session.receivingChainKey, session.sendingChainKey].filter { $0.count == 32 }
        for rawKey in candidateKeys {
            let key = SymmetricKey(data: rawKey)
            if let opened = try? AES.GCM.open(box, using: key), let plaintext = String(data: opened, encoding: .utf8) {
                return plaintext
            }
        }

        throw CryptoServiceError.invalidCiphertext
    }
}

typealias MockCryptoService = AuthenticatedCryptoService

protocol AttachmentService {
    var maxBytes: Int { get }
    func stripMetadata(_ attachment: AttachmentDraft) -> AttachmentDraft
    func encryptForUpload(_ attachment: AttachmentDraft, recipient: String) -> AttachmentDraft
    func upload(_ attachment: AttachmentDraft) async throws -> String // returns mock URL/id
}

enum AttachmentError: Error {
    case tooLarge
}

//Attachment pipeline stubs
final class MockAttachmentService: AttachmentService {
    let maxBytes: Int = 10 * 1024 * 1024 // 10MB configurable

    func stripMetadata(_ attachment: AttachmentDraft) -> AttachmentDraft {
        // Real implementation would strip EXIF for images/video
        attachment
    }

    func encryptForUpload(_ attachment: AttachmentDraft, recipient: String) -> AttachmentDraft {
        attachment
    }

    func upload(_ attachment: AttachmentDraft) async throws -> String {
        try await Task.sleep(nanoseconds: 250_000_000) // 250ms
        return "mock://upload/\(attachment.id.uuidString)"
    }
}
