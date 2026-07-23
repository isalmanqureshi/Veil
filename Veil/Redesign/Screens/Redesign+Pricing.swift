//
//  Redesign+Pricing.swift
//  Veil
//
//  Free vs Pro. Honest framing: privacy is never paywalled — Pro buys
//  convenience and control, not safety.
//

import SwiftUI

extension Redesign {

    struct PricingView: View {
        var onSubscribe: () -> Void = {}
        var onRestore: () -> Void = {}

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.l) {

                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Veil Pro")
                            .font(Theme.Fonts.display)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text("Encryption is free for everyone, always. Pro adds finer control.")
                            .font(Theme.Fonts.callout)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    .padding(.top, Theme.Spacing.s)

                    // Free tier
                    planCard(
                        name: "Free",
                        price: "$0",
                        cadence: "forever",
                        highlighted: false,
                        features: [
                            "End-to-end encrypted messaging",
                            "Disappearing messages (30s – 1 day)",
                            "Message requests with abuse signals",
                            "Trust Center & screenshot alerts"
                        ]
                    )

                    // Pro tier
                    planCard(
                        name: "Pro",
                        price: "$2.99",
                        cadence: "per month",
                        highlighted: true,
                        features: [
                            "Everything in Free",
                            "Custom disappearing timers",
                            "Per-chat default timers",
                            "Priority attachment size limits"
                        ]
                    )

                    VStack(spacing: Theme.Spacing.s) {
                        Button("Upgrade to Pro", action: onSubscribe)
                            .buttonStyle(.veilPrimary)
                        Button("Restore purchases", action: onRestore)
                            .buttonStyle(.veilQuiet)
                        Text("Billed through the App Store. Cancel anytime. No purchase data is ever linked to your messages.")
                            .font(Theme.Fonts.footnote)
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.bottom, Theme.Spacing.l)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Pricing")
            .navigationBarTitleDisplayMode(.inline)
        }

        private func planCard(
            name: String,
            price: String,
            cadence: String,
            highlighted: Bool,
            features: [String]
        ) -> some View {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                HStack(alignment: .firstTextBaseline) {
                    Text(name)
                        .font(Theme.Fonts.title)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    if highlighted {
                        Text("Recommended").chip(tint: Theme.Colors.accent)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(price)
                            .font(Theme.Fonts.title)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text(cadence)
                            .font(Theme.Fonts.footnote)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    ForEach(features, id: \.self) { feature in
                        HStack(spacing: Theme.Spacing.s) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(highlighted ? Theme.Colors.accent : Theme.Colors.trustInfo)
                            Text(feature)
                                .font(Theme.Fonts.callout)
                                .foregroundStyle(Theme.Colors.textPrimary)
                        }
                    }
                }
            }
            .padding(Theme.Spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .strokeBorder(highlighted ? Theme.Colors.accent : Theme.Colors.separator,
                                  lineWidth: highlighted ? 2 : 1)
            )
            .shadow(color: Theme.Shadows.cardColor, radius: Theme.Shadows.cardRadius, y: Theme.Shadows.cardY)
        }
    }
}

#Preview("Pricing") {
    NavigationStack {
        Redesign.PricingView()
    }
}

#Preview("Pricing · dark") {
    NavigationStack {
        Redesign.PricingView()
    }
    .preferredColorScheme(.dark)
}
