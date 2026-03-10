import Foundation
import StoreKit

final class StoreKitPurchaseProvider: PurchaseProvider {

    private let productIDs: [String]

    init(productIDs: [String] = VeilProductID.all) {
        self.productIDs = productIDs
    }

    func products() async throws -> [Product] {
        try await Product.products(for: productIDs)
            .sorted { $0.price < $1.price }
    }

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            return true
        case .pending, .userCancelled:
            return false
        @unknown default:
            return false
        }
    }

    func restore() async throws {
        try await AppStore.sync()
    }

    func observeTransactions() -> AsyncStream<Void> {
        AsyncStream { continuation in
            let task = Task {
                for await update in Transaction.updates {
                    if let transaction = try? checkVerified(update) {
                        await transaction.finish()
                    }
                    continuation.yield(())
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw StoreError.failedVerification
        }
    }
}

enum StoreError: LocalizedError {
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Purchase verification failed."
        }
    }
}
