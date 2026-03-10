import Foundation

final class MessagePoller {
    private let messageService: MessageService
    private let chatRepository: NetworkChatRepository
    private let requestsRepository: NetworkMessageRequestsRepository
    private let intervalNanoseconds: UInt64

    private let lock = NSLock()
    private var task: Task<Void, Never>?

    init(
        messageService: MessageService,
        chatRepository: NetworkChatRepository,
        requestsRepository: NetworkMessageRequestsRepository,
        intervalSeconds: TimeInterval = 3
    ) {
        self.messageService = messageService
        self.chatRepository = chatRepository
        self.requestsRepository = requestsRepository
        self.intervalNanoseconds = UInt64(max(intervalSeconds, 2) * 1_000_000_000)
    }

    func start() {
        lock.withLock {
            guard task == nil else { return }
            task = Task { [messageService, chatRepository, requestsRepository, intervalNanoseconds] in
                while !Task.isCancelled {
                    do {
                        async let inbox = messageService.pollInbox()
                        async let requests = requestsRepository.refresh()
                        let envelopes = try await inbox
                        _ = await requests
                        chatRepository.ingestIncoming(envelopes)
                    } catch {
                        // swallow errors for calm offline behavior
                    }

                    try? await Task.sleep(nanoseconds: intervalNanoseconds)
                }
            }
        }
    }

    func stop() {
        lock.withLock {
            task?.cancel()
            task = nil
        }
    }
}
