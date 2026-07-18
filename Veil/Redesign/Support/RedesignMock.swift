//
//  RedesignMock.swift
//  Veil
//
//  Preview/mock data for the redesign, bound to the app's real model types
//  (ChatMessage, ChatThread, MessageRequestThread, RequestSignals,
//  MessageTimer, TrustEvent). No networking, no crypto.
//

import Foundation
import SwiftUI

// MARK: - MessageTimer presentation helpers

extension MessageTimer {
    /// SF Symbol used wherever the disappearing timer is surfaced.
    var symbolName: String {
        switch self {
        case .seconds30: return "bolt"
        case .minutes5: return "timer"
        case .hour1: return "clock"
        case .day1: return "sun.horizon"
        case .custom: return "slider.horizontal.3"
        }
    }

    /// Calm one-line description for the selector.
    var explanation: String {
        switch self {
        case .seconds30: return "Gone almost immediately"
        case .minutes5: return "For quick, sensitive notes"
        case .hour1: return "The everyday default"
        case .day1: return "For slower conversations"
        case .custom: return "Pick your own window"
        }
    }
}

// MARK: - Shared formatting

extension Redesign {
    /// Compact inbox timestamp: time today, weekday this week, date otherwise.
    static func compactTimestamp(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return date.formatted(date: .omitted, time: .shortened)
        }
        if let days = calendar.dateComponents([.day], from: date, to: Date()).day, days < 7 {
            return date.formatted(.dateTime.weekday(.abbreviated))
        }
        return date.formatted(.dateTime.day().month(.abbreviated))
    }
}

// MARK: - Mock data

extension Redesign {
    enum Mock {

        static let localUsername = "salman"

        static let threads: [ChatThread] = [
            ChatThread(id: UUID(), username: "maya", lastPreview: "Dinner tonight?", lastAt: .now.addingTimeInterval(-540)),
            ChatThread(id: UUID(), username: "aiden", lastPreview: "On my way 🚕", lastAt: .now.addingTimeInterval(-2_400)),
            ChatThread(id: UUID(), username: "studio_ops", lastPreview: "Build finished successfully", lastAt: .now.addingTimeInterval(-16_000)),
            ChatThread(id: UUID(), username: "unknown_veil", lastPreview: "Hello!", lastAt: .now.addingTimeInterval(-90_000))
        ]

        static func messages(for username: String) -> [ChatMessage] {
            [
                ChatMessage(
                    id: UUID(), chatUsername: username, direction: .incoming,
                    ciphertext: "enc:9f2a…", plaintextPreview: "Hey! Are we still on for tonight?",
                    createdAt: .now.addingTimeInterval(-3_600), timer: .hour1, state: .sent
                ),
                ChatMessage(
                    id: UUID(), chatUsername: username, direction: .outgoing,
                    ciphertext: "enc:1b77…", plaintextPreview: "Yes — 7pm at the usual place.",
                    createdAt: .now.addingTimeInterval(-3_400), timer: .hour1, state: .sent
                ),
                ChatMessage(
                    id: UUID(), chatUsername: username, direction: .incoming,
                    ciphertext: "enc:44c0…", plaintextPreview: "Perfect. I'll grab a table by the window.",
                    createdAt: .now.addingTimeInterval(-3_300), timer: .hour1, state: .sent
                ),
                ChatMessage(
                    id: UUID(), chatUsername: username, direction: .outgoing,
                    ciphertext: "enc:a3d9…", plaintextPreview: "Bringing the documents too.",
                    createdAt: .now.addingTimeInterval(-120), timer: .minutes5, state: .sending
                ),
                ChatMessage(
                    id: UUID(), chatUsername: username, direction: .outgoing,
                    ciphertext: "enc:fail…", plaintextPreview: "And the photos from last week",
                    createdAt: .now.addingTimeInterval(-60), timer: .hour1, state: .failed
                )
            ]
        }

        static let requests: [MessageRequestThread] = [
            MessageRequestThread(
                id: UUID(), fromUsername: "new_friend", previewCiphertext: "enc:…",
                createdAt: .now.addingTimeInterval(-900),
                signals: RequestSignals(
                    pow: .verified(difficulty: 20), rateLimit: .none,
                    isFirstContact: true, confidenceNote: "First contact"
                )
            ),
            MessageRequestThread(
                id: UUID(), fromUsername: "unknown_veil", previewCiphertext: "enc:…",
                createdAt: .now.addingTimeInterval(-1_800),
                signals: RequestSignals(
                    pow: .verified(difficulty: 18), rateLimit: .light,
                    isFirstContact: true, confidenceNote: "New sender • Rate-limited"
                )
            ),
            MessageRequestThread(
                id: UUID(), fromUsername: "community_mod", previewCiphertext: "enc:…",
                createdAt: .now.addingTimeInterval(-3_000),
                signals: RequestSignals(
                    pow: .required(difficulty: 16), rateLimit: .heavy,
                    isFirstContact: false, confidenceNote: "Heavily rate-limited"
                )
            )
        ]

        static let trustEvents: [TrustEvent] = [
            TrustEvent(
                id: UUID(), type: .screenshotTaken,
                title: "Screenshot taken",
                message: "A screenshot was taken in your chat with @maya. Content may now exist outside Veil.",
                timestamp: .now.addingTimeInterval(-1_200), severity: .warning
            ),
            TrustEvent(
                id: UUID(), type: .newDeviceDetected,
                title: "New device signed in",
                message: "Your account was opened on a new device. If this was you, nothing to do.",
                timestamp: .now.addingTimeInterval(-86_000), severity: .warning
            ),
            TrustEvent(
                id: UUID(), type: .identityKeyChanged,
                title: "@aiden's safety number changed",
                message: "This usually means they reinstalled Veil. You can verify together when convenient.",
                timestamp: .now.addingTimeInterval(-170_000), severity: .info
            )
        ]

        static let recoveryKey = "k7pm-2xqf-9rwd-hz4t-y8vn-3cjs-6lbq-e5ga-w1uk"
    }
}
