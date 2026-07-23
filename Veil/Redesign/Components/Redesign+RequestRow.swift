//
//  Redesign+RequestRow.swift
//  Veil
//
//  Message-request row + SignalBadge. Renders RequestSignals with quiet
//  confidence: soft tinted chips, no alarmist treatment, no raw telemetry.
//

import SwiftUI

extension Redesign {

    // MARK: - SignalBadge

    /// One calm capsule per signal. Language is descriptive, never scary.
    struct SignalBadge: View {
        let text: String
        let symbolName: String
        var tint: Color = Theme.Colors.trustInfo

        var body: some View {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: symbolName)
                    .font(.caption2)
                Text(text)
            }
            .chip(tint: tint)
            .accessibilityElement(children: .combine)
        }

        /// Maps RequestSignals to at most three quiet badges.
        static func badges(for signals: RequestSignals) -> [SignalBadge] {
            var result: [SignalBadge] = []

            if signals.isFirstContact {
                result.append(SignalBadge(text: "New contact", symbolName: "person.crop.circle.badge.plus"))
            }

            switch signals.pow {
            case .verified:
                result.append(SignalBadge(text: "Effort verified", symbolName: "checkmark.seal"))
            case .required:
                result.append(SignalBadge(text: "Effort required", symbolName: "seal", tint: Theme.Colors.textSecondary))
            case .none:
                break
            }

            switch signals.rateLimit {
            case .light:
                result.append(SignalBadge(text: "Rate limited", symbolName: "tortoise", tint: Theme.Colors.trustWarning))
            case .heavy, .throttled:
                result.append(SignalBadge(text: "Heavily limited", symbolName: "tortoise", tint: Theme.Colors.trustWarning))
            case .none:
                break
            }

            return result
        }
    }

    // MARK: - RequestRow

    struct RequestRow: View {
        let request: MessageRequestThread

        var body: some View {
            HStack(alignment: .top, spacing: Theme.Spacing.m) {
                AvatarView(username: request.fromUsername)

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    HStack {
                        Text("@\(request.fromUsername)")
                            .font(Theme.Fonts.headline)
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .lineLimit(1)
                        Spacer(minLength: Theme.Spacing.s)
                        Text(Redesign.compactTimestamp(request.createdAt))
                            .font(Theme.Fonts.footnote)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    // The message stays sealed until accepted — say so, gently.
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                        Text("Message hidden until you accept")
                            .font(Theme.Fonts.callout)
                    }
                    .foregroundStyle(Theme.Colors.textSecondary)

                    let badges = SignalBadge.badges(for: request.signals)
                    if !badges.isEmpty {
                        HStack(spacing: Theme.Spacing.xs) {
                            ForEach(Array(badges.enumerated()), id: \.offset) { _, badge in
                                badge
                            }
                        }
                        .padding(.top, Theme.Spacing.xs)
                    }
                }
            }
            .padding(.vertical, Theme.Spacing.s + 2)
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
        }
    }
}

#Preview("Request rows") {
    VStack(spacing: 0) {
        ForEach(Redesign.Mock.requests) { request in
            Redesign.RequestRow(request: request)
                .padding(.horizontal, Theme.Spacing.m)
            Divider().padding(.leading, 48 + Theme.Spacing.m * 2)
        }
    }
    .background(Theme.Colors.surface)
    .padding()
    .background(Theme.Colors.background)
}
