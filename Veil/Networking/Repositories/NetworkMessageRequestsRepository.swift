import Foundation

final class NetworkMessageRequestsRepository: MessageRequestsRepository {
    private let service: RequestsService
    private let chatRepo: NetworkChatRepository
    private let authContext: LocalAuthContext

    private let lock = NSLock()
    private var cache: [MessageRequestThread] = []

    init(service: RequestsService, chatRepo: NetworkChatRepository, authContext: LocalAuthContext = LocalAuthContext()) {
        self.service = service
        self.chatRepo = chatRepo
        self.authContext = authContext
    }

    func loadRequests() -> [MessageRequestThread] {
        lock.withLock { cache.sorted(by: { $0.createdAt > $1.createdAt }) }
    }

    func accept(requestId: UUID) -> String? {
        guard let username = authContext.currentUsername() else { return nil }
        let fromUsername = lock.withLock { cache.first(where: { $0.id == requestId })?.fromUsername }

        Task {
            _ = try? await service.accept(.init(requestId: requestId, username: username))
        }

        lock.withLock { cache.removeAll { $0.id == requestId } }
        if let fromUsername { chatRepo.ensureChatExists(username: fromUsername) }
        return fromUsername
    }

    func ignore(requestId: UUID) {
        guard let username = authContext.currentUsername() else { return }
        Task {
            _ = try? await service.ignore(.init(requestId: requestId, username: username))
        }
        lock.withLock { cache.removeAll { $0.id == requestId } }
    }

    func block(requestId: UUID) {
        guard let username = authContext.currentUsername() else { return }
        Task {
            _ = try? await service.block(.init(requestId: requestId, username: username))
        }
        lock.withLock { cache.removeAll { $0.id == requestId } }
    }

    func report(requestId: UUID, reason: String) {
        guard let username = authContext.currentUsername() else { return }
        Task {
            _ = try? await service.report(.init(requestId: requestId, username: username, reason: reason))
        }
        lock.withLock { cache.removeAll { $0.id == requestId } }
    }

    func refresh() async {
        guard let username = authContext.currentUsername() else { return }

        do {
            let response = try await service.loadRequests(username: username)
            let mapped = response.requests.map { dto in
                MessageRequestThread(
                    id: dto.id,
                    fromUsername: dto.fromUsername,
                    previewCiphertext: dto.previewCiphertext,
                    createdAt: dto.createdAt,
                    signals: RequestSignals(
                        pow: .none,
                        rateLimit: .none,
                        isFirstContact: dto.signals?.isFirstContact ?? true,
                        confidenceNote: dto.signals?.confidenceNote
                    )
                )
            }
            lock.withLock { cache = mapped }
        } catch {
            // keep cache on failure
        }
    }
}
