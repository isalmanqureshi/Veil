//
//  PrivacyDashboardView.swift
//  Veil
//
//  Created by Salman Qureshi on 2/5/26.
//

import SwiftUI

struct PrivacyDashboardView: View {

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
        }
        .navigationTitle("Privacy")
    }
}


#Preview {
    PrivacyDashboardView()
}
