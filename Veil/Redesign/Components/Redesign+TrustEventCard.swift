//
//  Redesign+TrustEventCard.swift
//  Veil
//
//  A quiet card for one TrustEvent (existing type). Severity is a small
//  tinted dot + icon, never a red banner.
//

import SwiftUI

extension Redesign {

    struct TrustEventCard: View {
        let event: TrustEvent
        var onDismiss: (() -> Void)? = nil

        var body: some View {
            HStack(alignment: .top, spacing: Theme.Spacing.m) {
                Image(systemName: symbolName)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(tint)
                    .frame(width: 36, height: 36)
                    .background(tint.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(event.title)
                            .font(Theme.Fonts.headline)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Spacer(minLength: Theme.Spacing.s)
                        Text(Redesign.compactTimestamp(event.timestamp))
                            .font(Theme.Fonts.footnote)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    Text(event.message)
                        .font(Theme.Fonts.callout)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let onDismiss {
                        Button("Got it", action: onDismiss)
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.Colors.accent)
                            .padding(.top, Theme.Spacing.xs)
                    }
                }
            }
            .surfaceCard()
            .accessibilityElement(children: .combine)
        }

        private var tint: Color {
            switch event.severity {
            case .info: return Theme.Colors.trustInfo
            case .warning: return Theme.Colors.trustWarning
            case .critical: return Theme.Colors.trustCritical
            }
        }

        private var symbolName: String {
            switch event.type {
            case .screenshotTaken: return "camera.viewfinder"
            case .newDeviceDetected: return "iphone.badge.plus"
            case .identityKeyChanged: return "key.horizontal"
            case .unverifiedContact: return "person.crop.circle.badge.questionmark"
            case .requestBlocked: return "hand.raised"
            case .requestReported: return "flag"
            }
        }
    }
}

#Preview("Trust cards") {
    ScrollView {
        VStack(spacing: Theme.Spacing.m) {
            ForEach(Redesign.Mock.trustEvents) { event in
                Redesign.TrustEventCard(event: event, onDismiss: event.severity == .warning ? {} : nil)
            }
        }
        .padding(Theme.Spacing.m)
    }
    .background(Theme.Colors.background)
}
