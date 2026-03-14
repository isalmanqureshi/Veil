# Polling and Push Design

## Status
- Implemented:
  - Polling loop (`MessagePoller`) in network mode.
  - Push token capture/sync and push-triggered inbox refresh bridge.
  - Polling + prekey maintenance start/stop tied to app active state and signed-in state.
- WIP:
  - Full push-first delivery operation at scale.
- Planned:
  - Production APNs/notification payload hardening and richer delivery telemetry.

## Polling architecture (`MessagePoller`)
`MessagePoller` runs when app is active + signed in (managed by `AppEnvironment`).

Cycle:
1. Resolve `username` + `deviceId` from `LocalAuthContext`.
2. Poll inbox (`messagesService.pollInbox`).
3. Refresh requests concurrently (`requestsRepository.refresh`).
4. Ingest and decrypt envelopes via `NetworkChatRepository.ingestIncoming`.
5. Ack message ids (`messagesService.ackMessages`).
6. Track `lastPollAt`, `lastError`.

### Polling intervals
- Config default: 3s (`BackendConfig.pollIntervalSeconds`).
- Poller enforces minimum 2s and uses exponential backoff on errors (up to 30s).

### Deduplication
`NetworkChatRepository` tracks `seenServerMessageIds` to prevent duplicate UI ingestion and duplicate ack storms.

## Lifecycle control (`AppEnvironment`)
`AppEnvironment.updatePollingState()` controls background loops:
- start poller + prekey maintenance only when both:
  - signed in (`setSignedIn(true)`), and
  - app active (`setAppActive(true)`).
- stop poller + prekey maintenance otherwise.

This means sign-out and local account erase both end polling/maintenance via the shared auth-state transition path in `AppRootView`.

## Push-ready architecture
Push plumbing is present:
- `VeilAppDelegate` forwards APNs callbacks to `PushNotificationCoordinator`.
- Push token persisted/synced through `PushTokenStore` + `PushTokenSyncService`.
- `PushNotificationCoordinator` triggers inbox refresh handler on foreground and remote push receipt.

## Local push token data on account removal
- `PushTokenStore.clear()` is called by `LocalDataWiper` during “Remove Account From Device”.
- This removes token + sync markers from local storage.

## Future push payload design
Recommended/assumed from current architecture:
- Push payload should contain **no plaintext message body**.
- Use opaque signal only (e.g., queue hint / badge increment / message available).
- App performs authenticated poll/decrypt after push wakeup.

This aligns with existing `refreshInboxFromPush()` behavior in `AppEnvironment`.

## Key references
- `Veil/Networking/MessagePoller.swift`
- `Veil/AppEnvironment.swift`
- `Veil/VeilApp.swift`
- `Veil/Authentication/LocalDataWiper.swift`
- `Veil/Networking/LocalAuthContext.swift`
- `Veil/Networking/BackendConfig.swift`
