# Veil iOS Client Documentation

Veil is a privacy-first iOS messaging application built around **username identity** (no phone numbers), **end-to-end encrypted messaging**, and **metadata minimization**. The client architecture is Signal-inspired, with X3DH-style session bootstrap today and Double Ratchet hardening planned.

Use this page as the primary entry point for client architecture, cryptography, messaging, and product-system documentation.

## Architecture Overview

- [iOS App Architecture](./ARCHITECTURE.md)
- [Coordinator Navigation System](./ARCHITECTURE.md#coordinator-navigation)
- [Dependency Injection (`AppEnvironment`)](./ARCHITECTURE.md#dependency-injection-via-appenvironment)
- [Repository Pattern](./ARCHITECTURE.md#repository-pattern)
- [System Architecture Diagrams](./DIAGRAMS.md#1-high-level-system-architecture)

## Authentication & Identity

- [Username Identity Model](./ONBOARDING_AND_AUTH.md#identity-model)
- [Password + Recovery Key System](./ONBOARDING_AND_AUTH.md#recovery-key-system)
- [Onboarding Flow](./ONBOARDING_AND_AUTH.md#flow-overview)
- [Sign Out vs Remove Account From Device](./ONBOARDING_AND_AUTH.md#sign-out-vs-erase-local-data)

## Cryptography

- [Cryptography Overview](./CRYPTOGRAPHY.md)
- [KeyManager + Identity Keys](./CRYPTOGRAPHY.md#identity-keys)
- [Signed + One-Time Prekeys](./CRYPTOGRAPHY.md#prekeys)
- [Session Establishment](./CRYPTOGRAPHY.md#session-establishment-sessionmanager)
- [Message Encryption Pipeline](./CRYPTOGRAPHY.md#message-encryption-pipeline)
- [Session Establishment Diagram](./DIAGRAMS.md#5-x3dh-style-session-establishment)

## Messaging

- [Messaging System Architecture](./MESSAGING_SYSTEM.md)
- [Message Sending Pipeline](./MESSAGING_SYSTEM.md#send-pipeline)
- [Disappearing Messages / Timer UX](./MESSAGING_SYSTEM.md) *(Partially documented)*
- [Attachment Pipeline](./ATTACHMENTS.md)
- [Messaging Pipeline Diagrams](./DIAGRAMS.md#6-message-send-pipeline)

## Inbox System

- [Inbox and Requests Architecture](./INBOX_AND_REQUESTS.md)
- [Chat Threads and Inbox Model](./INBOX_AND_REQUESTS.md#inbox-architecture)
- [Message Requests Flow](./INBOX_AND_REQUESTS.md#request-flows)
- [Abuse-Resistant Requests Design](./DIAGRAMS.md#8-message-requests-flow-abuse-resistant)

## Privacy & Security

- [Trust Center](./TRUST_CENTER.md)
- [Abuse Resistance](./ABUSE_RESISTANCE.md)
- [Encryption Review](./CHAT_ENCRYPTION_REVIEW.md)
- [Metadata Minimization + Encrypted/Visible Fields](./BACKEND_API_CONTRACT.md#encrypted-vs-visible-data)
- [Screenshot Detection](./TRUST_CENTER.md) *(Planned — not yet documented as a dedicated design section)*
- [Security Boundary Diagram](./DIAGRAMS.md#13-security-architecture-and-cryptographic-boundaries)

## Backend Integration

- [Backend API Contract](./BACKEND_API_CONTRACT.md)
- [Polling Architecture + Push Bridge](./POLLING_AND_PUSH_DESIGN.md)
- [Backend Relay Architecture Diagram](./DIAGRAMS.md#12-backend-architecture-expected-by-ios-app)

## Monetization

- [Pricing Model](./PRICING_AND_BUSINESS_MODEL.md)
- [Subscription Gating + Entitlement Checks](./PRICING_AND_BUSINESS_MODEL.md#entitlement-evaluation)

## Roadmap

- [Roadmap](./ROADMAP.md)
- [Double Ratchet Implementation](./ROADMAP.md#planned)
- [APNs Push Delivery Hardening](./ROADMAP.md#planned)
- [Group Encryption](./ROADMAP.md#planned)
- [Encrypted Storage](./DATA_STORAGE.md#planned-encrypted-storage-options)

## Full Documentation Catalog

- [Architecture](./ARCHITECTURE.md)
- [Onboarding and Authentication](./ONBOARDING_AND_AUTH.md)
- [Cryptography](./CRYPTOGRAPHY.md)
- [Messaging System](./MESSAGING_SYSTEM.md)
- [Inbox and Requests](./INBOX_AND_REQUESTS.md)
- [Abuse Resistance](./ABUSE_RESISTANCE.md)
- [Trust Center](./TRUST_CENTER.md)
- [Backend API Contract](./BACKEND_API_CONTRACT.md)
- [Polling and Push Design](./POLLING_AND_PUSH_DESIGN.md)
- [Data Storage](./DATA_STORAGE.md)
- [Attachments](./ATTACHMENTS.md)
- [Pricing and Business Model](./PRICING_AND_BUSINESS_MODEL.md)
- [Roadmap](./ROADMAP.md)
- [Diagrams](./DIAGRAMS.md)
- [Chat Encryption Review](./CHAT_ENCRYPTION_REVIEW.md)
