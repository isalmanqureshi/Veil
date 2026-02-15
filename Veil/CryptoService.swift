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
    private let outOfOrderWindow: UInt32 = 20
    private let skippedCapacity: Int = 20

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
        let blob = try decodePayload(ciphertext)
        let counter = parseCounter(blob)

        if counter < session.recvCount {
            return try decryptLateArrival(blob: blob, counter: counter, recipient: recipient, session: &session)
        }

        if counter == session.recvCount {
            return try decryptInOrder(blob: blob, counter: counter, recipient: recipient, session: &session)
        }

        let gap = counter - session.recvCount
        guard gap <= outOfOrderWindow else {
            throw CryptoServiceError.counterOutOfOrder
        }

        return try decryptWithinWindow(blob: blob, counter: counter, recipient: recipient, session: &session)
    }

    private func decodePayload(_ ciphertext: String) throws -> Data {
        guard let blob = Data(base64Encoded: ciphertext), blob.count > 5 else {
            throw CryptoServiceError.malformedEnvelope
        }

        guard blob[0] == payloadVersion else {
            throw CryptoServiceError.unsupportedVersion
        }

        return blob
    }

    private func parseCounter(_ blob: Data) -> UInt32 {
        let counterSlice = blob[1..<5]
        return counterSlice.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
    }

    private func decryptInOrder(
        blob: Data,
        counter: UInt32,
        recipient: String,
        session: inout SessionState
    ) throws -> String {
        guard session.receivingChainKey.count == 32 else {
            throw CryptoServiceError.invalidChainKey
        }

        let context = "veil.v1.recv.\(recipient)"
        let messageKeyData = ChainKDF.deriveMessageKey(
            chainKey: session.receivingChainKey,
            counter: counter,
            context: context
        )

        let plaintext = try openPayload(blob: blob, messageKeyData: messageKeyData)

        session.receivingChainKey = ChainKDF.advanceChainKey(
            chainKey: session.receivingChainKey,
            counter: counter,
            context: context
        )
        session.recvCount = counter &+ 1
        session.trimSkippedKeys(capacity: skippedCapacity)

        return plaintext
    }

    private func decryptWithinWindow(
        blob: Data,
        counter: UInt32,
        recipient: String,
        session: inout SessionState
    ) throws -> String {
        guard session.receivingChainKey.count == 32 else {
            throw CryptoServiceError.invalidChainKey
        }

        let context = "veil.v1.recv.\(recipient)"
        let start = session.recvCount
        var trialChainKey = session.receivingChainKey
        var stagedSkipped = session.skippedMessageKeys
        var targetMessageKey: Data?

        for i in start...counter {
            let msgKey = ChainKDF.deriveMessageKey(chainKey: trialChainKey, counter: i, context: context)
            let nextKey = ChainKDF.advanceChainKey(chainKey: trialChainKey, counter: i, context: context)

            if i == counter {
                targetMessageKey = msgKey
            } else {
                stagedSkipped.removeAll(where: { $0.counter == i })
                stagedSkipped.append(SkippedKey(counter: i, key: msgKey))
            }

            trialChainKey = nextKey
        }

        guard let targetMessageKey else {
            throw CryptoServiceError.invalidCiphertext
        }

        let plaintext = try openPayload(blob: blob, messageKeyData: targetMessageKey)

        session.receivingChainKey = trialChainKey
        session.recvCount = counter &+ 1
        session.skippedMessageKeys = stagedSkipped.sorted(by: { $0.counter < $1.counter })
        session.trimSkippedKeys(capacity: skippedCapacity)

        return plaintext
    }

    private func decryptLateArrival(
        blob: Data,
        counter: UInt32,
        recipient: String,
        session: inout SessionState
    ) throws -> String {
        _ = recipient
        guard let cached = session.skippedKey(for: counter) else {
            throw CryptoServiceError.counterOutOfOrder
        }

        let plaintext = try openPayload(blob: blob, messageKeyData: cached)
        session.removeSkippedKey(for: counter)
        session.trimSkippedKeys(capacity: skippedCapacity)
        return plaintext
    }

    private func openPayload(blob: Data, messageKeyData: Data) throws -> String {
        let combined = blob.subdata(in: 5..<blob.count)
        let box = try AES.GCM.SealedBox(combined: combined)
        let opened = try AES.GCM.open(box, using: SymmetricKey(data: messageKeyData))

        guard let plaintext = String(data: opened, encoding: .utf8) else {
            throw CryptoServiceError.invalidCiphertext
        }

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
