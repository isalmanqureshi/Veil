//
//  StartChatView.swift
//  Veil
//
//  Created by Salman Qureshi on 2/5/26.
//

import SwiftUI

struct StartChatView: View {
    
    @State private var username = ""
    @State private var showAdvanced = false
    @State private var verifyIdentity = false
    
    @EnvironmentObject private var coordinator: AppCoordinator

    private var normalizedUsername: String {
        UsernameRules.normalize(username)
    }

    private var canStartChat: Bool {
        UsernameRules.isValid(normalizedUsername)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            
            // Username input
            VStack(alignment: .leading, spacing: 8) {
                Text("Enter username")
                    .font(.system(size: 15, weight: .medium))
                
                TextField("username", text: $username)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
            }
            
            // Options
            VStack(spacing: 16) {
                OptionRow(title: "Scan QR", icon: "qrcode.viewfinder")
                OptionRow(title: "Paste invite link", icon: "link")
            }
            
            // Advanced
            Toggle("Advanced", isOn: $showAdvanced)
                .font(.system(size: 15))
                .padding(.top, 8)
            
            if showAdvanced {
                CheckboxView(
                    isChecked: $verifyIdentity,
                    label: "Verify identity now (optional)"
                )
            }
            
            Spacer()
            
            // CTA
            Button {
                guard canStartChat else { return }
                coordinator.push(.chat(username: normalizedUsername))
            } label: {
                Text("Start Chat")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .background(canStartChat ? Color.primary : Color.secondary)
            .foregroundColor(Color(.systemBackground))
            .cornerRadius(12)
            .disabled(!canStartChat)
        }
        .padding(24)
        .navigationTitle("Start Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: username) { newValue in
            let sanitized = UsernameRules.sanitize(newValue)
            if sanitized != newValue {
                username = sanitized
            }
        }
    }
}

struct OptionRow: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}


#Preview {
    StartChatView()
        .environmentObject(AppCoordinator())
}
