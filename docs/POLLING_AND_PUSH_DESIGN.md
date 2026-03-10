# Polling and Push Design

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

## Push-ready architecture
Push plumbing is present:
- `VeilAppDelegate` forwards APNs callbacks to `PushNotificationCoordinator`.
- Push token persisted/synced through `PushTokenStore` + `PushTokenSyncService`.
- `PushNotificationCoordinator` triggers inbox refresh handler on foreground and remote push receipt.

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
- `Veil/Networking/LocalAuthContext.swift`
- `Veil/Networking/BackendConfig.swift`
