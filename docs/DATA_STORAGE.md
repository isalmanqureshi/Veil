# Data Storage

## Status
- Implemented:
  - Keychain storage for identity seed, key material, and password verifier/salt.
  - UserDefaults for session flags, username/device metadata, and push token sync metadata.
  - Destructive local wipe path (`LocalDataWiper`) for account removal from device.
- WIP:
  - Durable encrypted message and session persistence.
- Planned:
  - Encrypted database-backed message/session stores and attachment metadata persistence.

## Current local storage

### Keychain
Used for sensitive material:
- Recovery seed (`veil.identity/identitySeed` via `MockAuthRepository`)
- Password salt + verifier (`veil.credentials/passwordSalt`, `veil.credentials/passwordVerifier`)
- Identity key private material (`KeyManager` accounts)
- Signed prekey private key/signature/metadata
- One-time prekey index + private keys

### UserDefaults
Used for non-sensitive app/session metadata:
- Current username
- Session signed-in flag
- Device ID
- Push token + sync markers
- Subscription entitlement (`isPro`)
- Mock purchase flags

### In-memory stores
- `NetworkChatRepository` and `MockChatRepository` keep message/thread cache in memory dictionaries.
- `InMemorySessionStore` stores `SessionState` in process memory.
- Request repositories keep in-memory request cache.

## Session controls and storage impact
### Sign out (`AuthStore.signOut`)
- Clears volatile auth/onboarding state and sets session signed-in flag to false.
- Does **not** clear local account identity seed/password verifier/key material.

### Remove account from device (`AuthStore.eraseLocalData`)
- Invokes `LocalDataWiper.wipeAllLocalData()`.
- Clears auth repository state, password verifier/salt, local key material, push token local state, and session/device defaults.
- Then signs out.

## Chat cache / message storage
Current message persistence is runtime-only in repository memory. There is no durable encrypted message DB yet.

## Session state and skipped keys
`SessionState` includes:
- root key
- sending/receiving chain keys
- counters
- skipped message keys buffer

Currently persisted only in `InMemorySessionStore` (**WIP for durable encrypted storage**).

## Planned encrypted storage options
Design-compatible future options:
- CoreData + SQLCipher
- GRDB + SQLCipher

Recommended mapping:
- encrypted message table
- encrypted session table
- skipped key records indexed by peer+counter
- attachment reference table

## Keychain usage notes
`KeychainStore` writes with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.

## Key references
- `Veil/Onboarding/Key/KeychainStore.swift`
- `Veil/Authentication/AuthRepository.swift`
- `Veil/Authentication/PasswordManager.swift`
- `Veil/Authentication/LocalDataWiper.swift`
- `Veil/Onboarding/Key/Managers/KeyManager.swift`
- `Veil/Onboarding/Key/Managers/SessionStore.swift`
- `Veil/Networking/Repositories/NetworkChatRepository.swift`
- `Veil/AppEnvironment.swift`
- `Veil/EntitlementsStore.swift`
