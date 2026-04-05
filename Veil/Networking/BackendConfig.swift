import Foundation

struct BackendConfig {
    let baseURL: URL
    let timeout: TimeInterval
    let useMockBackend: Bool
    let pollIntervalSeconds: TimeInterval
    let preKeyMaintenanceIntervalSeconds: TimeInterval
    let signedPreKeyMaxAgeDays: Int
    let oneTimePreKeyMinimumCount: Int
    let oneTimePreKeyTargetCount: Int

    var useMock: Bool { useMockBackend }

    static let `default` = BackendConfig(
        baseURL: URL(string: "https://api.example.com")!,
        timeout: 15,
        useMockBackend: true,
        pollIntervalSeconds: 3,
        preKeyMaintenanceIntervalSeconds: 300,
        signedPreKeyMaxAgeDays: 30,
        oneTimePreKeyMinimumCount: 20,
        oneTimePreKeyTargetCount: 50
    )
}
