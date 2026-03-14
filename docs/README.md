# Veil iOS Technical Documentation

## What Veil is
Veil is a SwiftUI iOS messaging application focused on private, username-based communication. Accounts are created with a recovery key-derived seed and support password sign-in on-device.

## Mission
**Private messaging without phone numbers.**

Core UX copy in the app reinforces this model:
- "Private by default. Invisible by design."
- "No phone number. No ads. No tracking."

## Status snapshot
- Implemented:
  - Auth-state root navigation (`AppRootView`) with coordinator path reset on auth transitions.
  - Username onboarding + recovery key generation + password sign-in.
  - Separate account controls for **Sign Out** vs **Remove Account From Device**.
  - X3DH-style session bootstrap, encrypted payload transport, inbox/requests flow, and polling with push-refresh bridge.
- WIP:
  - Full Double Ratchet and persistent encrypted message/session storage.
  - Attachment production pipeline and deeper entitlement-based feature gating.
  - Full trust center product surface and advanced abuse enforcement.
- Planned:
  - Broader device management UX and push-first delivery hardening.

## High-level architecture

```text
┌───────────────────────────────────────────────────────────────────┐
│ UI Layer (SwiftUI Views)                                         │
│ Welcome, Onboarding, Inbox, Chat, Requests, Trust, Pricing       │
└───────────────▲───────────────────────────────────────────────────┘
                │ bindings / events
┌───────────────┴───────────────────────────────────────────────────┐
│ Application Layer (ViewModels + Coordinator + Stores)            │
│ AppCoordinator, AuthStore, InboxViewModel, ChatViewModel         │
└───────────────▲───────────────────────────────────────────────────┘
                │ abstractions / use cases
┌───────────────┴───────────────────────────────────────────────────┐
│ Domain Layer (Repositories + Models)                             │
│ ChatRepository, MessageRequestsRepository, AuthRepository         │
└───────────────▲───────────────────────────────────────────────────┘
                │ services / DTO mapping
┌───────────────┴───────────────────────────────────────────────────┐
│ Security Layer (Key + Session + Crypto)                          │
│ KeyManager, SessionManager (X3DH-style), AuthenticatedCryptoService│
└───────────────▲───────────────────────────────────────────────────┘
                │ HTTP/JSON
┌───────────────┴───────────────────────────────────────────────────┐
│ Networking Layer                                                  │
│ HTTPClient, *Services, DTOs, Poller, PreKeySyncManager           │
└───────────────▲───────────────────────────────────────────────────┘
                │ REST endpoints (/v1/...)
┌───────────────┴───────────────────────────────────────────────────┐
│ Backend Layer                                                     │
│ User registration, prekeys, message queue, request moderation     │
└───────────────────────────────────────────────────────────────────┘
```

## Technology stack
- **Language/UI**: Swift, SwiftUI
- **Crypto**: CryptoKit (Ed25519, X25519, HKDF-SHA256, AES.GCM)
- **Persistence**: Keychain + UserDefaults + in-memory stores (current state)
- **Networking**: URLSession via typed `HTTPClient`
- **Payments**: StoreKit + fallback mock provider
- **App architecture**: MVVM + Coordinator + repository pattern + environment-based dependency injection

## Documentation map
- [ARCHITECTURE.md](./ARCHITECTURE.md)
- [ONBOARDING_AND_AUTH.md](./ONBOARDING_AND_AUTH.md)
- [CRYPTOGRAPHY.md](./CRYPTOGRAPHY.md)
- [MESSAGING_SYSTEM.md](./MESSAGING_SYSTEM.md)
- [INBOX_AND_REQUESTS.md](./INBOX_AND_REQUESTS.md)
- [ABUSE_RESISTANCE.md](./ABUSE_RESISTANCE.md)
- [TRUST_CENTER.md](./TRUST_CENTER.md)
- [BACKEND_API_CONTRACT.md](./BACKEND_API_CONTRACT.md)
- [POLLING_AND_PUSH_DESIGN.md](./POLLING_AND_PUSH_DESIGN.md)
- [DATA_STORAGE.md](./DATA_STORAGE.md)
- [ATTACHMENTS.md](./ATTACHMENTS.md)
- [PRICING_AND_BUSINESS_MODEL.md](./PRICING_AND_BUSINESS_MODEL.md)
- [ROADMAP.md](./ROADMAP.md)
