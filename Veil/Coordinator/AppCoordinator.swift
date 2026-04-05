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
    func pop()
    func clear()
}


final class AppCoordinator: ObservableObject, AppCoordinating {

    @Published var path: [AppRoute] = []

    func push(_ route: AppRoute) {
        if path.last == route { return }
        path.append(route)
    }

    func reset(to route: AppRoute) {
        path = [route]
    }

    func clear() {
        path.removeAll()
    }
}

extension AppCoordinator {
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
