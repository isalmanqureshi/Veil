//
//  EmptyRequestsStateView.swift
//  Veil
//
//  Created by Salman Qureshi on 2/11/26.
//
import SwiftUI

struct EmptyRequestsState: View {
    var body: some View {
        VStack(spacing: 10) {
            Spacer()

            Text("No requests")
                .font(.system(size: 22, weight: .semibold))

            Text("New people land here until you accept.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }
}
