//
//  IdentityVerificationView.swift
//  Veil
//
//  Created by Salman Qureshi on 2/5/26.
//

import SwiftUI

enum IdentityStatus {
    case unverified
    case verifying
    case verified
}

struct IdentityVerificationView: View {

    @State private var status: IdentityStatus = .unverified

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: status == .verified ? "checkmark.shield.fill" : "shield")

            Text(title)

            Button(action: verify) {
                Text(buttonTitle)
            }
        }
    }

    private var title: String {
        switch status {
        case .unverified: return "Identity not verified"
        case .verifying: return "Verifying…"
        case .verified: return "Identity verified"
        }
    }

    private var buttonTitle: String {
        status == .verified ? "Done" : "Verify now"
    }

    private func verify() {
        status = .verifying
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            status = .verified
        }
    }
}


#Preview {
    IdentityVerificationView()
}
