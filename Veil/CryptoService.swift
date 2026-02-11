//
//  Untitled.swift
//  Veil
//
//  Created by Salman Qureshi on 2/10/26.
//
import SwiftUI

protocol CryptoService {
    func encrypt(plaintext: String, for recipient: String) -> String
}

// Local encryption stub (deterministic)
final class MockCryptoService: CryptoService {
    func encrypt(plaintext: String, for recipient: String) -> String {
        // Deterministic “ciphertext” for mock UI
        "enc(\(recipient)):\(plaintext.reversed())"
    }
}

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

