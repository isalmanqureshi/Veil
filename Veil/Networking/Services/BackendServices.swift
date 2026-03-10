import Foundation

protocol PreKeyService {
    func publishBundle(_ bundle: PreKeyBundle) async throws
    func fetchBundle(username: String) async throws -> RemotePreKeyBundle
}

protocol MessageService {
    func sendEnvelope(_ envelope: MessageEnvelopeDTO) async throws
    func pollInbox() async throws -> [MessageEnvelopeDTO]
}

protocol RequestsService {
    func load() async throws -> [MessageRequestDTO]
    func accept(id: UUID) async throws
    func ignore(id: UUID) async throws
    func block(id: UUID) async throws
    func report(id: UUID, reason: String) async throws
}

private struct EmptyBody: Encodable {}
private struct ReportBody: Encodable { let reason: String }

final class NetworkPreKeyService: PreKeyService {
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func publishBundle(_ bundle: PreKeyBundle) async throws {
        try await httpClient.send(path: "/v1/prekeys/publish", method: .post, body: PreKeyBundleDTO(bundle: bundle))
    }

    func fetchBundle(username: String) async throws -> RemotePreKeyBundle {
        let dto: RemotePreKeyBundleDTO = try await httpClient.request(
            path: "/v1/prekeys/\(username)",
            method: .get,
            body: Optional<EmptyBody>.none
        )
        return try dto.toDomain()
    }
}

final class NetworkMessageService: MessageService {
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func sendEnvelope(_ envelope: MessageEnvelopeDTO) async throws {
        try await httpClient.send(path: "/v1/messages/send", method: .post, body: envelope)
    }

    func pollInbox() async throws -> [MessageEnvelopeDTO] {
        try await httpClient.request(path: "/v1/messages/inbox", method: .get, body: Optional<EmptyBody>.none)
    }
}

final class NetworkRequestsService: RequestsService {
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func load() async throws -> [MessageRequestDTO] {
        try await httpClient.request(path: "/v1/requests", method: .get, body: Optional<EmptyBody>.none)
    }

    func accept(id: UUID) async throws {
        try await httpClient.send(path: "/v1/requests/\(id.uuidString)/accept", method: .post, body: EmptyBody())
    }

    func ignore(id: UUID) async throws {
        try await httpClient.send(path: "/v1/requests/\(id.uuidString)/ignore", method: .post, body: EmptyBody())
    }

    func block(id: UUID) async throws {
        try await httpClient.send(path: "/v1/requests/\(id.uuidString)/block", method: .post, body: EmptyBody())
    }

    func report(id: UUID, reason: String) async throws {
        try await httpClient.send(path: "/v1/requests/\(id.uuidString)/report", method: .post, body: ReportBody(reason: reason))
    }
}
