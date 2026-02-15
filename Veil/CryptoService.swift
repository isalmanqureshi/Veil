//
//  Untitled.swift
//  Veil
//
//  Created by Salman Qureshi on 2/10/26.
//
import Foundation
import CryptoKit

enum ChainKDF {
    /// Not full Double Ratchet yet; symmetric chain only.
    static func deriveMessageKey(chainKey: Data, counter: UInt32, context: String) -> Data {
        let mac = HMAC<SHA256>.authenticationCode(
            for: Data("msg".utf8) + counter.bigEndianData + Data(context.utf8),
            using: SymmetricKey(data: chainKey)
        )
        return Data(mac)
    }

    /// Not full Double Ratchet yet; symmetric chain only.
    static func advanceChainKey(chainKey: Data, counter: UInt32, context: String) -> Data {
        let mac = HMAC<SHA256>.authenticationCode(
            for: Data("ck".utf8) + counter.bigEndianData + Data(context.utf8),
            using: SymmetricKey(data: chainKey)
        )
        return Data(mac)
    }
}

protocol CryptoService {
    func encrypt(plaintext: String, for recipient: String, session: inout SessionState) throws -> String
    func decrypt(ciphertext: String, for recipient: String, session: inout SessionState) throws -> String
}

enum CryptoServiceError: Error {
    case invalidChainKey
    case malformedEnvelope
    case invalidCiphertext
    case unsupportedVersion
    case counterOutOfOrder
}

final class AuthenticatedCryptoService: CryptoService {

    private let payloadVersion: UInt8 = 1

    func encrypt(plaintext: String, for recipient: String, session: inout SessionState) throws -> String {
        guard session.sendingChainKey.count == 32 else {
            throw CryptoServiceError.invalidChainKey
        }

        let counter = session.sendCount
        let context = "veil.v1.send.\(recipient)"
        let messageKeyData = ChainKDF.deriveMessageKey(
            chainKey: session.sendingChainKey,
            counter: counter,
            context: context
        )

        let payload = Data(plaintext.utf8)
        let sealed = try AES.GCM.seal(payload, using: SymmetricKey(data: messageKeyData))
        guard let combined = sealed.combined else {
            throw CryptoServiceError.invalidCiphertext
        }

        var blob = Data([payloadVersion])
        blob.append(counter.bigEndianData)
        blob.append(combined)

        session.sendingChainKey = ChainKDF.advanceChainKey(
            chainKey: session.sendingChainKey,
            counter: counter,
            context: context
        )
        session.sendCount = counter &+ 1

        return blob.base64EncodedString()
    }

    func decrypt(ciphertext: String, for recipient: String, session: inout SessionState) throws -> String {
        guard let blob = Data(base64Encoded: ciphertext), blob.count > 5 else {
            throw CryptoServiceError.malformedEnvelope
        }

        let version = blob[0]
        guard version == payloadVersion else {
            throw CryptoServiceError.unsupportedVersion
        }

        let counterSlice = blob[1..<5]
        let counter = counterSlice.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }

        // MVP assumes in-order delivery.
        guard counter == session.recvCount else {
            throw CryptoServiceError.counterOutOfOrder
        }

        guard session.receivingChainKey.count == 32 else {
            throw CryptoServiceError.invalidChainKey
        }

        let context = "veil.v1.recv.\(recipient)"
        let messageKeyData = ChainKDF.deriveMessageKey(
            chainKey: session.receivingChainKey,
            counter: counter,
            context: context
        )

        let combined = blob.subdata(in: 5..<blob.count)
        let box = try AES.GCM.SealedBox(combined: combined)
        let opened = try AES.GCM.open(box, using: SymmetricKey(data: messageKeyData))

        guard let plaintext = String(data: opened, encoding: .utf8) else {
            throw CryptoServiceError.invalidCiphertext
        }

        session.receivingChainKey = ChainKDF.advanceChainKey(
            chainKey: session.receivingChainKey,
            counter: counter,
            context: context
        )
        session.recvCount = counter &+ 1

        return plaintext
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

private extension UInt32 {
    var bigEndianData: Data {
        withUnsafeBytes(of: self.bigEndian) { Data($0) }
    }
}
