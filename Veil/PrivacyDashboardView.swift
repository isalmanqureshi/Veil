//
//  PrivacyDashboardView.swift
//  Veil
//
//  Created by Salman Qureshi on 2/5/26.
//

import SwiftUI

struct PrivacyDashboardView: View {

    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var entitlements: EntitlementsStore

    @State private var requiresPoW = false

    var body: some View {
        List {

            Section("Veil Pro") {
                Button {
                    coordinator.push(.pricing)
                } label: {
                    HStack {
                        Text("Veil Pro")
                        Spacer()
                        if entitlements.isPro {
                            Text("Active")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            }

            Section("Identity") {
                NavigationLink("Username") {}
                NavigationLink("Linked devices") {}
                Text("Personas (Phase 2)")
                    .foregroundStyle(.secondary)
            }

            Section("Visibility") {
                Toggle("Online status", isOn: .constant(false))
                Toggle("Read receipts", isOn: .constant(false))
                Toggle("Typing indicator", isOn: .constant(false))
            }

            Section("Data") {
                NavigationLink("Message retention") {}
                Toggle("Backup", isOn: .constant(false))
                Toggle("Metadata protection", isOn: .constant(true))
            }

            Section("Security") {
                NavigationLink("Key verification") {}
                Toggle("Requests require PoW", isOn: Binding(
                    get: { requiresPoW },
                    set: { value in
                        if !entitlements.isPro && value {
                            coordinator.push(.pricing)
                            return
                        }
                        requiresPoW = value
                    }
                ))
                Text("Last security check: Today")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Privacy")
    }
}


#Preview {
    PrivacyDashboardView()
        .environmentObject(AppCoordinator())
        .environmentObject(EntitlementsStore(purchaseProvider: MockPurchaseProvider()))
}
