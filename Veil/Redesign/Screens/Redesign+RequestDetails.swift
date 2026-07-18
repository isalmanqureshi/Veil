//
//  Redesign+RequestDetails.swift
//  Veil
//
//  Full-screen view of one message request: who, calm trust context,
//  accept / ignore / block / report. The message stays sealed until accepted.
//

import SwiftUI

extension Redesign {

    struct RequestDetailsView: View {
        let request: MessageRequestThread

        var onAccept: () -> Void = {}
        var onIgnore: () -> Void = {}
        var onBlock: () -> Void = {}
        var onReport: (String) -> Void = { _ in }

        @State private var showBlockConfirm = false
        @State private var showReportDialog = false

        var body: some View {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: Theme.Spacing.l) {
                        // Who
                        VStack(spacing: Theme.Spacing.m) {
                            AvatarView(username: request.fromUsername, size: 88)
                            VStack(spacing: Theme.Spacing.xs) {
                                Text("@\(request.fromUsername)")
                                    .font(Theme.Fonts.title)
                                    .foregroundStyle(Theme.Colors.textPrimary)
                                Text("Wants to message you · \(Redesign.compactTimestamp(request.createdAt))")
                                    .font(Theme.Fonts.footnote)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }

                            let badges = SignalBadge.badges(for: request.signals)
                            if !badges.isEmpty {
                                HStack(spacing: Theme.Spacing.xs) {
                                    ForEach(Array(badges.enumerated()), id: \.offset) { _, badge in
                                        badge
                                    }
                                }
                            }

                            if let note = request.signals.confidenceNote {
                                Text(note)
                                    .font(Theme.Fonts.footnote)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                        }
                        .padding(.top, Theme.Spacing.l)

                        // Sealed message
                        VStack(spacing: Theme.Spacing.s) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 22, weight: .light))
                                .foregroundStyle(Theme.Colors.textSecondary)
                            Text("Their message is sealed")
                                .font(Theme.Fonts.headline)
                                .foregroundStyle(Theme.Colors.textPrimary)
                            Text("Veil can't read it, and neither can you — until you accept. They won't know you've seen this request.")
                                .font(Theme.Fonts.footnote)
                                .foregroundStyle(Theme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(Theme.Spacing.l)
                        .background(Theme.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                    }
                    .padding(.horizontal, Theme.Spacing.l)
                }

                // Actions — accept is primary; block/report present but quiet.
                VStack(spacing: Theme.Spacing.s) {
                    Button("Accept request", action: onAccept)
                        .buttonStyle(.veilPrimary)
                    Button("Ignore", action: onIgnore)
                        .buttonStyle(.veilQuiet)

                    HStack(spacing: Theme.Spacing.l) {
                        Button("Block") { showBlockConfirm = true }
                        Button("Report") { showReportDialog = true }
                    }
                    .font(Theme.Fonts.footnote)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .padding(.top, Theme.Spacing.xs)
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.bottom, Theme.Spacing.m)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Request")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog(
                "Block @\(request.fromUsername)?",
                isPresented: $showBlockConfirm,
                titleVisibility: .visible
            ) {
                Button("Block", role: .destructive, action: onBlock)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("They won't be able to send you requests again. They won't be notified.")
            }
            .confirmationDialog(
                "Report @\(request.fromUsername)?",
                isPresented: $showReportDialog,
                titleVisibility: .visible
            ) {
                Button("Spam") { onReport("spam") }
                Button("Harassment") { onReport("harassment") }
                Button("Something else") { onReport("other") }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Only the sealed envelope metadata is shared — never message content.")
            }
        }
    }
}

#Preview("Request details") {
    NavigationStack {
        Redesign.RequestDetailsView(request: Redesign.Mock.requests[1])
    }
}

#Preview("Request details · dark") {
    NavigationStack {
        Redesign.RequestDetailsView(request: Redesign.Mock.requests[2])
    }
    .preferredColorScheme(.dark)
}
