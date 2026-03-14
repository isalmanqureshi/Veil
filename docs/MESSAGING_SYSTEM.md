# Messaging System

## Status
- Implemented:
  - Chat send/receive with optimistic UI, retry, and encrypted network envelopes.
  - Inbox ingest + ack pipeline through `NetworkChatRepository` and `MessagePoller`.
- WIP:
  - Persistent encrypted message store.
  - Full Double Ratchet evolution.
- Planned:
  - Richer delivery receipts and durable sync state.


## Core components
- `ChatView` (UI)
- `ChatViewModel` (send/retry/attachment UX state)
- `ChatRepository` (protocol)
- `MockChatRepository` (deterministic seeded local behavior)
- `NetworkChatRepository` (E2EE payload + backend transport)

## Models
- `ChatMessage` (`incoming/outgoing`, `sending/sent/failed`)
- `ChatThread` (inbox list item)

## Send pipeline
```text
User taps Send
 -> ChatViewModel inserts local sending bubble
 -> ChatRepository.sendMessage(...)
 -> ensure session (existing or new X3DH bootstrap)
 -> encrypt plaintext using CryptoService + chain counter
 -> build envelope DTO (payloadB64 + metadata)
 -> POST /v1/messages/send
 -> replace local sending bubble with sent message
```

## Silent retry logic
`ChatViewModel` retries failed send once with ~600ms backoff before marking message failed. Failed messages can be retried by user tap.

## Receive pipeline (network mode)
```text
GET /v1/messages/inbox -> [InboxEnvelopeDTO]
 -> NetworkChatRepository.ingestIncoming
 -> dedupe by serverMessageId
 -> decrypt via session + CryptoService
 -> append message to local chat store
 -> return ackIds
 -> POST /v1/messages/ack
 -> UI refreshes from repository state
```

## Session dependency
Outgoing send path lazily establishes session by fetching remote prekeys (`PreKeysService.fetch`) and calling `SessionManager.establishSessionAsInitiator`.

## Mock + network roles
- Mock repo: deterministic chat seeds, deterministic first-fail send scenario for retry UX, local fake remote key managers.
- Network repo: real prekey fetch, payload envelope send, incoming ingest+ack, server dedupe.

## **WIP notes**
- Persistent encrypted message store is not implemented (in-memory dictionary store in repositories).
- Full Double Ratchet evolution is not complete.

## Key references
- `Veil/Chats/View/ChatView.swift`
- `Veil/Chats/ViewModel/ChatViewModel.swift`
- `Veil/Chats/Repository/ChatRepository.swift`
- `Veil/Networking/Repositories/NetworkChatRepository.swift`
- `Veil/Networking/DTO/WireDTOs.swift`

## Messaging diagrams
See `docs/DIAGRAMS.md` for message send/receive pipelines, message requests flow, and polling + push hybrid delivery diagrams.

