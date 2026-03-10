# Veil Architecture

## App structure
- Entry point: `VeilApp` + `VeilAppDelegate`.
- Root composition: `AppRootView` in `Coordinator/AppRouteView.swift`.
- Dependency root: `AppEnvironment`.

## Coordinator navigation
Veil uses `NavigationStack` with app routes (`AppRoute` enum) and a shared `AppCoordinator`.

```text
View intent -> coordinator.push(.route)
           -> NavigationStack path mutation
           -> destination view resolution in routeView(for:)
```

Benefits:
- Removes direct view-to-view coupling.
- Central route vocabulary (`login`, `recoveryKey`, `chat(username:)`, `requestDetails`, etc.).

## MVVM implementation
Major UI modules use view model boundaries:
- `ChatView` -> `ChatViewModel`
- `InboxView` -> `InboxViewModel`
- Onboarding/Auth screens mostly bind directly to `AuthStore` (store-style VM).

### ViewModel boundary rule
- Views own presentation and user interaction.
- ViewModels own screen state, async orchestration, and repository calls.

## Dependency injection via `AppEnvironment`
`AppEnvironment` creates and exposes all major dependencies as `@EnvironmentObject` and constructor-injected repositories/services.

Two modes:
1. **Mock backend mode** (`useMockBackend = true`):
   - `MockAuthRepository`
   - `MockChatRepository`
   - `MockMessageRequestsRepository`
   - No HTTP services/poller
2. **Network backend mode**:
   - `Network*Service` via `HTTPClient`
   - `NetworkChatRepository` + `NetworkMessageRequestsRepository`
   - `MessagePoller` + `PreKeySyncManager`

## EnvironmentObject usage
`AppRootView` injects:
- `AppCoordinator`
- `AppEnvironment`
- `TrustCenter`
- `AuthStore`
- `EntitlementsStore`

This yields global app state access without direct singleton coupling.

## Repository pattern
Repositories define app-facing contracts and isolate transport/mock details.

```text
View
 ↓
ViewModel (or Store)
 ↓
Repository protocol
 ↓
Mock or Network implementation
 ↓
Service layer
 ↓
Backend API
```

## Why this structure
- Easy offline UX prototyping using deterministic mock repositories.
- Straight migration path to production backend (same interfaces).
- Testable layers: crypto/session and chat behavior are separable from UI.
- Security-critical code remains in dedicated crypto/session modules instead of views.

## Key code references
- `Veil/AppEnvironment.swift`
- `Veil/Coordinator/AppCoordinator.swift`
- `Veil/Coordinator/AppRouteView.swift`
- `Veil/Chats/ViewModel/ChatViewModel.swift`
- `Veil/Inbox/ViewModel/InboxViewModel.swift`
