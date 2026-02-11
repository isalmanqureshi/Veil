//
//  StatusView.swift
//  Veil
//
//  Created by Salman Qureshi on 2/5/26.
//

import SwiftUI

struct StatusView: View {

    var body: some View {
        List {

            Section {
                Button("Create Status") {}
                Text("My active status")
            }

            Section {
                Text("Visible to: 3 people")
                    .foregroundStyle(.secondary)
            }

            Section("Status Settings") {
                Toggle("Auto-expire (24h)", isOn: .constant(true))
                Toggle("Viewer anonymity", isOn: .constant(true))
                Toggle("Screenshot blocking", isOn: .constant(true))
            }
        }
        .navigationTitle("Status")
    }
}


#Preview {
    StatusView()
}
