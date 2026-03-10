# Inbox and Requests

## Inbox architecture
Primary inbox surface is segmented:
- **Chats** tab (`ChatThread` list)
- **Requests** tab (`MessageRequestThread` list)

Key UI files:
- `InboxView.swift`
- `ChatRow.swift`
- `RequestRowSummary.swift`
- `RequestDetailsView.swift`

State manager:
- `InboxViewModel` loads chats from `ChatRepository` and requests from `MessageRequestsRepository`.

## Request model
`MessageRequestThread` contains:
- sender username
- preview ciphertext text
- creation date
- `RequestSignals` (PoW/rate-limit/first-contact/confidence note)

## Request flows
### Accept flow
`RequestDetailsView` -> `requestsRepo.accept(requestId)` -> removes request and (network mode) ensures chat exists -> navigates to chat.

### Ignore flow
`requestsRepo.ignore(requestId)` -> removes request locally and (network mode) posts ignore.

### Block flow
`requestsRepo.block(requestId)` -> removes request and blocks sender path on backend implementation.

### Report flow
Shows a report sheet, sends reason through `requestsRepo.report`, removes request, and pushes trust warning confirmation.

## Abuse resistance integration in requests UI
`RequestSignalsFormatter` renders calm risk context:
- PoW verified/required labels
- rate-limited/throttled labels
- optional confidence note override

Design intent: communicate protective signals without exposing unnecessary sender metadata.

## Mock and network repository behavior
- `MockMessageRequestsRepository` includes deterministic seeded request examples + local block/report behaviors.
- `NetworkMessageRequestsRepository` syncs request list with backend and maps wire DTO signals into domain model.

## Key references
- `Veil/Inbox/InboxView.swift`
- `Veil/Inbox/ViewModel/InboxViewModel.swift`
- `Veil/Inbox/Views/RequestDetailsView.swift`
- `Veil/Chats/Model/MessageRequestThread.swift`
- `Veil/Networking/Repositories/NetworkMessageRequestsRepository.swift`
