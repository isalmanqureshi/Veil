import XCTest
@testable import Veil

final class ChatEncryptionTests: XCTestCase {

    func testMockInboxDataIsDeterministicAndPopulated() {
        let chatRepo = MockChatRepository(crypto: MockCryptoService())
        let requestRepo = MockMessageRequestsRepository(chatRepo: chatRepo)

        let chats = chatRepo.listChats()
        let requests = requestRepo.loadRequests()

        XCTAssertEqual(chats.count, 4)
        XCTAssertEqual(requests.count, 3)
        XCTAssertEqual(chats.map(\.username), ["maya", "aiden", "unknown_veil", "studio_ops"])
        XCTAssertEqual(requests.map(\.fromUsername), ["new_friend", "unknown_veil", "community_mod"])
    }

    func testAuthenticatedCryptoServiceProducesEncryptedEnvelopeWithoutPlaintextLeak() throws {
        let crypto = AuthenticatedCryptoService()
        var sender = SessionState(
            username: "alice",
            createdAt: Date(),
            remoteOneTimePreKeyId: nil,
            rootKey: Data(repeating: 1, count: 32),
            sendingChainKey: Data(repeating: 7, count: 32),
            receivingChainKey: Data(repeating: 9, count: 32)
        )

        var receiver = SessionState(
            username: "alice",
            createdAt: Date(),
            remoteOneTimePreKeyId: nil,
            rootKey: Data(repeating: 1, count: 32),
            sendingChainKey: Data(repeating: 9, count: 32),
            receivingChainKey: Data(repeating: 7, count: 32)
        )

        let plaintext = "top secret message"
        let sealed = try crypto.encrypt(plaintext: plaintext, for: "alice", session: &sender)

        XCTAssertFalse(sealed.contains(plaintext))

        guard let envelopeData = Data(base64Encoded: sealed) else {
            return XCTFail("Envelope should be base64 encoded")
        }

        XCTAssertGreaterThan(envelopeData.count, 5)
        XCTAssertEqual(envelopeData[0], 1)

        let decrypted = try crypto.decrypt(ciphertext: sealed, for: "alice", session: &receiver)
        XCTAssertEqual(decrypted, plaintext)
    }

    func testDecryptFailureDoesNotMutateSessionState() throws {
        let crypto = AuthenticatedCryptoService()
        var session = SessionState(
            username: "alice",
            createdAt: Date(),
            remoteOneTimePreKeyId: nil,
            rootKey: Data(repeating: 1, count: 32),
            sendingChainKey: Data(repeating: 7, count: 32),
            receivingChainKey: Data(repeating: 9, count: 32)
        )

        let original = session
        XCTAssertThrowsError(try crypto.decrypt(ciphertext: "not-base64", for: "alice", session: &session))
        XCTAssertEqual(session, original)
    }

    @MainActor
    func testRetryFailedUsesOriginalPlaintext() async {
        let repo = RetryAwareChatRepository()
        let vm = ChatViewModel(chatUsername: "alice", repo: repo)
        vm.draftText = "hello there"

        vm.sendTapped()
        await wait(seconds: 0.2)

        guard let failed = vm.messages.first(where: { $0.state == .failed }) else {
            return XCTFail("Expected failed message after first send")
        }

        vm.retryFailed(failed)
        await wait(seconds: 0.2)

        XCTAssertEqual(repo.sentPlaintexts, ["hello there", "hello there"])
        XCTAssertEqual(vm.messages.first?.state, .sent)
    }

    private func wait(seconds: TimeInterval) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}

private final class RetryAwareChatRepository: ChatRepository {
    var sentPlaintexts: [String] = []
    private var shouldFailFirstSend = true

    func loadMessages(chatUsername: String) -> [ChatMessage] { [] }

    func sendMessage(chatUsername: String, plaintext: String, timer: MessageTimer) async throws -> ChatMessage {
        sentPlaintexts.append(plaintext)

        if shouldFailFirstSend {
            shouldFailFirstSend = false
            throw SendError.transient
        }

        return ChatMessage(
            id: UUID(),
            chatUsername: chatUsername,
            direction: .outgoing,
            ciphertext: "cipher",
            plaintextPreview: plaintext,
            createdAt: Date(),
            timer: timer,
            state: .sent
        )
    }

    func listChats() -> [ChatThread] { [] }
}
