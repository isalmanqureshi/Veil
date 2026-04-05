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
    @EnvironmentObject private var auth: AuthStore

    @State private var requiresPoW = false
    @State private var showSignOutConfirmation = false
    @State private var showEraseDeviceDataConfirmation = false

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
                comingSoonRow("Username")
                comingSoonRow("Linked devices")
                comingSoonRow("Personas")
            }

            Section("Visibility") {
                Toggle("Online status", isOn: .constant(false))
                Toggle("Read receipts", isOn: .constant(false))
                Toggle("Typing indicator", isOn: .constant(false))
            }

            Section("Data") {
                comingSoonRow("Message retention")
                Toggle("Backup", isOn: .constant(false))
                Toggle("Metadata protection", isOn: .constant(true))
            }

            Section("Security") {
                comingSoonRow("Key verification")
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

            Section("Account") {
                Button {
                    showSignOutConfirmation = true
                } label: {
                    Text("Sign Out")
                }

                Button(role: .destructive) {
                    showEraseDeviceDataConfirmation = true
                } label: {
                    Text("Remove Account From Device")
                }
            }
        }
        .confirmationDialog("Sign out of Veil?", isPresented: $showSignOutConfirmation, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                auth.signOut()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You’ll return to the welcome screen on this device.")
        }
        .confirmationDialog("Remove account from this device?", isPresented: $showEraseDeviceDataConfirmation, titleVisibility: .visible) {
            Button("Remove Account From Device", role: .destructive) {
                auth.eraseLocalData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will erase local messages, keys, and saved sign-in data from this device. This can’t be undone here.")
        }
        .navigationTitle("Privacy")
    }

    @ViewBuilder
    private func comingSoonRow(_ title: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("Coming soon")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}


#Preview {
    let environment = AppEnvironment()

    return PrivacyDashboardView()
        .environmentObject(AppCoordinator())
        .environmentObject(EntitlementsStore(purchaseProvider: MockPurchaseProvider()))
        .environmentObject(AuthStore(authRepo: environment.authRepo, identitySyncService: environment.identitySyncService, deviceIdentityStore: environment.deviceIdentityStore))
}
