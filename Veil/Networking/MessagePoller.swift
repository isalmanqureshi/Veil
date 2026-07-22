import Foundation
import Combine

@MainActor
final class MessagePoller: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var lastPollAt: Date?
    @Published private(set) var lastError: String?

    private let chatRepository: NetworkChatRepository
    private let requestsRepository: NetworkMessageRequestsRepository
    private let authContext: LocalAuthContext
    private let intervalNanoseconds: UInt64

    private var task: Task<Void, Never>?

    init(
        chatRepository: NetworkChatRepository,
        requestsRepository: NetworkMessageRequestsRepository,
        pollIntervalSeconds: TimeInterval,
        authContext: LocalAuthContext = LocalAuthContext()
    ) {
        self.chatRepository = chatRepository
        self.requestsRepository = requestsRepository
        self.intervalNanoseconds = UInt64(max(pollIntervalSeconds, 2) * 1_000_000_000)
        self.authContext = authContext
    }

    func start() {
        guard task == nil else { return }
        isRunning = true

        task = Task {
            var backoffNanoseconds = intervalNanoseconds

            while !Task.isCancelled {
                do {
                    _ = try await self.performPollCycle()
                    backoffNanoseconds = intervalNanoseconds
                } catch is CancellationError {
                    break
                } catch {
                    if Task.isCancelled { break }
                    lastError = error.localizedDescription
                    backoffNanoseconds = min(intervalNanoseconds * 2, 30_000_000_000)
                }

                do {
                    try await Task.sleep(nanoseconds: backoffNanoseconds)
                } catch {
                    break
                }
            }

            isRunning = false
            task = nil
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        isRunning = false
    }

    deinit {
        // Safety net: the poll loop strong-captures self, so guarantee teardown
        // even if an owner releases the poller without calling stop().
        task?.cancel()
    }

    func refreshNow() async -> Bool {
        do {
            _ = try await performPollCycle()
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    func restartIfNeeded() {
        stop()
        start()
    }

    private func performPollCycle() async throws -> Bool {
        guard let username = authContext.currentSignedInUsername() else {
            return false
        }

        async let refreshRequests = requestsRepository.refresh(for: username)
        let hasMessages = try await chatRepository.pollIncomingPointers()
        _ = await refreshRequests

        if Task.isCancelled || authContext.currentSignedInUsername() != username {
            return false
        }

        lastPollAt = Date()
        lastError = nil
        return hasMessages
    }
}
