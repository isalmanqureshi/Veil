import CryptoKit
import Foundation
import Security

enum PasswordManagerError: Error {
    case invalidPassword
    case randomGenerationFailed
}

final class PasswordManager {
    private let keychain: KeychainStore
    private let service = "veil.credentials"
    private let saltAccount = "passwordSalt"
    private let verifierAccount = "passwordVerifier"

    private let iterations = 120_000
    private let saltLength = 16

    init(keychain: KeychainStore = KeychainStore()) {
        self.keychain = keychain
    }

    func setPassword(_ password: String) throws {
        let normalizedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedPassword.isEmpty else {
            throw PasswordManagerError.invalidPassword
        }

        let salt = try randomSalt()
        let verifier = deriveVerifier(for: normalizedPassword, salt: salt)

        try keychain.save(salt, service: service, account: saltAccount)
        try keychain.save(verifier, service: service, account: verifierAccount)
    }

    func verifyPassword(_ password: String) -> Bool {
        let normalizedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedPassword.isEmpty else { return false }

        guard
            let salt = try? keychain.load(service: service, account: saltAccount),
            let verifier = try? keychain.load(service: service, account: verifierAccount)
        else {
            return false
        }

        return deriveVerifier(for: normalizedPassword, salt: salt) == verifier
    }

    func clearPassword() {
        keychain.delete(service: service, account: saltAccount)
        keychain.delete(service: service, account: verifierAccount)
    }

    private func randomSalt() throws -> Data {
        var salt = Data(count: saltLength)
        let status = salt.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, saltLength, bytes.baseAddress!)
        }

        guard status == errSecSuccess else {
            throw PasswordManagerError.randomGenerationFailed
        }

        return salt
    }

    private func deriveVerifier(for password: String, salt: Data) -> Data {
        var digestInput = salt + Data(password.utf8)
        var digest = Data(SHA256.hash(data: digestInput))

        for _ in 1..<iterations {
            digestInput = digest + salt
            digest = Data(SHA256.hash(data: digestInput))
        }

        return digest
    }
}
