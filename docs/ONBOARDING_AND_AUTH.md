# Onboarding and Authentication

## Identity model
Veil authenticates users by:
- Username
- Recovery key (encodes a 32-byte seed + checksum)

No phone number or email login is implemented.

## Flow overview

### Create account flow
```text
WelcomeView
  -> AuthStore.startOnboarding()
UsernameCreationView
  -> auth.onboardingUsername + prepareRecoveryKeyIfNeeded()
RecoveryKeyView
  -> auth.finishOnboarding()
  -> KeyManager.bootstrapIdentityIfNeeded(seed)
  -> generate prekey bundle
  -> state = .signedIn
InboxView
```

### Login flow
```text
LoginView
  -> auth.login(username, recoveryKey)
  -> RecoveryKeyGenerator.decode(recoveryKey) -> seed
  -> authRepo.restoreUser(...)
  -> KeyManager.bootstrapIdentityIfNeeded(seed)
  -> generate prekey bundle
  -> state = .signedIn
InboxView
```

## `AuthStore`
Responsibilities:
- Source of auth state (`signedOut`, `onboarding`, `signedIn`).
- Generates onboarding recovery key once.
- Validates username/recovery key input.
- Triggers backend identity + prekey sync via `IdentitySyncService`.

Backend sync state is explicit (`idle/syncing/synced/failed`).

## Repositories
### `AuthRepository` (protocol)
Contract for local identity persistence and recovery key lifecycle.

### `MockAuthRepository`
Current concrete implementation; despite name, it is the app’s active local auth persistence component in both modes.
- Stores username in `UserDefaults`.
- Stores seed in Keychain (`veil.identity/identitySeed`).
- Does not persist plaintext recovery key.

### `NetworkAuthRepository` (**WIP / currently not wired in AppEnvironment**)
Wraps `AuthRepository` and opportunistically publishes identity/prekeys to backend asynchronously.

## Recovery key system
`RecoveryKeyGenerator`:
- Creates 32-byte random seed.
- Appends 4-byte SHA256 checksum.
- Encodes in Base32 and groups with `-` separators.
- Decode validates format + checksum.

## Seed derivation and identity bootstrap
- Recovery seed is passed into `KeyManager.bootstrapIdentityIfNeeded(seed:)`.
- Deterministic HKDF derivation produces:
  - Ed25519 identity signing key
  - X25519 identity agreement key

## Identity bootstrap to backend
`IdentitySyncService` network implementation:
1. Builds prekey bundle from `KeyManager`.
2. Registers username/device and identity keys.
3. Publishes signed prekey + one-time prekeys.

## Key references
- `Veil/Authentication/AuthStore.swift`
- `Veil/Authentication/AuthRepository.swift`
- `Veil/Authentication/IdentitySyncService.swift`
- `Veil/Onboarding/LoginView.swift`
- `Veil/Onboarding/UsernameCreationView.swift`
- `Veil/Onboarding/RecoveryKeyView.swift`
- `Veil/Onboarding/Key/RecoveryKeyGenerator.swift`
- `Veil/Onboarding/Key/Managers/KeyManager.swift`
