import Foundation
import StoreKit

protocol EntitlementsProviding {
    var isPro: Bool { get }
    func refresh() async
}

@MainActor
final class EntitlementsStore: ObservableObject, EntitlementsProviding {

    @Published private(set) var isPro: Bool

    private let isProDefaultsKey = "veil.entitlements.isPro"
    private let purchaseProvider: PurchaseProvider
    private var transactionObserverTask: Task<Void, Never>?

    init(purchaseProvider: PurchaseProvider) {
        self.purchaseProvider = purchaseProvider
        self.isPro = UserDefaults.standard.bool(forKey: isProDefaultsKey)
        observeTransactions()

        Task {
            await refresh()
        }
    }

    deinit {
        transactionObserverTask?.cancel()
    }

    func refresh() async {
        if let mockProvider = purchaseProvider as? MockPurchaseProvider {
            updateEntitlement(isPro: mockProvider.hasPurchasedMock)
            return
        }

        if let fallbackProvider = purchaseProvider as? FallbackPurchaseProvider, fallbackProvider.usingMock {
            updateEntitlement(isPro: fallbackProvider.hasPurchasedMock)
            return
        }

        var hasActiveEntitlement = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard VeilProductID.all.contains(transaction.productID) else { continue }
            if transaction.revocationDate == nil {
                hasActiveEntitlement = true
                break
            }
        }

        updateEntitlement(isPro: hasActiveEntitlement)
    }

    func purchase(_ product: Product) async throws -> Bool {
        let purchased = try await purchaseProvider.purchase(product)
        await refresh()
        return purchased
    }

    func restore() async throws {
        try await purchaseProvider.restore()
        await refresh()
    }

    func fetchProducts() async throws -> [Product] {
        try await purchaseProvider.products()
    }

    func purchaseMock(productID: String) async {
        if let mockProvider = purchaseProvider as? MockPurchaseProvider {
            mockProvider.purchaseMock(productID: productID)
            await refresh()
            return
        }
        if let fallbackProvider = purchaseProvider as? FallbackPurchaseProvider {
            fallbackProvider.purchaseMock(productID: productID)
            await refresh()
        }
    }

    var mockOffers: [MockOffer] {
        if let mock = purchaseProvider as? MockPurchaseProvider { return mock.offers }
        if let fallback = purchaseProvider as? FallbackPurchaseProvider { return fallback.mockOffers }
        return []
    }

    var isUsingMockProvider: Bool {
        if purchaseProvider is MockPurchaseProvider { return true }
        if let fallback = purchaseProvider as? FallbackPurchaseProvider { return fallback.usingMock }
        return false
    }

    private func updateEntitlement(isPro: Bool) {
        self.isPro = isPro
        UserDefaults.standard.set(isPro, forKey: isProDefaultsKey)
    }

    private func observeTransactions() {
        // `[weak self]` breaks the retain cycle: the observed transaction stream
        // may never terminate, so a strong capture would keep `self` alive
        // forever and `deinit` (which cancels this task) would never run.
        transactionObserverTask = Task { [weak self, purchaseProvider] in
            for await _ in purchaseProvider.observeTransactions() {
                await self?.refresh()
            }
        }
    }
}
