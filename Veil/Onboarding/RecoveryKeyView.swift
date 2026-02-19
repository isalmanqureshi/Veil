//
//  RecoveryKeyView.swift
//  Veil
//
//  Created by Salman Qureshi on 2/5/26.
//

import SwiftUI

struct RecoveryKeyView: View {

    @EnvironmentObject private var auth: AuthStore

    private var recoveryKey: String { auth.onboardingRecoveryKey }

    @State private var isBlurred = true
    @State private var isConfirmed = false
    @State private var showCopiedHint = false

    var body: some View {
        VStack {
            Spacer()

            Image(systemName: "shield.fill")
                .font(.system(size: 40))
                .padding(.bottom, 20)

            Text("Your Recovery Key")
                .font(.system(size: 24, weight: .semibold))
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)

            Text("Store this safely. If lost, your account cannot be recovered.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)

            VStack(spacing: 16) {
                if recoveryKey.isEmpty {
                    Text("Recovery key unavailable. Go back and try again.")
                        .font(.system(size: 14))
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    Text(recoveryKey)
                        .font(.system(size: 15, weight: .medium, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .blur(radius: isBlurred ? 8 : 0)
                        .textSelection(.enabled)
                        .padding()

                    Button {
                        withAnimation { isBlurred.toggle() }
                    } label: {
                        Text(isBlurred ? "Show recovery key" : "Hide recovery key")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
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
                .disabled(recoveryKey.isEmpty)

                ShareLink(item: recoveryKey) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .medium))
                }
                .disabled(recoveryKey.isEmpty)
            }
            .foregroundStyle(.primary)
            .padding(.top, 16)

            if showCopiedHint {
                Text("Recovery key copied.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                    .transition(.opacity)
            }

            CheckboxView(
                isChecked: $isConfirmed,
                label: "I understand that this key cannot be recovered if lost."
            )
            .padding(.horizontal, 24)
            .padding(.top, 24)

            if let errorMessage = auth.onboardingErrorMessage {
                Text(errorMessage)
                    .font(.system(size: 13))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
            }

            Spacer()

            Button {
                auth.finishOnboarding()
            } label: {
                Text("Finish setup")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .background((isConfirmed && !recoveryKey.isEmpty) ? Color.primary : Color.secondary)
            .foregroundColor(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .disabled(!isConfirmed || recoveryKey.isEmpty)
        }
        .onAppear {
            auth.prepareRecoveryKeyIfNeeded()
        }
    }

    private func copyKey() {
        guard !recoveryKey.isEmpty else { return }

        UIPasteboard.general.string = recoveryKey
        withAnimation {
            showCopiedHint = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showCopiedHint = false
            }
        }
    }
}

#Preview {
    let environment = AppEnvironment()
    let auth = AuthStore(authRepo: environment.authRepo)
    auth.startOnboarding()
    auth.onboardingUsername = "preview_user"
    auth.prepareRecoveryKeyIfNeeded()

    return RecoveryKeyView()
        .environmentObject(auth)
}
