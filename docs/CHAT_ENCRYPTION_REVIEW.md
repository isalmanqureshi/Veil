# Chat Feature Encryption Review

## Scope reviewed

- `Veil/CryptoService.swift`
- `Veil/Chats/Repository/ChatRepository.swift`
- `Veil/Chats/ViewModel/ChatViewModel.swift`
- `Veil/Chats/Model/ChatMessage.swift`
- `Veil/Chats/View/ChatView.swift`

## Current encryption design (as implemented)

1. `ChatViewModel.sendTapped()` captures trimmed plaintext from the composer, inserts a local placeholder message (`ciphertext: "encrypting…"`), and asynchronously delegates send to the repository.
2. `MockChatRepository.sendMessage(...)` performs encryption via dependency-injected `CryptoService` before persisting to in-memory message store.
3. `MockCryptoService.encrypt(...)` is currently a deterministic mock transform (`enc(<recipient>):<reversed plaintext>`), not cryptographic encryption.
4. Message model stores only `ciphertext` in `ChatMessage`.
5. Attachment path is scaffolded (size check -> metadata strip -> encrypt -> upload), but currently implemented as no-op stubs.

## Security and privacy assessment

### What is good already

- **Encryption boundary is centralized** in repository/service layers rather than in views, which is a clean separation for future real crypto integration.
- **Dependency injection for crypto** (`MockChatRepository` takes `CryptoService`) makes replacement with a real implementation straightforward.
- **Ciphertext-only message field** in `ChatMessage` encourages avoiding plaintext retention in message history objects.

### Gaps / risks

1. **No real cryptography yet**
   - Current implementation is reversible string manipulation.
   - No confidentiality guarantees.

2. **No integrity/authenticity protection**
   - No signatures/MAC/AEAD tag validation path.
   - Messages can be tampered with in transit/storage in this mock model.

3. **No key management model in chat send path**
   - No per-device identity keys, session keys, prekeys, rotation, or trust state checks before encrypting.

4. **Retry flow drops original plaintext**
   - `retryFailed` re-sends `"(retry)"` instead of original message content.
   - This is functionally incorrect and can obscure what data was actually encrypted/sent.

5. **Attachment encryption is not enforced**
   - Attachment service methods currently return unchanged input and mock upload URL.
   - No metadata stripping or content encryption is currently effective.

6. **Ciphertext visible directly in UI previews/lists**
   - `listChats()` uses `last.ciphertext` for `lastPreview`, which is okay for mock but not ideal UX once real encrypted payload format is used.

## Recommended next steps

1. **Introduce a production `CryptoService`**
   - Use authenticated encryption (AEAD) with random nonce per message.
   - Return an encoded envelope (version, key id/session id, nonce, ciphertext, auth tag).

2. **Define message envelope model**
   - Replace plain `String ciphertext` with a structured payload (or canonical serialized envelope).
   - Include algorithm/version metadata for migration safety.

3. **Add key/session management integration**
   - Resolve recipient/device session before encrypting.
   - Fail closed (do not send plaintext fallback) when trust/session is unavailable.

4. **Fix retry semantics**
   - Persist ephemeral outgoing draft plaintext securely until send success/final failure, or re-encrypt from protected local draft.
   - Ensure retry sends same user-authored content.

5. **Implement real attachment pipeline**
   - Enforce max size checks.
   - Strip metadata for supported media.
   - Encrypt binary locally, upload encrypted bytes only.
   - Send message referencing encrypted object descriptor.

6. **Add tests around encryption contracts**
   - Unit tests for:
     - repository always encrypts before persistence,
     - retries preserve message content,
     - plaintext never appears in stored/surfaced message payloads.

## Reviewer conclusion

The current chat encryption path is a **well-structured mock scaffold** with good dependency boundaries, but it is **not cryptographically secure yet** and should be treated as pre-production. Priority should be to ship authenticated encryption + key/session management and to fix retry/content integrity behavior before considering the feature secure.
