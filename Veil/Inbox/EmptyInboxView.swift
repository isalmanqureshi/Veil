//
//  EmptyInboxView.swift
//  Veil
//
//  Created by Salman Qureshi on 2/5/26.
//

import SwiftUI

struct EmptyInboxView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var env: AppEnvironment
    
    var body: some View {
        VStack {
            
            Spacer()
            
            VStack(spacing: 16) {
                Text("No conversations yet")
                    .font(.system(size: 22, weight: .semibold))
                
                Button(action: {
                    // Start chat
                    coordinator.push(.startChat)
                }) {
                    Text("Start a Chat")
                        .font(.system(size: 17, weight: .semibold))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                }
                .background(Color.primary)
                .foregroundColor(Color(.systemBackground))
                .cornerRadius(12)
                
                Button(action: {
                    // Share username
                    coordinator.push(.status)
                }) {
                    Text("Share your username")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    // Settings action
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 17))
                }
            }
        }
    }
}

#Preview {
    EmptyInboxView()
}
