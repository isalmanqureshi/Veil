import Foundation

final class MessagePoller {
    private let messagesService: MessagesService
    private let chatRepository: NetworkChatRepository
    private let requestsRepository: NetworkMessageRequestsRepository
    private let authContext: LocalAuthContext
    private let intervalNanoseconds: UInt64

    private let lock = NSLock()
    private var task: Task<Void, Never>?

    init(
        messagesService: MessagesService,
        chatRepository: NetworkChatRepository,
        requestsRepository: NetworkMessageRequestsRepository,
        pollIntervalSeconds: TimeInterval,
        authContext: LocalAuthContext = LocalAuthContext()
    ) {
        self.messagesService = messagesService
        self.chatRepository = chatRepository
        self.requestsRepository = requestsRepository
        self.intervalNanoseconds = UInt64(max(pollIntervalSeconds, 2) * 1_000_000_000)
        self.authContext = authContext
    }

    func start() {
        lock.withLock {
            guard task == nil else { return }
            task = Task { [messagesService, chatRepository, requestsRepository, intervalNanoseconds, authContext] in
                var backoffNanoseconds = intervalNanoseconds

                while !Task.isCancelled {
                    guard let username = authContext.currentUsername() else {
                        try? await Task.sleep(nanoseconds: intervalNanoseconds)
                        continue
                    }

                    let deviceId = authContext.currentDeviceId()

                    do {
                        async let inboxResponse = messagesService.pollInbox(username: username, deviceId: deviceId)
                        async let refreshRequests = requestsRepository.refresh()
                        let envelopes = try await inboxResponse.messages
                        _ = await refreshRequests

                        let ackIds = chatRepository.ingestIncoming(envelopes)
                        if !ackIds.isEmpty {
                            _ = try await messagesService.ackMessages(.init(username: username, deviceId: deviceId, messageIds: ackIds))
                        }

                        backoffNanoseconds = intervalNanoseconds
                    } catch {
                        backoffNanoseconds = min(backoffNanoseconds * 2, 30_000_000_000)
                    }

                    try? await Task.sleep(nanoseconds: backoffNanoseconds)
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
