# Veil Backend Documentation

Veil's backend is intentionally minimal and privacy-preserving. Its job is infrastructure coordination, not content inspection.

Core responsibilities:

- user registration
- prekey publishing and retrieval
- message relay and inbox queueing
- message request queue and moderation actions
- client polling endpoints
- abuse-resistance signals and controls
- push notification trigger surface

No plaintext message content is required for normal server operation; encrypted payloads are relayed as opaque ciphertext with minimal routing metadata.

> **Current state:** this repository contains the iOS client and shared backend-contract documentation. Backend design docs are currently split between `/docs` and planned backend-specific documents listed below.

## Backend Architecture

- [Backend relay architecture expected by iOS](../docs/DIAGRAMS.md#12-backend-architecture-expected-by-ios-app)
- [High-level system architecture](../docs/DIAGRAMS.md#1-high-level-system-architecture)
- [Stateless relay architecture](./architecture.md) *(Planned)*
- [API gateway / service edge model](./api-gateway.md) *(Planned)*

## API Contract

- [Backend API Contract](../docs/BACKEND_API_CONTRACT.md)
- [User registration](../docs/BACKEND_API_CONTRACT.md#users-and-prekeys)
- [Prekey publishing](../docs/BACKEND_API_CONTRACT.md#users-and-prekeys)
- [Message sending](../docs/BACKEND_API_CONTRACT.md#messaging)
- [Message polling](../docs/BACKEND_API_CONTRACT.md#messaging)
- [Message requests](../docs/BACKEND_API_CONTRACT.md#requests)

## Encryption Model

- [X3DH-style handshake + session establishment](../docs/CRYPTOGRAPHY.md#session-establishment-sessionmanager)
- [Message encryption (AES-GCM payloads)](../docs/CRYPTOGRAPHY.md#cryptographic-primitives-in-code)
- [Session establishment flow diagram](../docs/DIAGRAMS.md#5-x3dh-style-session-establishment)
- [Backend encryption model](./encryption-model.md) *(Planned)*

## Message Relay

- [Messaging relay flow from client perspective](../docs/MESSAGING_SYSTEM.md#send-pipeline)
- [Encrypted vs visible transport fields](../docs/BACKEND_API_CONTRACT.md#encrypted-vs-visible-data)
- [Sealed sender design](./sealed-sender.md) *(Planned)*

## Prekey Service

- [Prekey contract](../docs/BACKEND_API_CONTRACT.md#users-and-prekeys)
- [Client prekey lifecycle diagram](../docs/DIAGRAMS.md#9-prekey-management-lifecycle)
- [Prekey depletion handling](./prekey-service.md) *(Planned)*

## Abuse Protection

- [Abuse resistance model](../docs/ABUSE_RESISTANCE.md)
- [Message request filtering model](../docs/INBOX_AND_REQUESTS.md#request-model)
- [Rate limits and proof-of-work signals](../docs/ABUSE_RESISTANCE.md#proof-of-work-and-rate-limiting-status)
- [Backend abuse policy and enforcement](./abuse-protection.md) *(Planned)*

## Polling System

- [Polling and push hybrid design](../docs/POLLING_AND_PUSH_DESIGN.md)
- [Message receive pipeline (polling) diagram](../docs/DIAGRAMS.md#7-message-receive-pipeline-polling)
- [Queue internals](./message-queue.md) *(Planned)*

## Push Notification Design

- [Push-ready architecture](../docs/POLLING_AND_PUSH_DESIGN.md#push-ready-architecture)
- [Metadata-minimized push payload direction](../docs/POLLING_AND_PUSH_DESIGN.md#future-push-payload-design)
- [Polling + push hybrid diagram](../docs/DIAGRAMS.md#10-polling--push-hybrid-delivery)

## Database Schema

- [Database schema overview](./database-schema.md) *(Planned)*
- [`users` table](./database-schema.md#users-table) *(Planned)*
- [`prekeys` table](./database-schema.md#prekeys-table) *(Planned)*
- [`messages` table](./database-schema.md#messages-table) *(Planned)*
- [`message_requests` table](./database-schema.md#message_requests-table) *(Planned)*

## Deployment

- [Node service deployment model](./deployment.md) *(Planned)*
- [Database topology](./deployment.md#database-topology) *(Planned)*
- [Horizontal scaling model](./deployment.md#horizontal-scaling) *(Planned)*

## Security Principles

- [No phone numbers identity model](../docs/ONBOARDING_AND_AUTH.md#identity-model)
- [No tracking / privacy-first product stance](../docs/README.md)
- [Metadata minimization references](../docs/BACKEND_API_CONTRACT.md#metadata-minimization-notes)
- [Trust center and security UX surfaces](../docs/TRUST_CENTER.md)
