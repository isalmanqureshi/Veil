//
//  AppRouteView.swift
//  Veil
//
//  Created by Salman Qureshi on 2/5/26.
//

import SwiftUI

enum AppRoute: Hashable {
    case username
    case recoveryKey
    case inbox
    case startChat
    case chat(username: String)
    case status
    case privacy
    case groupCreation
    case trustWarning(title: String, message: String)
}

struct AppRootView: View {
    
    @StateObject private var coordinator = AppCoordinator()
    @StateObject private var environment = AppEnvironment()
    @StateObject private var trustCenter: TrustCenter
    
    init() {
        let coordinator = AppCoordinator()
        _coordinator = StateObject(wrappedValue: coordinator)
        _trustCenter = StateObject(wrappedValue: TrustCenter(coordinator: coordinator))
        _environment = StateObject(wrappedValue: AppEnvironment())
    }
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            WelcomeView()
                .navigationDestination(for: AppRoute.self) { route in
                    routeView(for: route)
                }
        }
        .environmentObject(coordinator)
        .environmentObject(environment)
        .environmentObject(trustCenter)
        .onAppear {
            ScreenshotDetector.start(trustCenter: trustCenter)
        }
    }
    
    @ViewBuilder
    private func routeView(for route: AppRoute) -> some View {
        switch route {
            
        case .username:
            UsernameCreationView()
            
        case .recoveryKey:
            RecoveryKeyView()
            
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
            
        case .groupCreation:
            GroupCreationView()
            
        case .trustWarning(let title, let message):
            TrustWarningView(title: title, message: message)
        }
    }
}

#Preview {
    AppRootView()
}
