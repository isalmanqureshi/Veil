//
//  RecoveryKeyGenerator.swift
//  Veil
//
//  Created by Salman Qureshi on 2/11/26.
//

import Foundation
import CryptoKit
import Security

enum RecoveryKeyError: Error {
    case invalidFormat
    case checksumMismatch
}

struct RecoveryKeyGenerator {

    // 32 bytes random seed + 4-byte checksum = 36 bytes
    static func generate() -> String {
        var seed = Data(count: 32)
        _ = seed.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!) }

        let checksum = checksum4(seed)
        let payload = seed + checksum

        let b32 = Base32.encode(payload) // no padding
        return group(b32, every: 4, separator: "-").lowercased()
    }

    static func decode(_ recoveryKey: String) throws -> Data {
        let cleaned = recoveryKey
            .lowercased()
            .replacingOccurrences(of: "-", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let payload = Base32.decode(cleaned), payload.count == 36 else {
            throw RecoveryKeyError.invalidFormat
        }

        let seed = payload.prefix(32)
        let checksum = payload.suffix(4)

        if checksum != checksum4(seed) {
            throw RecoveryKeyError.checksumMismatch
        }

        return Data(seed)
    }

    private static func checksum4(_ data: Data) -> Data {
        let digest = SHA256.hash(data: data)
        return Data(digest.prefix(4))
    }

    private static func group(_ s: String, every: Int, separator: String) -> String {
        var out: [String] = []
        out.reserveCapacity((s.count / every) + 1)
        var i = s.startIndex
        while i < s.endIndex {
            let j = s.index(i, offsetBy: every, limitedBy: s.endIndex) ?? s.endIndex
            out.append(String(s[i..<j]))
            i = j
        }
        return out.joined(separator: separator)
    }
}

// MARK: - Minimal Base32 (RFC4648 alphabet, no padding)

enum Base32 {
    private static let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
    private static let lookup: [Character: UInt8] = {
        var m: [Character: UInt8] = [:]
        for (i, c) in alphabet.enumerated() { m[c] = UInt8(i) }
        return m
    }()

    static func encode(_ data: Data) -> String {
        var output = ""
        output.reserveCapacity((data.count * 8 + 4) / 5)

        var buffer: UInt64 = 0
        var bitsLeft: Int = 0

        for byte in data {
            buffer = (buffer << 8) | UInt64(byte)
            bitsLeft += 8
            while bitsLeft >= 5 {
                let index = Int((buffer >> UInt64(bitsLeft - 5)) & 0x1F)
                output.append(alphabet[index])
                bitsLeft -= 5
            }
        }

        if bitsLeft > 0 {
            let index = Int((buffer << UInt64(5 - bitsLeft)) & 0x1F)
            output.append(alphabet[index])
        }

        return output
    }

    static func decode(_ string: String) -> Data? {
        var buffer: UInt64 = 0
        var bitsLeft: Int = 0
        var out = Data()
        out.reserveCapacity((string.count * 5) / 8)

        for ch in string.uppercased() {
            guard let val = lookup[ch] else { return nil }
            buffer = (buffer << 5) | UInt64(val)
            bitsLeft += 5
            if bitsLeft >= 8 {
                let byte = UInt8((buffer >> UInt64(bitsLeft - 8)) & 0xFF)
                out.append(byte)
                bitsLeft -= 8
            }
        }
        return out
    }
}
