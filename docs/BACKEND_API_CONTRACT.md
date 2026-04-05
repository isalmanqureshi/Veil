# Backend API Contract

## Status
- Implemented:
  - Client-side DTOs and service calls for users, prekeys, messages, requests, and push token registration.
- WIP:
  - Metadata-hardening policy completeness and deployment-level backend guarantees.
- Planned:
  - Operational hardening and final contract governance/versioning.


> Client service paths currently include `/v1/...`. Endpoint names below are shown both in requested canonical form and actual client path.

## Users and prekeys

### POST /users/register  (client: `POST /v1/users/register`)
Registers username + device + identity material.

Request fields:
- `username`, `deviceId`
- `identitySigningPublicKeyB64`
- `identityAgreementPublicKeyB64`
- `signedPreKeyId`, `signedPreKeyPublicKeyB64`, `signedPreKeySignatureB64`
- `oneTimePreKeys[]`

Response:
- `username`
- `registered: Bool`

### POST /prekeys/publish (client: `POST /v1/prekeys/publish`)
Publishes refreshed signed prekey + one-time prekeys.

### GET /prekeys/:username (client: `GET /v1/prekeys/{username}`)
Fetches remote prekey bundle for initiating session.

## Messaging

### POST /messages/send (client: `POST /v1/messages/send`)
Sends encrypted envelope.

Request includes:
- `fromUsername`, `toUsername`, `deviceId`
- `payloadB64` (**encrypted payload**)
- `envelopeVersion`
- `oneTimePreKeyId?`
- `timer?`
- `clientMessageId`

Response:
- `accepted`
- `serverMessageId`

### GET /messages/inbox (client: `GET /v1/messages/inbox?username&deviceId`)
Returns inbox envelopes for the device.

### POST /messages/ack (client: `POST /v1/messages/ack`)
Acknowledges processed `serverMessageId`s.

## Requests

### GET /requests (client: `GET /v1/requests?username=`)
Loads pending message requests.

### POST /requests/accept (client: `POST /v1/requests/accept`)
Accepts a request thread.

### POST /requests/block (client: `POST /v1/requests/block`)
Blocks requester and removes pending request.

### POST /requests/report (client: `POST /v1/requests/report`)
Reports sender with reason.

### Additional implemented endpoint
- `POST /requests/ignore` (client: `POST /v1/requests/ignore`) is implemented in app services/repositories.

## Push token registration
- `POST /v1/push/register` with username/device/token/platform.

## Encrypted vs visible data
Encrypted:
- message body in `payloadB64`

Visible metadata (necessary routing/control plane):
- sender/recipient usernames
- deviceId
- envelope version, timers, message ids
- queue timestamps

## Metadata minimization notes
- Request risk UI avoids exposing detailed sender telemetry.
- Debug logging redacts `payloadB64` and preview ciphertext in HTTP logs.
- Full metadata-hardening strategy is **WIP** and depends on backend policy.

## Key references
- `Veil/Networking/Services/BackendServices.swift`
- `Veil/Networking/DTO/WireDTOs.swift`
- `Veil/Networking/HTTPClient.swift`
