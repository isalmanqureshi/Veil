//
//  AppRouteView.swift
//  Veil
//
//  Created by Salman Qureshi on 2/5/26.
//

import SwiftUI

enum AppRoute: Hashable {
    case login
    case username
    case passwordCreation
    case recoveryKey
    case recoveryLogin
    case resetPassword
    case inbox
    case startChat
    case chat(username: String)
    case status
    case privacy
    case pricing
    case groupCreation
    case requestDetails(id: UUID)
    case trustWarning(title: String, message: String)
}

struct AppRootView: View {

    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var coordinator: AppCoordinator
    @StateObject private var environment: AppEnvironment
    @StateObject private var trustCenter: TrustCenter
    @StateObject private var auth: AuthStore

    init() {
        let coordinator = AppCoordinator()
        let trustCenter = TrustCenter(coordinator: coordinator)

        _coordinator = StateObject(wrappedValue: coordinator)
        _trustCenter = StateObject(wrappedValue: trustCenter)
        
        let environment = AppEnvironment()
        _auth = StateObject(wrappedValue: AuthStore(authRepo: environment.authRepo, identitySyncService: environment.identitySyncService, deviceIdentityStore: environment.deviceIdentityStore))
        _environment = StateObject(wrappedValue: environment)
    }

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            rootScreen
                .navigationDestination(for: AppRoute.self) { route in
                    routeView(for: route)
                }
        }
        .environmentObject(coordinator)
        .environmentObject(environment)
        .environmentObject(trustCenter)
        .environmentObject(auth)
        .environmentObject(environment.entitlements)
        .onAppear {
            ScreenshotDetector.start(trustCenter: trustCenter)
            environment.setAppActive(true)
            environment.setSignedIn(isSignedInState(auth.state))
        }
        .onChange(of: auth.state) { _, newState in
            switch newState {
            case .signedOut, .signedIn, .requiresPasswordReset:
                coordinator.clear()
            case .onboarding:
                break
            }

            environment.setSignedIn(isSignedInState(newState))
        }

        .onChange(of: auth.backendSyncState) { _, newState in
            guard isSignedInState(auth.state) else { return }
            if case .synced = newState {
                environment.syncPreKeysIfNeeded()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            environment.setAppActive(newPhase == .active)
        }
    }


    private func isSignedInState(_ state: AuthState) -> Bool {
        if case .signedIn = state { return true }
        return false
    }

    @ViewBuilder
    private var rootScreen: some View {
        switch auth.state {
        case .signedOut:
            WelcomeView()

        case .onboarding:
            UsernameCreationView()

        case .requiresPasswordReset:
            ResetPasswordView()

        case .signedIn:
            InboxView(chatRepo: environment.chatRepo, requestsRepo: environment.requestsRepo)
        }
    }

    @ViewBuilder
    private func routeView(for route: AppRoute) -> some View {
        switch route {

        case .login:
            LoginView()

        case .username:
            UsernameCreationView()

        case .passwordCreation:
            PasswordCreationView()

        case .recoveryKey:
            RecoveryKeyView()

        case .recoveryLogin:
            RecoveryLoginView()

        case .resetPassword:
            ResetPasswordView()

        case .inbox:
            InboxView(chatRepo: environment.chatRepo, requestsRepo: environment.requestsRepo)

        case .startChat:
            StartChatView()

        case .chat(let username):
            ChatView(username: username, repo: environment.chatRepo)

        case .status:
            StatusView()

        case .privacy:
            PrivacyDashboardView()

        case .pricing:
            PricingView()

        case .groupCreation:
            GroupCreationView()
            
        case .requestDetails(let id):
            RequestDetailsView(requestId: id, requestsRepo: environment.requestsRepo)

        case .trustWarning(let title, let message):
            TrustWarningView(title: title, message: message)
        }
    }
}

#Preview {
    AppRootView()
}
