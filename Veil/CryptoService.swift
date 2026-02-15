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
    case encodeFailure
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
