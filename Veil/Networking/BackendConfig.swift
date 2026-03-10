import Foundation

struct BackendConfig {
    let baseURL: URL
    let timeout: TimeInterval
    let useMock: Bool

    static let `default` = BackendConfig(
        baseURL: URL(string: "https://api.example.com")!,
        timeout: 15,
        useMock: true
    )
}
