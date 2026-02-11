//
//  AppCoordinator.swift
//  Veil
//
//  Created by Salman Qureshi on 2/10/26.
//
import SwiftUI

// MARK: This removes view-to-view coupling.
protocol AppCoordinating {
    func push(_ route: AppRoute)
    func reset(to route: AppRoute)
}


final class AppCoordinator: ObservableObject, AppCoordinating {

    @Published var path: [AppRoute] = []

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func reset(to route: AppRoute) {
        path = [route]
    }
}

extension AppCoordinator {
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

