//
//  Redesign+PrivacyDashboard.swift
//  Veil
//
//  What's encrypted vs. visible, protection toggles, and account exit paths
//  ("sign out" vs "remove account from this device" — clearly different).
//

import SwiftUI

extension Redesign {

    struct PrivacyDashboardView: View {
        @State private var screenshotAlertsOn = true
        var onSignOut: () -> Void = {}
        var onEraseDevice: () -> Void = {}

        @State private var showEraseConfirm = false

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.l) {

                    // Encrypted vs visible — honest, specific, calm.
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        sectionHeader("End-to-end encrypted")
                        VStack(spacing: 0) {
                            dataRow("Message content", symbol: "lock.fill", protected: true)
                            divider
                            dataRow("Attachments", symbol: "lock.fill", protected: true)
                            divider
                            dataRow("Disappearing-timer settings", symbol: "lock.fill", protected: true)
                        }
                        .background(Theme.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        sectionHeader("Visible for delivery")
                        VStack(spacing: 0) {
                            dataRow("Usernames (yours & theirs)", symbol: "at", protected: false)
                            divider
                            dataRow("Delivery timestamps", symbol: "clock", protected: false)
                            divider
                            dataRow("Device identifier", symbol: "iphone", protected: false)
                        }
                        .background(Theme.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))

                        Text("Only what's needed to route messages. Veil keeps this to a minimum by design.")
                            .font(Theme.Fonts.footnote)
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .padding(.horizontal, Theme.Spacing.xs)
                    }

                    // Protections
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        sectionHeader("Protections")
                        Toggle(isOn: $screenshotAlertsOn) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Screenshot alerts")
                                    .font(Theme.Fonts.callout)
                                    .foregroundStyle(Theme.Colors.textPrimary)
                                Text("Log a Trust Center event when a screenshot is taken.")
                                    .font(Theme.Fonts.footnote)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                        }
                        .tint(Theme.Colors.accent)
                        .padding(Theme.Spacing.m)
                        .background(Theme.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                    }

                    // Account exit paths — the difference matters, so spell it out.
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        sectionHeader("Account")

                        Button("Sign out", action: onSignOut)
                            .buttonStyle(.veilQuiet)
                        Text("Keeps your keys and messages on this device. Sign back in with your password.")
                            .font(Theme.Fonts.footnote)
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .padding(.horizontal, Theme.Spacing.xs)

                        Button("Remove account from this device") { showEraseConfirm = true }
                            .buttonStyle(.veilQuietCritical)
                        Text("Erases keys, messages, and identity from this phone. You'll need your recovery key to come back.")
                            .font(Theme.Fonts.footnote)
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .padding(.horizontal, Theme.Spacing.xs)
                    }
                }
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.vertical, Theme.Spacing.m)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.large)
            .confirmationDialog(
                "Remove account from this device?",
                isPresented: $showEraseConfirm,
                titleVisibility: .visible
            ) {
                Button("Remove everything", role: .destructive, action: onEraseDevice)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This can't be undone on this device. Your recovery key is the only way back in.")
            }
        }

        private func sectionHeader(_ title: String) -> some View {
            Text(title.uppercased())
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
                .padding(.leading, Theme.Spacing.xs)
        }

        private func dataRow(_ title: String, symbol: String, protected: Bool) -> some View {
            HStack(spacing: Theme.Spacing.m) {
                Image(systemName: symbol)
                    .font(.system(size: 15))
                    .foregroundStyle(protected ? Theme.Colors.trustInfo : Theme.Colors.textSecondary)
                    .frame(width: 24)
                Text(title)
                    .font(Theme.Fonts.callout)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Spacer()
                Text(protected ? "Encrypted" : "Visible")
                    .chip(tint: protected ? Theme.Colors.trustInfo : Theme.Colors.textSecondary)
            }
            .padding(Theme.Spacing.m)
            .accessibilityElement(children: .combine)
        }

        private var divider: some View {
            Divider().padding(.leading, 24 + Theme.Spacing.m * 2)
        }
    }
}

#Preview("Privacy dashboard") {
    NavigationStack {
        Redesign.PrivacyDashboardView()
    }
}

#Preview("Privacy dashboard · dark") {
    NavigationStack {
        Redesign.PrivacyDashboardView()
    }
    .preferredColorScheme(.dark)
}
