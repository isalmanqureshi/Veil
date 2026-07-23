//
//  MessageTimerSelectorView.swift
//  Veil
//
//  Created by Salman Qureshi on 2/5/26.
//

import SwiftUI

enum MessageTimer: String, Codable, CaseIterable, Identifiable {
    case seconds30 = "30 sec"
    case minutes5 = "5 min"
    case hour1 = "1 hr"
    case day1 = "1 day"
    case custom = "Custom"

    var id: String { rawValue }
}


struct MessageTimerSelectorView: View {

    @EnvironmentObject private var entitlements: EntitlementsStore
    @EnvironmentObject private var coordinator: AppCoordinator

    @Binding var selectedTimer: MessageTimer
    @Binding var makeDefault: Bool

    @State private var showProHint = false

    var body: some View {
        VStack(spacing: 20) {

            Text("Message timer")
                .font(.system(size: 18, weight: .semibold))

            ForEach(MessageTimer.allCases) { timer in
                Button {
                    if timer == .custom, !entitlements.isPro {
                        showProHint = true
                        return
                    }
                    selectedTimer = timer
                } label: {
                    HStack {
                        Text(timer.rawValue)
                        if timer == .custom && !entitlements.isPro {
                            Text("Pro")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color(.tertiarySystemBackground))
                                .clipShape(Capsule())
                        }
                        Spacer()
                        if selectedTimer == timer {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            }

            CheckboxView(
                isChecked: Binding(
                    get: { makeDefault },
                    set: { newValue in
                        if newValue, !entitlements.isPro {
                            showProHint = true
                            return
                        }
                        makeDefault = newValue
                    }
                ),
                label: entitlements.isPro ? "Make default for this chat" : "Make default for this chat (Pro)"
            )

            if showProHint && !entitlements.isPro {
                HStack {
                    Text("Requires Pro")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("View pricing") {
                        coordinator.push(.pricing)
                    }
                    .font(.system(size: 13, weight: .semibold))
                }
            }

            Spacer()
        }
        .padding(24)
        .presentationDetents([.medium])
    }
}


#Preview {
    MessageTimerSelectorPreviewContainer()
}

private struct MessageTimerSelectorPreviewContainer: View {

    @State private var timer: MessageTimer = .day1
    @State private var makeDefault = false

    var body: some View {
        MessageTimerSelectorView(
            selectedTimer: $timer,
            makeDefault: $makeDefault
        )
        .environmentObject(AppCoordinator())
        .environmentObject(EntitlementsStore(purchaseProvider: MockPurchaseProvider()))
    }
}
