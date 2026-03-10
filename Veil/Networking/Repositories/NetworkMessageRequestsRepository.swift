import Foundation

final class NetworkMessageRequestsRepository: MessageRequestsRepository {
    private let service: RequestsService
    private let chatRepo: NetworkChatRepository

    private let lock = NSLock()
    private var cache: [MessageRequestThread] = []

    init(service: RequestsService, chatRepo: NetworkChatRepository) {
        self.service = service
        self.chatRepo = chatRepo
    }

    func loadRequests() -> [MessageRequestThread] {
        lock.withLock {
            cache.sorted(by: { $0.createdAt > $1.createdAt })
        }
    }

    func accept(requestId: UUID) -> String? {
        let username = lock.withLock { cache.first(where: { $0.id == requestId })?.fromUsername }

        Task {
            do {
                try await service.accept(id: requestId)
            } catch {
                // keep calm UX: retain local cache behavior
            }
        }

        lock.withLock {
            cache.removeAll { $0.id == requestId }
        }

        if let username {
            _ = chatRepo.loadMessages(chatUsername: username)
        }

        return username
    }

    func ignore(requestId: UUID) {
        Task {
            do {
                try await service.ignore(id: requestId)
            } catch {
                // keep calm UX: retain local cache behavior
            }
        }

        lock.withLock {
            cache.removeAll { $0.id == requestId }
        }
    }

    func block(requestId: UUID) {
        Task {
            do {
                try await service.block(id: requestId)
            } catch {
                // keep calm UX: retain local cache behavior
            }
        }

        lock.withLock {
            cache.removeAll { $0.id == requestId }
        }
    }

    func report(requestId: UUID, reason: String) {
        Task {
            do {
                try await service.report(id: requestId, reason: reason)
            } catch {
                // keep calm UX: retain local cache behavior
            }
        }

        lock.withLock {
            cache.removeAll { $0.id == requestId }
        }
    }

    func refresh() async {
        do {
            let remote = try await service.load().map {
                MessageRequestThread(
                    id: $0.id,
                    fromUsername: $0.fromUsername,
                    previewCiphertext: $0.previewCiphertext,
                    createdAt: $0.createdAt
                )
            }
            lock.withLock {
                cache = remote
            }
        } catch {
            // leave cache unchanged on transient failures
        }
    }
}
