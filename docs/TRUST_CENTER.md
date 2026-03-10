# Trust Center

## Purpose
Trust Center centralizes security-relevant events and routes user-visible warnings when severity requires attention.

## Core types
- `TrustEventType`: screenshot, new device, identity key change, unverified contact, request blocked/reported.
- `TrustEvent`: title, message, timestamp, severity.
- `TrustState`: active events + historical log + last reviewed timestamp.

## TrustCenter behavior
- `log(event:)` appends to log and active list.
- non-info events trigger navigation to `TrustWarningView` via `AppCoordinator`.
- can dismiss active events and query critical issue status.

## UI surfaces
- `TrustWarningView`: generic warning UI route.
- `IdentityVerificationView`: basic identity verification status screen (**WIP scaffold**).

## Security model
The model supports:
- explicit surfacing of account and conversation trust changes
- controlled route-based warning presentation
- non-blocking event log accumulation for later review/center UI expansion

## **WIP notes**
- No dedicated full Trust Center screen yet (logic exists, not fully productized UI).
- Identity fingerprint and QR verification workflows are not fully implemented; `IdentityVerificationView` is placeholder simulation.

## Key references
- `Veil/TrustCenter.swift`
- `Veil/TrustWarningView.swift`
- `Veil/IdentityVerificationView.swift`
- `Veil/Coordinator/AppRouteView.swift`
