//
//  GroupCreationView.swift
//  Veil
//
//  Created by Salman Qureshi on 2/5/26.
//

import SwiftUI

struct GroupCreationView: View {

    @State private var groupName = ""

    var body: some View {
        Form {

            Section {
                TextField("Group name", text: $groupName)
                NavigationLink("Members") {}
            }

            Section("Permissions") {
                Toggle("Post allowed", isOn: .constant(true))
                Toggle("DM allowed", isOn: .constant(true))
                Toggle("Anonymous members", isOn: .constant(false))
            }

            Section("Message policy") {
                Toggle("Ephemeral only", isOn: .constant(true))
                Toggle("Time-restricted", isOn: .constant(false))
            }
        }
        .navigationTitle("New Group")
    }
}


#Preview {
    GroupCreationView()
}
