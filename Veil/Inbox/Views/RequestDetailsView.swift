//
//  RequestDetailsView.swift
//  Veil
//
//  Created by Salman Qureshi on 2/11/26.
//

import SwiftUI

struct RequestDetailsView: View {

    @EnvironmentObject private var coordinator: AppCoordinator

    let requestId: UUID
    private let chatRepo: ChatRepository
    private let requestsRepo: MessageRequestsRepository

    @State private var request: MessageRequestThread?
    @State private var showReportSheet = false

    init(requestId: UUID, chatRepo: ChatRepository, requestsRepo: MessageRequestsRepository) {
        self.requestId = requestId
        self.chatRepo = chatRepo
        self.requestsRepo = requestsRepo
    }

    var body: some View {
        Group {
            if let req = request {
                content(req)
            } else {
                ContentUnavailableView("Request not found", systemImage: "questionmark.circle")
            }
        }
        .navigationTitle("Request")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { reload() }
        .sheet(isPresented: $showReportSheet) {
            ReportSheet(
                onCancel: { showReportSheet = false },
                onSubmit: { reason in
                    requestsRepo.report(requestId: requestId, reason: reason)
                    showReportSheet = false
                    request = nil

                    coordinator.push(.trustWarning(
                        title: "Report received",
                        message: "Thanks. This request was removed and will help improve protections."
                    ))
                    // ✅ Don’t pop here
                }
            )
        }
    }

    private func reload() {
        request = requestsRepo.loadRequests().first(where: { $0.id == requestId })
    }

    private func acceptTitle(for req: MessageRequestThread) -> String {
        RequestSignalsFormatter.acceptTitle(req.signals)
    }

    private func content(_ req: MessageRequestThread) -> some View {
        VStack(spacing: 16) {

            HStack(spacing: 12) {
                AvatarCircle(text: String(req.fromUsername.prefix(1)))

                VStack(alignment: .leading, spacing: 4) {
                    Text(req.fromUsername)
                        .font(.system(size: 20, weight: .semibold))

                    Text("New request • Not in your chats")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)

                    if let line = RequestSignalsFormatter.primaryLine(req.signals) {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.secondary)

                            Text(line)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 2)
                    }
                }

                Spacer()
            }
            .padding(.top, 8)

            VStack(alignment: .leading, spacing: 8) {
                Text("Preview")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text(req.previewCiphertext)
                    .font(.system(size: 15, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            VStack(spacing: 12) {

                Button {
                    let username = requestsRepo.accept(requestId: req.id)
                    request = nil
                    coordinator.push(.chat(username: username))
                } label: {
                    Text(acceptTitle(for: req))
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .background(Color.primary)
                .foregroundColor(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                HStack(spacing: 12) {
                    Button {
                        requestsRepo.ignore(requestId: req.id)
                        request = nil
                        coordinator.pop()
                    } label: {
                        Text("Ignore")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Button {
                        requestsRepo.block(requestId: req.id)
                        request = nil
                        coordinator.push(.trustWarning(
                            title: "Blocked",
                            message: "This sender can’t request messages from you."
                        ))
                        // ✅ Don’t pop immediately; let user read it
                    } label: {
                        Text("Block")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Button {
                    showReportSheet = true
                } label: {
                    Text("Report")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(16)
    }
}


private struct ReportSheet: View {

    let onCancel: () -> Void
    let onSubmit: (String) -> Void

    @State private var reason: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Tell us what happened")
                    .font(.system(size: 20, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("Reason (optional)", text: $reason, axis: .vertical)
                    .lineLimit(3...6)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Text("Reports are used to improve protections. No panic language, just signal.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }
            .padding(16)
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Submit") { onSubmit(reason.trimmingCharacters(in: .whitespacesAndNewlines)) }
                }
            }
        }
    }
}


enum RequestSignalsFormatter {

    static func primaryLine(_ s: RequestSignals) -> String? {
        var parts: [String] = []

        // PoW
        switch s.pow {
        case .none:
            break
        case .verified(let difficulty):
            parts.append("PoW verified (\(difficulty))")
        case .required(let difficulty):
            parts.append("PoW required (\(difficulty))")
        }

        // Rate limit
        switch s.rateLimit {
        case .none:
            break
        case .light:
            parts.append("Rate-limited")
        case .heavy:
            parts.append("Heavily rate-limited")
        case .throttled(let until):
            // Keep it calm & vague, avoid precise timestamps if you want metadata minimization
            parts.append("Temporarily throttled")
            _ = until
        }

        // Optional short note overrides if you prefer
        if let note = s.confidenceNote, !note.isEmpty {
            return note
        }

        return parts.isEmpty ? nil : parts.joined(separator: " • ")
    }
}

extension RequestSignalsFormatter {
    static func acceptTitle(_ s: RequestSignals) -> String {
        if case .throttled = s.rateLimit { return "Accept (may be delayed)" }
        return "Accept"
    }
}

