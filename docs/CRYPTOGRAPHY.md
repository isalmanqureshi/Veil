# Cryptography

## Status
- Implemented:
  - Deterministic identity derivation, X3DH-style initiator handshake, AES-GCM payload encryption.
- WIP:
  - Full Double Ratchet DH-step evolution.
  - Persistent encrypted session/message storage.
- Planned:
  - Additional protocol hardening and external cryptographic review.


## Cryptographic primitives in code
- **Ed25519**: identity signing keys + signed prekey signatures
- **X25519**: identity agreement + prekeys + DH operations
- **HKDF-SHA256**: seed derivation and session key schedule
- **AES-256-GCM**: message payload encryption/decryption

## Identity keys
`KeyManager` maintains deterministic identity keys derived from recovery seed via HKDF:
- `veil.identity.ed25519` info label -> signing private key
- `veil.identity.x25519` info label -> agreement private key

These keys are stored in Keychain.

## Prekeys
`KeyManager` manages:
- Signed prekey (with timestamp + rotation support)
- One-time prekeys (indexed list + per-key private storage)

Signed prekey is Ed25519-signed over `(prekeyId || prekeyPublicKey)`.

## Session establishment (`SessionManager`)
Session establishment is **X3DH-style**.

### Initiator handshake
```text
Verify remote signed prekey signature
Generate ephemeral key EK_A
Load local identity agreement key IK_A

DH1 = DH(IK_A, SPK_B)
DH2 = DH(EK_A, IK_B)
DH3 = DH(EK_A, SPK_B)
DH4 = DH(EK_A, OTK_B) [optional]

IKM = DH1 || DH2 || DH3 || DH4
HKDF(ikm, info="veil.x3dh.v1") -> rootKey, sendCK, recvCK
```

## Message encryption pipeline
`AuthenticatedCryptoService` packet format:
```text
version(1 byte) || counter(4 bytes BE) || AES.GCM.combined(nonce+ciphertext+tag)
```
Then Base64 encoded for transport (`payloadB64`).

### Chain KDF
- `ChainKDF.deriveMessageKey(chainKey, counter, context)`
- `ChainKDF.advanceChainKey(chainKey, counter, context)`

Context strings:
- send: `veil.v1.send.<recipient>`
- recv: `veil.v1.recv.<recipient>`

### Ratchet direction / state
Current model is **single symmetric chain per direction**, not full Double Ratchet.
- `sendingChainKey`, `receivingChainKey`
- `sendCount`, `recvCount`
- `skippedMessageKeys` cache for controlled out-of-order delivery window

This is explicitly a staged design toward fuller ratcheting.

## Forward secrecy status
- Forward-secrecy-like properties from chain key advancement and one-time prekey usage are present.
- Full Double Ratchet with DH ratchet step is **WIP**.

## Session storage
`SessionStore` is currently `InMemorySessionStore` (volatile process memory). Persistent encrypted session storage is not yet implemented.

## Key references
- `Veil/Onboarding/Key/Managers/KeyManager.swift`
- `Veil/Onboarding/Key/Managers/SessionManager.swift`
- `Veil/Onboarding/Key/Managers/SessionStore.swift`
- `Veil/Onboarding/Key/Models/KeyModels.swift`
- `Veil/CryptoService.swift`

## Cryptography diagrams
See `docs/DIAGRAMS.md` for the X3DH-style session establishment, prekey lifecycle, trust verification (WIP), attachment encryption pipeline (WIP), and cryptographic boundary diagram.

