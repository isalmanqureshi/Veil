//
//  TrustWarningView.swift
//  Veil
//
//  Created by Salman Qureshi on 2/5/26.
//

import SwiftUI

struct TrustWarningView: View {
    
    let title: String
    let message: String
    
    @EnvironmentObject private var trustCenter: TrustCenter
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield")
                .font(.system(size: 32))
            
            Text(title)
                .font(.system(size: 18, weight: .semibold))
            
            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Got it") {
                // handled automatically via navigation back
            }
        }
        .padding(24)
    }
}


#Preview {
    TrustWarningView(title: "Shield", message: "This is to put trust")
}
