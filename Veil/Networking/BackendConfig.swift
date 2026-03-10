import Foundation

struct BackendConfig {
    let baseURL: URL
    let timeout: TimeInterval
    let useMockBackend: Bool
    let pollIntervalSeconds: TimeInterval

    var useMock: Bool { useMockBackend }

    static let `default` = BackendConfig(
        baseURL: URL(string: "https://api.example.com")!,
        timeout: 15,
        useMockBackend: true,
        pollIntervalSeconds: 3
    )
}
