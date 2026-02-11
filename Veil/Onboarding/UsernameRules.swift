//
//  UsernameRules.swift
//  Veil
//
//  Created by Codex on 2/11/26.
//

import Foundation

enum UsernameRules {
    static let minLength = 4
    static let maxLength = 24
    static let allowedPattern = "^[a-z0-9_]{4,24}$"

    static func normalize(_ username: String) -> String {
        username
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    static func sanitize(_ username: String) -> String {
        let normalized = normalize(username)
        let filtered = normalized.filter { char in
            char.isWholeNumber || (char >= "a" && char <= "z") || char == "_"
        }

        return String(filtered.prefix(maxLength))
    }

    static func isValid(_ username: String) -> Bool {
        let normalized = normalize(username)
        return normalized.range(of: allowedPattern, options: .regularExpression) != nil
    }
}
