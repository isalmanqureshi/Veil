# Onboarding and Authentication

## Identity model
Veil authentication is username-based and device-local.

- Primary sign-in: **username + password**.
- Recovery fallback: **username + recovery key**, then password reset.
- No phone number or email auth is implemented.

## Status
- Implemented:
  - Username onboarding with generated recovery key.
  - Password-based sign in (`LoginView` -> `AuthStore.login`).
  - Recovery-key restore path (`RecoveryLoginView` -> `AuthStore.recoverAccount`) with required password reset.
  - Session-level sign out and destructive local erase as separate actions.
- WIP:
  - `NetworkAuthRepository` integration in `AppEnvironment` (currently local `MockAuthRepository` is used for identity persistence in both modes).
- Planned:
  - Multi-account/device management UX beyond the current single local account model.

## Flow overview

### Create account flow
```text
WelcomeView
  -> AuthStore.startOnboarding()
UsernameCreationView
  -> auth.setOnboardingUsername(...)
  -> auth.prepareRecoveryKeyIfNeeded()
RecoveryKeyView
  -> auth.finishOnboarding()
  -> authRepo.createUser(username, seed, recoveryKey)
  -> KeyManager.bootstrapIdentityIfNeeded(seed)
  -> KeyManager.makePreKeyBundle(...)
  -> PasswordManager.setPassword(...)
  -> state = .signedIn
InboxView
```

### Password login flow
```text
WelcomeView -> LoginView
  -> auth.login(username, password)
  -> authRepo.loadCurrentUser() + PasswordManager.verifyPassword(...)
  -> state = .signedIn
InboxView
```

### Recovery flow (break-glass)
```text
WelcomeView -> RecoveryLoginView
  -> auth.recoverAccount(username, recoveryKey)
  -> RecoveryKeyGenerator.decode(recoveryKey)
  -> authRepo.restoreUser(...)
  -> KeyManager.bootstrapIdentityIfNeeded(seed)
  -> state = .requiresPasswordReset
ResetPasswordView
  -> auth.resetPassword(newPassword)
  -> PasswordManager.setPassword(...)
  -> state = .signedIn
```

### Account/session controls flow
```text
PrivacyDashboardView
  -> Sign Out
     -> AuthStore.signOut()
     -> set sessionSignedIn false
     -> state = .signedOut

  -> Remove Account From Device
     -> AuthStore.eraseLocalData()
     -> LocalDataWiper.wipeAllLocalData()
     -> AuthStore.signOut()
```

## `AuthStore`
Responsibilities:
- Source of auth state (`signedOut`, `onboarding`, `requiresPasswordReset`, `signedIn`).
- Generates onboarding recovery key and seed once per onboarding attempt.
- Validates username/password/recovery-key input.
- Triggers backend identity + prekey sync via `IdentitySyncService` after successful signed-in transitions.
- Separates:
  - `signOut()` (**session-level**) from
  - `eraseLocalData()` (**destructive local-device wipe**).

Backend sync state is explicit (`idle/syncing/synced/failed`).

## Repositories
### `AuthRepository` (protocol)
Contract for local identity persistence and recovery-key lifecycle.

### `MockAuthRepository`
Current concrete implementation; despite name, it is the active local auth persistence component in both app modes.
- Stores username in `UserDefaults`.
- Stores identity seed in Keychain (`veil.identity/identitySeed`).
- Does not persist plaintext recovery key.

### `NetworkAuthRepository` (**WIP / currently not wired in AppEnvironment**)
Wraps an `AuthRepository` and attempts backend registration/prekey publish after local create/restore.

## Recovery key system
`RecoveryKeyGenerator`:
- Creates 32-byte random seed.
- Appends 4-byte SHA256 checksum.
- Encodes in Base32 and groups with `-` separators.
- Decode validates format + checksum.

## Sign out vs erase local data
- `signOut()`:
  - clears volatile onboarding/login state,
  - clears signed-in session flag,
  - transitions auth state to `.signedOut`.
  - preserves local account seed/password material for routine password sign-in.
- `eraseLocalData()`:
  - clears local account identity (`AuthRepository.clear()`),
  - clears password verifier/salt,
  - clears key material via `KeyManager.eraseLocalKeyMaterial()`,
  - clears APNs token state and device/session defaults,
  - then signs out.

## Key references
- `Veil/Authentication/AuthStore.swift`
- `Veil/Authentication/AuthRepository.swift`
- `Veil/Authentication/PasswordManager.swift`
- `Veil/Authentication/LocalDataWiper.swift`
- `Veil/Authentication/IdentitySyncService.swift`
- `Veil/Onboarding/LoginView.swift`
- `Veil/Onboarding/RecoveryLoginView.swift`
- `Veil/Onboarding/ResetPasswordView.swift`
- `Veil/Onboarding/RecoveryKeyView.swift`
- `Veil/Onboarding/Key/RecoveryKeyGenerator.swift`
- `Veil/Onboarding/Key/Managers/KeyManager.swift`
