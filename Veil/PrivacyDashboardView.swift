//
//  PrivacyDashboardView.swift
//  Veil
//
//  Created by Salman Qureshi on 2/5/26.
//

import SwiftUI

struct PrivacyDashboardView: View {

    @EnvironmentObject private var auth: AuthStore

    var body: some View {
        List {

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
                Text("Last security check: Today")
                    .foregroundStyle(.secondary)
            }

            Section {
                Button(role: .destructive) {
                    auth.signOut()
                } label: {
                    Text("Sign Out")
                }
            }
        }
        .navigationTitle("Privacy")
    }
}


#Preview {
    let coordinator = AppCoordinator()
    let environment = AppEnvironment()

    return PrivacyDashboardView()
        .environmentObject(coordinator)
        .environmentObject(environment)
        .environmentObject(TrustCenter(coordinator: coordinator))
        .environmentObject(AuthStore(authRepo: environment.authRepo))
}
