# Veil Roadmap

## Implemented
- Username onboarding flow with generated recovery key.
- Password-based sign in with recovery-key fallback and required password reset.
- Clear separation of account controls:
  - session `Sign Out`
  - destructive `Remove Account From Device` local wipe.
- Local identity seed handling and deterministic key bootstrap.
- Deterministic identity key derivation and prekey generation.
- X3DH-style session establishment (initiator path).
- AES-GCM encrypted message payload pipeline with chain counters.
- Chat UI and send state UX (sending/sent/failed + silent retry).
- Inbox with chats and message requests.
- Request actions: accept, ignore, block, report.
- Network service layer + DTO contracts for users/prekeys/messages/requests.
- Polling architecture with ack and dedupe.
- Push-ready APNs token registration + refresh bridge.
- StoreKit-based pricing skeleton with fallback mock mode.

## In progress (**WIP**)
- Full Double Ratchet (beyond current symmetric chain model).
- Persistent encrypted storage for messages and sessions.
- Fully integrated trust center product surface.
- Attachment crypto/upload/download production pipeline.
- Deeper feature gating tied to paid entitlements.
- Comprehensive abuse policy enforcement logic on client.
- Full `NetworkAuthRepository` adoption as the default auth repository path.

## Planned
- Full backend deployment readiness and hardening.
- Push-driven low-latency delivery at scale (poll fallback retained).
- Device management and richer trust verification UX (fingerprints/QR).
- Group messaging expansion.
- Desktop clients and/or multi-platform expansion.
- Additional cryptographic audits and protocol hardening.
