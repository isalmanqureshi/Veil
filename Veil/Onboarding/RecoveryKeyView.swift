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

    private var recoveryKey: String { auth.onboardingRecoveryKey }

    @State private var isBlurred = true
    @State private var isConfirmed = false

    var body: some View {
        VStack {
            Spacer()

            Image(systemName: "shield.fill")
                .font(.system(size: 40))
                .padding(.bottom, 20)

            Text("Your Recovery Key")
                .font(.system(size: 24, weight: .semibold))
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)

            VStack(spacing: 16) {
                Text(recoveryKey)
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .blur(radius: isBlurred ? 8 : 0)
                    .padding()

                Button {
                    withAnimation { isBlurred.toggle() }
                } label: {
                    Text(isBlurred ? "Show recovery key" : "Hide recovery key")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(14)
            .padding(.horizontal, 24)

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

            CheckboxView(
                isChecked: $isConfirmed,
                label: "I understand that this key cannot be recovered if lost."
            )
            .padding(.horizontal, 24)
            .padding(.top, 24)

            Spacer()

            Button {
                auth.finishOnboarding()
                
                coordinator.path.removeAll()
            } label: {
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
        .onAppear {
            // Safety: if user navigated here directly, ensure key exists
            auth.prepareRecoveryKeyIfNeeded()
        }
    }

    private func copyKey() { UIPasteboard.general.string = recoveryKey }
    private func downloadKey() { /* share sheet later */ }
}


#Preview {
    RecoveryKeyView()
}
