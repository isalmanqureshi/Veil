import Foundation
import StoreKit

final class FallbackPurchaseProvider: PurchaseProvider {

    private let primary: StoreKitPurchaseProvider
    private let mock: MockPurchaseProvider
    private(set) var usingMock = false

    init(primary: StoreKitPurchaseProvider = StoreKitPurchaseProvider(), mock: MockPurchaseProvider = MockPurchaseProvider()) {
        self.primary = primary
        self.mock = mock
    }

    func products() async throws -> [Product] {
        if usingMock { return [] }

        do {
            return try await primary.products()
        } catch {
            usingMock = true
            return []
        }
    }

    func purchase(_ product: Product) async throws -> Bool {
        if usingMock { return false }
        return try await primary.purchase(product)
    }

    func restore() async throws {
        if usingMock {
            try await mock.restore()
            return
        }

        do {
            try await primary.restore()
        } catch {
            usingMock = true
            try await mock.restore()
        }
    }

    func observeTransactions() -> AsyncStream<Void> {
        if usingMock {
            return mock.observeTransactions()
        }
        return primary.observeTransactions()
    }

    var mockOffers: [MockOffer] { mock.offers }

    func purchaseMock(productID: String) {
        usingMock = true
        mock.purchaseMock(productID: productID)
    }

    var hasPurchasedMock: Bool { mock.hasPurchasedMock }
}
