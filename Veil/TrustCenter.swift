//
//  TrustCenter.swift
//  Veil
//
//  Created by Salman Qureshi on 2/10/26.
//
import SwiftUI

enum TrustEventType: Hashable {
    case screenshotTaken
    case newDeviceDetected
    case identityKeyChanged
    case unverifiedContact
    case requestBlocked
    case requestReported
}

struct TrustEvent: Identifiable, Hashable {
    let id: UUID
    let type: TrustEventType
    let title: String
    let message: String
    let timestamp: Date
    let severity: Severity

    enum Severity {
        case info
        case warning
        case critical
    }
}


struct TrustState {
    var activeEvents: [TrustEvent] = []
    var eventLog: [TrustEvent] = []
    var lastReviewedAt: Date?
}


final class TrustCenter: ObservableObject {

    @Published private(set) var state = TrustState()

    private let coordinator: AppCoordinator

    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }

    // MARK: Public API

    func log(event: TrustEvent) {
        state.eventLog.append(event)
        state.activeEvents.append(event)
        routeIfNeeded(event)
    }

    func record(_ event: TrustEvent) {
        log(event: event)
    }

    func dismiss(_ event: TrustEvent) {
        state.activeEvents.removeAll { $0.id == event.id }
        state.lastReviewedAt = Date()
    }

    func hasCriticalIssues() -> Bool {
        state.activeEvents.contains { $0.severity == .critical }
    }

    func eventCount(for type: TrustEventType) -> Int {
        state.eventLog.filter { $0.type == type }.count
    }
}

private extension TrustCenter {

    func routeIfNeeded(_ event: TrustEvent) {
        guard event.severity != .info else { return }

        coordinator.push(
            .trustWarning(
                title: event.title,
                message: event.message
            )
        )
    }
}
