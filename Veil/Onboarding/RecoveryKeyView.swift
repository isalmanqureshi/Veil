//
//  RecoveryKeyView.swift
//  Veil
//
//  Created by Salman Qureshi on 2/5/26.
//

import SwiftUI

struct RecoveryKeyView: View {
    
    @EnvironmentObject private var auth: AuthStore
       @EnvironmentObject private var coordinator: AppCoordinator
    
    private let recoveryKey =
    "lorem-ipsum-dolor-sit-amet-consectetur-adipiscing-elit"
    
    
    @State private var isBlurred = true
    @State private var isConfirmed = false
    
    var body: some View {
        VStack {
            
            Spacer()
            
            // Icon
            Image(systemName: "shield.fill")
                .font(.system(size: 40))
                .padding(.bottom, 20)
            
            // Title
            Text("Your Recovery Key")
                .font(.system(size: 24, weight: .semibold))
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)
            
            // Recovery Key Card
            VStack(spacing: 16) {
                
                Text(recoveryKey)
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .blur(radius: isBlurred ? 8 : 0)
                    .padding()
                
                Button(action: {
                    withAnimation {
                        isBlurred.toggle()
                    }
                }) {
                    Text(isBlurred ? "Show recovery key" : "Hide recovery key")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(14)
            .padding(.horizontal, 24)
            
            // Actions
            HStack(spacing: 24) {
                
                Button(action: copyKey) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.system(size: 14, weight: .medium))
                }
                
                Button(action: downloadKey) {
                    Label("Download", systemImage: "arrow.down.doc")
                        .font(.system(size: 14, weight: .medium))
                }
            }
            .foregroundStyle(.primary)
            .padding(.top, 16)
            
            // Acknowledgment
            CheckboxView(
                isChecked: $isConfirmed,
                label: "I understand that this key cannot be recovered if lost."
            )
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .contentShape(Rectangle())
            .accessibilityLabel("Recovery key acknowledgment")
            .accessibilityValue(isConfirmed ? "Checked" : "Unchecked")
            
            
            Spacer()
            
            // CTA
            Button(action: {
                // Finish setup action
                auth.finishOnboarding(username: auth.onboardingUsername)
                coordinator.path.removeAll()
            }) {
                Text("Finish setup")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .background(isConfirmed ? Color.primary : Color.secondary)
            .foregroundColor(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .disabled(!isConfirmed)
        }
    }
    
    private func copyKey() {
        UIPasteboard.general.string = recoveryKey
    }
    
    private func downloadKey() {
        // Export to file / share sheet
    }
}

#Preview {
    RecoveryKeyView()
}
