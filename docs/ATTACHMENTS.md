# Attachments

## Status
- Implemented:
  - Attachment service abstractions and UI-level send scaffolding.
- WIP:
  - Real metadata stripping, encryption/upload/download backend integration.
- Planned:
  - Production encrypted attachment pipeline with durable reference storage.


## Current architecture status
Attachment support is scaffolded in `ChatViewModel` and `AttachmentService` abstractions, with mock behavior provided by `MockAttachmentService`.

This feature is currently **WIP** (no production backend upload pipeline or encrypted attachment retrieval flow yet).

## Intended upload flow
`ChatViewModel.addAttachment` enforces/implements this sequence:
1. Validate size (`attachment.bytes <= maxBytes`)
2. Strip metadata (`stripMetadata`) — intended EXIF removal
3. Encrypt locally (`encryptForUpload`)
4. Upload encrypted blob (`upload`)
5. Send message containing attachment reference (`attachment:<uploadRef>`)

## Metadata stripping
- Explicitly modeled as a first-class step.
- Current mock implementation is a no-op placeholder.

## Local encryption
- Explicit service step exists.
- Current mock implementation returns attachment unchanged.

## Message reference model
Attachment send currently appends a chat message with:
- `ciphertext`: `attachment:<uploadRef>`
- `plaintextPreview`: file name

This indicates an eventual content-addressed or URL-id attachment envelope model.

## Key references
- `Veil/Chats/ViewModel/ChatViewModel.swift`
- `Veil/CryptoService.swift` (`AttachmentService`, `MockAttachmentService`)
- `Veil/Chats/Model/ChatMessage.swift`
