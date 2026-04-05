import Foundation

protocol IdentitySyncService {
    func sync(username: String, deviceId: String) async throws
}

struct NoopIdentitySyncService: IdentitySyncService {
    func sync(username: String, deviceId: String) async throws {}
}

enum IdentitySyncServiceError: LocalizedError {
    case usernameConflict

    var errorDescription: String? {
        switch self {
        case .usernameConflict:
            return "Username is already registered to another account."
        }
    }
}

final class NetworkIdentitySyncService: IdentitySyncService {
    private let usersService: UsersService
    private let preKeysService: PreKeysService
    private let keyManager: KeyManager

    init(usersService: UsersService, preKeysService: PreKeysService, keyManager: KeyManager = KeyManager()) {
        self.usersService = usersService
        self.preKeysService = preKeysService
        self.keyManager = keyManager
    }

    func sync(username: String, deviceId: String) async throws {
        let bundle = try keyManager.makePreKeyBundle(oneTimeCount: 20)
        let registerRequest = bundle.asRegisterDTO(username: username, deviceId: deviceId)

        do {
            _ = try await usersService.register(registerRequest)
        } catch let APIError.server(statusCode, message) where statusCode == 409 {
            let conflictMessage = message?.lowercased() ?? ""
            if conflictMessage.contains("taken") || conflictMessage.contains("conflict") {
                throw IdentitySyncServiceError.usernameConflict
            }
        }

        _ = try await preKeysService.publish(bundle.asPublishDTO(username: username, deviceId: deviceId))
    }
}
