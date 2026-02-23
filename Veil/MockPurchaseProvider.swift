import Foundation
import StoreKit

struct MockOffer: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let price: String
}

final class MockPurchaseProvider: PurchaseProvider {

    private let purchasedKey = "veil.mock.pro.purchased"

    let offers: [MockOffer] = [
        .init(id: VeilProductID.monthly, title: "Monthly", subtitle: "Billed every month", price: "$4.99"),
        .init(id: VeilProductID.yearly, title: "Yearly", subtitle: "Billed yearly • Best value", price: "$39.99")
    ]

    func products() async throws -> [Product] {
        []
    }

    func purchase(_ product: Product) async throws -> Bool {
        UserDefaults.standard.set(true, forKey: purchasedKey)
        return true
    }

    func restore() async throws {
        if UserDefaults.standard.bool(forKey: purchasedKey) {
            UserDefaults.standard.set(true, forKey: purchasedKey)
        }
    }

    func observeTransactions() -> AsyncStream<Void> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    func purchaseMock(productID: String) {
        guard offers.contains(where: { $0.id == productID }) else { return }
        UserDefaults.standard.set(true, forKey: purchasedKey)
    }

    var hasPurchasedMock: Bool {
        UserDefaults.standard.bool(forKey: purchasedKey)
    }
}
