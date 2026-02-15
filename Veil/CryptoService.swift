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

enum CryptoServiceError: Error {
    case invalidChainKey
    case malformedEnvelope
    case invalidCiphertext
}

final class AuthenticatedCryptoService: CryptoService {

    func encrypt(plaintext: String, for recipient: String, session: SessionState) throws -> String {
        let key = try deriveMessageKey(for: recipient, session: session)
        let payload = Data(plaintext.utf8)
        let sealed = try AES.GCM.seal(payload, using: key)

        guard let combined = sealed.combined else {
            throw CryptoServiceError.invalidCiphertext
        }

        return combined.base64EncodedString()
    }

    func decrypt(ciphertext: String, for recipient: String, session: SessionState) throws -> String {
        guard let combined = Data(base64Encoded: ciphertext) else {
            throw CryptoServiceError.malformedEnvelope
        }

        let box = try AES.GCM.SealedBox(combined: combined)

        // Try receiving then sending key for local loopback/development readability.
        let candidateKeys = try candidateMessageKeys(for: recipient, session: session)
        for key in candidateKeys {
            if let opened = try? AES.GCM.open(box, using: key), let plaintext = String(data: opened, encoding: .utf8) {
                return plaintext
            }
        }

        throw CryptoServiceError.invalidCiphertext
    }

    private func deriveMessageKey(for recipient: String, session: SessionState) throws -> SymmetricKey {
        let seed = session.rootKey.count == 32 ? session.rootKey : session.sendingChainKey
        guard !seed.isEmpty else {
            throw CryptoServiceError.invalidChainKey
        }

        let baseKey = SymmetricKey(data: seed)
        return HKDF<SHA256>.deriveKey(
            inputKeyMaterial: baseKey,
            salt: Data("veil.msg.salt.v1".utf8),
            info: Data("veil.msg.\(recipient)".utf8),
            outputByteCount: 32
        )
    }

    private func candidateMessageKeys(for recipient: String, session: SessionState) throws -> [SymmetricKey] {
        var keys: [SymmetricKey] = []

        let senderSeed = session.rootKey.count == 32 ? session.rootKey : session.sendingChainKey
        if !senderSeed.isEmpty {
            keys.append(
                HKDF<SHA256>.deriveKey(
                    inputKeyMaterial: SymmetricKey(data: senderSeed),
                    salt: Data("veil.msg.salt.v1".utf8),
                    info: Data("veil.msg.\(recipient)".utf8),
                    outputByteCount: 32
                )
            )
        }

        if !session.receivingChainKey.isEmpty {
            keys.append(
                HKDF<SHA256>.deriveKey(
                    inputKeyMaterial: SymmetricKey(data: session.receivingChainKey),
                    salt: Data("veil.msg.salt.v1".utf8),
                    info: Data("veil.msg.\(recipient)".utf8),
                    outputByteCount: 32
                )
            )
        }

        return keys
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
