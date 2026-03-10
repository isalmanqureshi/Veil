import Foundation

protocol UsersService {
    func register(_ request: RegisterUserRequestDTO) async throws -> RegisterUserResponseDTO
    func lookup(username: String) async throws -> RegisterUserResponseDTO
}

protocol PreKeysService {
    func publish(_ request: PublishPreKeysRequestDTO) async throws -> PublishPreKeysResponseDTO
    func fetch(username: String) async throws -> RemotePreKeyBundleDTO
}

protocol MessagesService {
    func sendEnvelope(_ request: SendMessageRequestDTO) async throws -> SendMessageResponseDTO
    func pollInbox(username: String, deviceId: String) async throws -> InboxResponseDTO
    func ackMessages(_ request: AckMessagesRequestDTO) async throws -> AckMessagesResponseDTO
}

protocol RequestsService {
    func loadRequests(username: String) async throws -> RequestsListResponseDTO
    func accept(_ request: AcceptRequestRequestDTO) async throws -> AcceptRequestResponseDTO
    func ignore(_ request: IgnoreRequestRequestDTO) async throws -> IgnoreRequestResponseDTO
    func block(_ request: BlockRequestRequestDTO) async throws -> BlockRequestResponseDTO
    func report(_ request: ReportRequestRequestDTO) async throws -> ReportRequestResponseDTO
}

final class NetworkUsersService: UsersService {
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func register(_ request: RegisterUserRequestDTO) async throws -> RegisterUserResponseDTO {
        try await httpClient.post(path: "v1/users/register", body: request)
    }

    func lookup(username: String) async throws -> RegisterUserResponseDTO {
        try await httpClient.get(path: "v1/users/\(username)")
    }
}

final class NetworkPreKeysService: PreKeysService {
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func publish(_ request: PublishPreKeysRequestDTO) async throws -> PublishPreKeysResponseDTO {
        try await httpClient.post(path: "v1/prekeys/publish", body: request)
    }

    func fetch(username: String) async throws -> RemotePreKeyBundleDTO {
        try await httpClient.get(path: "v1/prekeys/\(username)")
    }
}

final class NetworkMessagesService: MessagesService {
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func sendEnvelope(_ request: SendMessageRequestDTO) async throws -> SendMessageResponseDTO {
        try await httpClient.post(path: "v1/messages/send", body: request)
    }

    func pollInbox(username: String, deviceId: String) async throws -> InboxResponseDTO {
        try await httpClient.get(path: "v1/messages/inbox", queryItems: [
            URLQueryItem(name: "username", value: username),
            URLQueryItem(name: "deviceId", value: deviceId)
        ])
    }

    func ackMessages(_ request: AckMessagesRequestDTO) async throws -> AckMessagesResponseDTO {
        try await httpClient.post(path: "v1/messages/ack", body: request)
    }
}

final class NetworkRequestsService: RequestsService {
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func loadRequests(username: String) async throws -> RequestsListResponseDTO {
        try await httpClient.get(path: "v1/requests", queryItems: [URLQueryItem(name: "username", value: username)])
    }

    func accept(_ request: AcceptRequestRequestDTO) async throws -> AcceptRequestResponseDTO {
        try await httpClient.post(path: "v1/requests/accept", body: request)
    }

    func ignore(_ request: IgnoreRequestRequestDTO) async throws -> IgnoreRequestResponseDTO {
        try await httpClient.post(path: "v1/requests/ignore", body: request)
    }

    func block(_ request: BlockRequestRequestDTO) async throws -> BlockRequestResponseDTO {
        try await httpClient.post(path: "v1/requests/block", body: request)
    }

    func report(_ request: ReportRequestRequestDTO) async throws -> ReportRequestResponseDTO {
        try await httpClient.post(path: "v1/requests/report", body: request)
    }
}
