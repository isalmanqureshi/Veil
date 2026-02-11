//
//  UsernameCreationView.swift
//  Veil
//
//  Created by Salman Qureshi on 2/5/26.
//

import SwiftUI

struct UsernameCreationView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var env: AppEnvironment
    
    @State private var username: String = "lorem_ipsum_92"
    
    var isValid: Bool {
        env.identityRepo.validateUsername(username)
    }
    
    var body: some View {
        VStack {
            
            Spacer()
            // Card
            VStack(spacing: 20) {
                
                Text("Choose a username")
                    .font(.system(size: 20, weight: .semibold))
                
                // Username Field
                HStack {
                    TextField("", text: $username)
                        .font(.system(size: 16))
                        .padding()
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    
                    if !isValid {
                        Text("Use at least 4 characters. Letters, numbers, underscores only.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Button(action: {
                        generateUsername()
                    }) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                
                // Caption
                Text("This is how others find you. It’s not tied to your real identity.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(
                color: Color.black.opacity(0.06),
                radius: 12,
                x: 0,
                y: 4
            )
            .padding(.horizontal, 24)
            
            Spacer()
            
            // CTA
            Button(action: {
                // Continue action
                coordinator.push(.recoveryKey)
            }) {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .disabled(!isValid)
            .background(Color.primary)
            .foregroundColor(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
    
    private func generateUsername() {
        let adjectives = ["lorem", "quiet", "solid", "simple"]
        let nouns = ["ipsum", "field", "signal", "user"]
        
        let adjective = adjectives.randomElement() ?? "lorem"
        let noun = nouns.randomElement() ?? "ipsum"
        let number = Int.random(in: 10...99)
        
        username = "\(adjective)_\(noun)_\(number)"
    }
}

#Preview {
    UsernameCreationView()
}
