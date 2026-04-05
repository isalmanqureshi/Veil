import SwiftUI
import StoreKit

struct PricingView: View {

    @EnvironmentObject private var entitlements: EntitlementsStore
    @EnvironmentObject private var coordinator: AppCoordinator

    @State private var products: [Product] = []
    @State private var selectedProductID: String?
    @State private var errorText: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Veil Pro")
                    .font(.system(size: 32, weight: .bold))

                Text("Pay to fund privacy. No ads. No tracking.")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)

                benefitRow("Custom timers + defaults per chat")
                benefitRow("Encrypted backups (off by default)")
                benefitRow("Advanced group controls")
                benefitRow("Stronger request protections")

                if !products.isEmpty {
                    productCards
                } else {
                    fallbackPricing
                }

                if let errorText {
                    Text(errorText)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }

                Button {
                    Task { await subscribe() }
                } label: {
                    Text(entitlements.isPro ? "You’re subscribed" : "Subscribe")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .disabled(!canSubscribe)
                .background(canSubscribe ? Color.primary : Color(.secondarySystemBackground))
                .foregroundStyle(canSubscribe ? Color(.systemBackground) : .secondary)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Button("Restore purchases") {
                    Task { await restore() }
                }
                .font(.system(size: 15, weight: .semibold))

                Button("Not now") {
                    coordinator.pop()
                }
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            }
            .padding(20)
        }
        .navigationTitle("Veil Pro")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadProducts()
        }
    }

    private var selectedProduct: Product? {
        products.first(where: { $0.id == selectedProductID })
    }

    private var selectedMockOffer: MockOffer? {
        entitlements.mockOffers.first(where: { $0.id == selectedProductID })
    }

    private var canSubscribe: Bool {
        if entitlements.isPro {
            return false
        }

        if selectedProduct != nil {
            return true
        }

        if entitlements.isUsingMockProvider, selectedMockOffer != nil {
            return true
        }

        return false
    }

    private var productCards: some View {
        VStack(spacing: 10) {
            ForEach(products, id: \.id) { product in
                Button {
                    selectedProductID = product.id
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(product.displayName)
                                .font(.system(size: 16, weight: .semibold))
                            Text(product.displayPrice)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if selectedProductID == product.id {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .padding(14)
                }
                .buttonStyle(.plain)
                .background(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(selectedProductID == product.id ? Color.primary : .clear, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    @ViewBuilder
    private var fallbackPricing: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pricing unavailable")
                .font(.system(size: 15, weight: .semibold))
            Text("We couldn’t load App Store pricing right now.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            if entitlements.isUsingMockProvider {
                VStack(spacing: 10) {
                    ForEach(entitlements.mockOffers) { offer in
                        Button {
                            selectedProductID = offer.id
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(offer.title)
                                        .font(.system(size: 15, weight: .semibold))
                                    Text("\(offer.subtitle) • \(offer.price)")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if selectedProductID == offer.id {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                            }
                            .padding(12)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func benefitRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
        }
        .font(.system(size: 14))
    }

    private func loadProducts() async {
        do {
            let loaded = try await entitlements.fetchProducts()
            products = loaded
            selectedProductID = loaded.first?.id ?? entitlements.mockOffers.first?.id
            errorText = nil
        } catch {
            products = []
            selectedProductID = entitlements.mockOffers.first?.id
            errorText = "Store temporarily unavailable. You can still continue using Veil."
        }
    }

    private func subscribe() async {
        errorText = nil

        if let selectedProduct {
            do {
                _ = try await entitlements.purchase(selectedProduct)
            } catch {
                errorText = "Couldn’t complete purchase right now."
            }
            return
        }

        if entitlements.isUsingMockProvider, let selectedProductID {
            await entitlements.purchaseMock(productID: selectedProductID)
            return
        }

        errorText = "Select a plan to continue."
    }

    private func restore() async {
        do {
            try await entitlements.restore()
        } catch {
            errorText = "Couldn’t restore purchases right now."
        }
    }
}

#Preview {
    NavigationStack {
        PricingView()
            .environmentObject(AppCoordinator())
            .environmentObject(AppEnvironment())
            .environmentObject(EntitlementsStore(purchaseProvider: MockPurchaseProvider()))
    }
}
