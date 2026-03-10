# Abuse Resistance

## Current anti-abuse primitives
Veil has foundational anti-abuse scaffolding embedded across request models and UI.

## Signals model
`RequestSignals` includes:
- Proof-of-work signal state (`none`, `verified`, `required`)
- Rate-limit state (`none`, `light`, `heavy`, `throttled`)
- First-contact marker
- Optional confidence note

This is surfaced in request details via `RequestSignalsFormatter`.

## Actions for abuse handling
From request details, user can:
- Ignore
- Block
- Report (with optional reason)

Network repository forwards these actions to backend endpoints (`/v1/requests/ignore|block|report`).

## Invite / trust signal primitives
`AbuseSignal` defines structured event types for behaviors such as:
- invite abuse
- rapid message burst
- blocked/reported by peer
- screenshot detected
- device added / identity changed

This indicates a planned event-driven abuse/trust subsystem.

## Risk communication approach
UI wording is intentionally calm and metadata-minimizing:
- avoids exposing operational internal scores
- uses short context lines (e.g., "Rate-limited", "First contact")
- avoids panic language

## Proof-of-work and rate limiting status
- Signal fields exist in domain and DTOs.
- Enforcement policy and adaptive throttling logic are **WIP** on client side; currently interpreted/displayed from data.

## Key references
- `Veil/Chats/Model/MessageRequestThread.swift`
- `Veil/Inbox/Views/RequestDetailsView.swift`
- `Veil/Networking/DTO/WireDTOs.swift`
- `Veil/Networking/Repositories/NetworkMessageRequestsRepository.swift`
- `Veil/Abuse/AbuseSignal.swift`
