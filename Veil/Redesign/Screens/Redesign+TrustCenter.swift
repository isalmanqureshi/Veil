//
//  Redesign+TrustCenter.swift
//  Veil
//
//  A quiet log of security events (existing TrustEvent type), grouped by
//  recency, with an "all clear" summary when nothing needs attention.
//

import SwiftUI

extension Redesign {

    struct TrustCenterView: View {
        let events: [TrustEvent]
        var onDismissEvent: (TrustEvent) -> Void = { _ in }

        private var hasCritical: Bool {
            events.contains { $0.severity == .critical }
        }

        private var todayEvents: [TrustEvent] {
            events.filter { Calendar.current.isDateInToday($0.timestamp) }
        }

        private var earlierEvents: [TrustEvent] {
            events.filter { !Calendar.current.isDateInToday($0.timestamp) }
        }

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                    summaryCard
                        .padding(.top, Theme.Spacing.s)

                    if events.isEmpty {
                        EmptyState(
                            symbolName: "checkmark.shield",
                            title: "Nothing to review",
                            message: "Security events for your account\nwill appear here."
                        )
                    } else {
                        if !todayEvents.isEmpty {
                            section("Today", events: todayEvents)
                        }
                        if !earlierEvents.isEmpty {
                            section("Earlier", events: earlierEvents)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.bottom, Theme.Spacing.l)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Trust Center")
            .navigationBarTitleDisplayMode(.large)
        }

        private var summaryCard: some View {
            HStack(spacing: Theme.Spacing.m) {
                Image(systemName: hasCritical ? "shield.lefthalf.filled" : "checkmark.shield.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(hasCritical ? Theme.Colors.trustWarning : Theme.Colors.trustInfo)

                VStack(alignment: .leading, spacing: 2) {
                    Text(hasCritical ? "Worth a look" : "Everything looks good")
                        .font(Theme.Fonts.headline)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text(hasCritical
                         ? "One or more events below could use your attention."
                         : "Your keys are healthy and your account is quiet.")
                        .font(Theme.Fonts.footnote)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .surfaceCard()
        }

        private func section(_ title: String, events: [TrustEvent]) -> some View {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text(title.uppercased())
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .padding(.leading, Theme.Spacing.xs)

                ForEach(events) { event in
                    TrustEventCard(event: event) {
                        onDismissEvent(event)
                    }
                }
            }
        }
    }
}

#Preview("Trust Center") {
    NavigationStack {
        Redesign.TrustCenterView(events: Redesign.Mock.trustEvents)
    }
}

#Preview("Trust Center · empty") {
    NavigationStack {
        Redesign.TrustCenterView(events: [])
    }
}
