# Veil iOS Technical Documentation

## What Veil is
Veil is a SwiftUI iOS messaging application focused on private, username-based communication. Accounts are created and restored via a recovery key-derived seed rather than phone number or email identity.

## Mission
**Private messaging without phone numbers.**

Core UX copy in the app reinforces this model:
- "Private by default. Invisible by design."
- "No phone number. No ads. No tracking."

## Key privacy principles
- Username-first identity (no phone/email authentication).
- Locally controlled cryptographic identity generated from recovery key seed.
- End-to-end encrypted message payloads (`payloadB64`) with minimal server-visible metadata.
- Device-local key material storage in Keychain.
- Trust and abuse interfaces that communicate risk with restrained metadata exposure.

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

## Project goals
- Privacy-first direct messaging.
- Minimal, understandable architecture for iterative hardening.
- Progressive migration from mock mode to full network backend mode.
- UX-safe anti-abuse and trust warning primitives.

## Security philosophy
- Make identity deterministic from a seed that users control.
- Keep key derivation and E2EE operations on-device.
- Treat transport as untrusted; only ciphertext leaves device for messages.
- Maintain forward-leaning primitives (X3DH bootstrap, chain KDF) while clearly marking partial implementations as **WIP**.

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
