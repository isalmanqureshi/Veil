# Pricing and Business Model

## Product tiers
### Free tier
Default app usage without subscription. App remains usable if pricing fetch fails.

### Privacy Pro tier (`Veil Pro`)
Displayed feature value proposition includes:
- custom timers + per-chat defaults
- encrypted backups (off by default)
- advanced group controls
- stronger request protections

Some listed benefits are roadmap-level and not fully implemented yet.

## Implemented pricing logic
- `PricingView` loads StoreKit products via `EntitlementsStore.fetchProducts()`.
- User can subscribe, restore purchases, or skip.
- Subscription status reflected through `EntitlementsStore.isPro`.

## Entitlement evaluation
`EntitlementsStore.refresh()`:
- Uses `Transaction.currentEntitlements` for real StoreKit verification.
- Accepts matching product IDs in `VeilProductID`.
- Persists boolean entitlement in UserDefaults.

## Fallback/mock behavior
If StoreKit product loading/restoration fails:
- `FallbackPurchaseProvider` switches to `MockPurchaseProvider`.
- Mock offers are shown in UI.
- Mock purchase toggles local pro entitlement for testing/demo.

## Feature gating status
- Entitlement state exists and is exposed app-wide.
- Deep runtime feature gating beyond pricing screen copy is **WIP**.

## Key references
- `Veil/PricingView.swift`
- `Veil/EntitlementsStore.swift`
- `Veil/PurchaseProvider.swift`
- `Veil/StoreKitPurchaseProvider.swift`
- `Veil/FallbackPurchaseProvider.swift`
- `Veil/MockPurchaseProvider.swift`
