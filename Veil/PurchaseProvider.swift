import Foundation
import StoreKit

protocol PurchaseProvider {
    func products() async throws -> [Product]
    func purchase(_ product: Product) async throws -> Bool
    func restore() async throws
    func observeTransactions() -> AsyncStream<Void>
}

enum VeilProductID {
    static let monthly = "com.veil.pro.monthly"
    static let yearly = "com.veil.pro.yearly"

    static let all = [monthly, yearly]
}
