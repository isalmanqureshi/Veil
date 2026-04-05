# Veil System Diagrams

This document centralizes architecture and flow diagrams for the Veil iOS app using Mermaid. Diagrams are based on the current repository implementation (SwiftUI app, repository/service networking, X3DH-style session bootstrap, password + recovery auth, polling + push refresh).

---

## 1) High-Level System Architecture

**Description**

This diagram shows the major runtime layers in Veil and their concrete components from the codebase. It reflects the `AppRootView` + `AppEnvironment` composition, repository/service boundaries, cryptographic managers, and backend API dependency.

```mermaid
flowchart TD
  subgraph UI[User Interface Layer]
    AppRoot[AppRootView]
    Screens[Welcome / Username / Recovery / Inbox / Chat]
    VM[ChatViewModel + InboxViewModel + AuthStore]
  end

  subgraph APP[Application Logic Layer]
    Coord[AppCoordinator + AppRoute]
    Env[AppEnvironment]
    Repos[ChatRepository + MessageRequestsRepository + AuthRepository]
    Poller[MessagePoller]
    PushCoord[PushNotificationCoordinator]
  end

  subgraph SEC[Security Layer]
    KM[KeyManager]
    SM[SessionManager]
    Crypto[AuthenticatedCryptoService]
    SessStore[SessionStore (InMemory) \n WIP: persistent encrypted store]
    KCS[KeychainStore]
  end

  subgraph NET[Networking Layer]
    HTTP[HTTPClient]
    UsersSvc[NetworkUsersService]
    PreKeysSvc[NetworkPreKeysService]
    MsgSvc[NetworkMessagesService]
    ReqSvc[NetworkRequestsService]
    PushSvc[NetworkDevicePushTokenService]
  end

  subgraph BE[Backend Services]
    API[Node API Layer]
    KeyDist[PreKey Distribution]
    MsgStore[Message Queue / Store]
    ReqModeration[Request Moderation]
    DB[(Database)]
    KeyStore[(Key Store)]
  end

  AppRoot --> Screens --> VM
  VM --> Coord
  AppRoot --> Env
  Env --> Repos
  Env --> Poller
  Env --> PushCoord

  Repos --> SM
  Repos --> Crypto
  SM --> KM
  SM --> SessStore
  KM --> KCS

  Repos --> HTTP
  Poller --> MsgSvc
  Poller --> ReqSvc
  HTTP --> UsersSvc
  HTTP --> PreKeysSvc
  HTTP --> MsgSvc
  HTTP --> ReqSvc
  HTTP --> PushSvc

  UsersSvc --> API
  PreKeysSvc --> KeyDist
  MsgSvc --> MsgStore
  ReqSvc --> ReqModeration
  PushSvc --> API
  API --> DB
  KeyDist --> KeyStore
```

---

## 2) Navigation Architecture

**Description**

Veil routes through a single `NavigationStack` in `AppRootView`, driven by `AppCoordinator.path` and `AppRoute`. Root content is state-based (`AuthStore.state`), while secondary screens are resolved in `routeView(for:)`.

```mermaid
flowchart TD
  App[VeilApp / AppRootView] --> Nav[NavigationStack(path: coordinator.path)]
  Nav --> Root{AuthStore.state}
  Root -->|signedOut| Welcome[WelcomeView]
  Root -->|onboarding| Username[UsernameCreationView]
  Root -->|requiresPasswordReset| ResetPassword[ResetPasswordView]
  Root -->|signedIn| Inbox[InboxView]

  App --> Coord[AppCoordinator]
  Coord --> Routes[AppRoute enum]
  Routes --> Dest[routeView(for: route)]

  Dest --> Login[LoginView]
  Dest --> Recovery[RecoveryKeyView]
  Dest --> RecoveryLogin[RecoveryLoginView]
  Dest --> Reset[ResetPasswordView]
  Dest --> Chat[ChatView]
  Dest --> RequestDetails[RequestDetailsView]
  Dest --> TrustWarn[TrustWarningView]
```

---

## 3) Authentication + Onboarding Flow

**Description**

The auth model supports password-first sign in with recovery-key fallback. Onboarding generates a recovery seed, bootstraps key material, sets password verifier, and syncs identity/prekeys.

```mermaid
sequenceDiagram
  participant U as User
  participant AS as AuthStore
  participant AR as AuthRepository
  participant PM as PasswordManager
  participant KM as KeyManager
  participant IS as IdentitySyncService
  participant BE as Backend

  U->>AS: startOnboarding()
  U->>AS: prepareRecoveryKeyIfNeeded()
  AS->>AR: prepareRecoveryKey()
  AR-->>AS: recoveryKey + seed
  U->>AS: finishOnboarding(username, password)
  AS->>AR: createUser(...)
  AS->>KM: bootstrapIdentityIfNeeded(seed)
  AS->>PM: setPassword(password)
  AS->>IS: sync(username, deviceId)
  IS->>BE: POST /v1/users/register + /v1/prekeys/publish
  AS-->>U: state = .signedIn

  U->>AS: login(username, password)
  AS->>PM: verifyPassword(password)
  AS-->>U: state = .signedIn

  U->>AS: recoverAccount(username, recoveryKey)
  AS->>AR: restoreUser(...)
  AS-->>U: state = .requiresPasswordReset
  U->>AS: resetPassword(newPassword)
  AS->>PM: setPassword(newPassword)
  AS-->>U: state = .signedIn
```

---

## 4) Account Controls: Sign Out vs Remove Account

**Description**

Settings exposes separate controls for ending a session versus destructive local-device wipe.

```mermaid
flowchart TD
  Privacy[PrivacyDashboardView] --> SignOut[Sign Out]
  Privacy --> Erase[Remove Account From Device]

  SignOut --> S1[AuthStore.signOut()]
  S1 --> S2[Clear session flag + volatile auth state]
  S2 --> S3[state = .signedOut]

  Erase --> E1[AuthStore.eraseLocalData()]
  E1 --> E2[LocalDataWiper.wipeAllLocalData()]
  E2 --> E3[authRepo.clear + password clear + key erase + push token clear]
  E3 --> E4[AuthStore.signOut() -> state = .signedOut]
```

---

## 5) X3DH-Style Session Establishment

**Description**

`SessionManager.establishSessionAsInitiator` verifies signed prekeys, performs X25519 DH computations, and derives root/send/receive chain keys. This is currently initiator-side and explicitly “X3DH-style”.

```mermaid
sequenceDiagram
  participant A as User A (initiator)
  participant SA as SessionManager A
  participant KA as KeyManager A
  participant B as Backend key distribution
  participant KB as User B PreKeyBundle

  A->>B: fetch /v1/prekeys/{username}
  B-->>A: IK_B + SPK_B(sig) + OTK_B?
  A->>SA: establishSessionAsInitiator(remoteBundle)
  SA->>SA: verify SPK_B signature w/ IK_sign_B
  SA->>KA: load IK_A (agreement private)
  SA->>SA: generate EK_A

  SA->>SA: DH1 = DH(IK_A, SPK_B)
  SA->>SA: DH2 = DH(EK_A, IK_B)
  SA->>SA: DH3 = DH(EK_A, SPK_B)
  SA->>SA: DH4 = DH(EK_A, OTK_B) (optional)

  SA->>SA: HKDF(ikm, info="veil.x3dh.v1")
  SA->>SA: derive rootKey + sendCK + recvCK
  SA-->>A: SessionState saved
```

---

## 6) Message Send Pipeline

**Description**

`ChatViewModel.sendMessage` performs optimistic UI update, delegates to repository, and retries once on transient failure. `NetworkChatRepository` ensures a session, encrypts with `CryptoService`, and sends envelope via `MessagesService`.

```mermaid
flowchart TD
  ChatView --> ChatVM[ChatViewModel]
  ChatVM -->|optimistic bubble| LocalUI[(UI message list)]
  ChatVM --> ChatRepo[NetworkChatRepository]
  ChatRepo --> SessMgr[SessionManager]
  SessMgr -->|if missing session| PreKeySvc[PreKeysService.fetch]
  ChatRepo --> Crypto[AuthenticatedCryptoService.encrypt]
  Crypto --> Envelope[payloadB64 + envelopeVersion + OTK id]
  Envelope --> MsgSvc[MessagesService.sendEnvelope]
  MsgSvc --> HTTP[HTTPClient]
  HTTP --> Backend[POST /v1/messages/send]
  Backend --> ChatRepo
  ChatRepo --> ChatVM
  ChatVM -->|mark sent / failed| LocalUI
```

---

## 7) Message Receive Pipeline (Polling)

**Description**

`MessagePoller` periodically polls inbox and requests in parallel. Incoming envelopes are decrypted via `NetworkChatRepository.ingestIncoming`; successful message IDs are acknowledged to backend.

```mermaid
sequenceDiagram
  participant P as MessagePoller
  participant MS as MessagesService
  participant RS as RequestsRepository
  participant BE as Backend
  participant CR as NetworkChatRepository
  participant SM as SessionManager
  participant C as CryptoService
  participant IVM as InboxViewModel/InboxView

  loop every pollIntervalSeconds
    P->>MS: pollInbox(username, deviceId)
    P->>RS: refresh()
    MS->>BE: GET /v1/messages/inbox
    BE-->>MS: InboxEnvelopeDTO[]
    MS-->>P: envelopes
    P->>CR: ingestIncoming(envelopes)
    CR->>SM: load session per sender
    CR->>C: decrypt(payloadB64)
    CR-->>P: ackIds[]
    P->>MS: ackMessages(ackIds)
    MS->>BE: POST /v1/messages/ack
    P-->>IVM: repositories now expose updated chats/requests
  end
```

---

## 8) Message Requests Flow (Abuse-Resistant)

**Description**

Unknown/first-contact traffic is represented as request threads. User actions in `RequestDetailsView` call `MessageRequestsRepository` APIs for accept/ignore/block/report.

```mermaid
flowchart TD
  Sender[Unknown Sender] --> Backend[Backend Requests Queue]
  Backend --> ReqRepo[NetworkMessageRequestsRepository]
  ReqRepo --> Inbox[InboxView Requests Tab]
  Inbox --> Details[RequestDetailsView]

  Details -->|Accept| Accept[requestsRepo.accept]
  Details -->|Ignore| Ignore[requestsRepo.ignore]
  Details -->|Block| Block[requestsRepo.block]
  Details -->|Report| Report[requestsRepo.report]

  Accept --> BackendAccept[POST /v1/requests/accept]
  Ignore --> BackendIgnore[POST /v1/requests/ignore]
  Block --> BackendBlock[POST /v1/requests/block]
  Report --> BackendReport[POST /v1/requests/report]

  Accept --> EnsureChat[chatRepo.ensureChatExists]
  Report --> Trust[TrustCenter warning event]
```

---

## 9) PreKey Management Lifecycle

**Description**

`PreKeySyncManager` keeps signed prekeys fresh and one-time prekeys above threshold, publishing refreshed bundles when rotation/replenishment occurs.

```mermaid
flowchart TD
  PKM[PreKeySyncManager] --> Auth[LocalAuthContext username/device]
  PKM --> KM[KeyManager]
  KM --> EnsureSPK[ensureSignedPreKey(maxAgeDays)]
  KM --> CountOTK[oneTimePreKeyCount()]
  CountOTK --> Replenish{count < minimum?}
  Replenish -->|yes| EnsureOTK[ensureOneTimePreKeys(targetCount)]
  Replenish -->|no| Skip[No OTK generation]

  EnsureSPK --> Bundle[makePreKeyBundle(oneTimeCount: target)]
  EnsureOTK --> Bundle
  Bundle --> DTO[PublishPreKeysRequestDTO]
  DTO --> PreSvc[PreKeysService.publish]
  PreSvc --> Backend[POST /v1/prekeys/publish]
```

---

## 9) Trust Center Verification Flow (WIP)

**Description**

Trust event plumbing exists (`TrustCenter`, warning routing), while full fingerprint/QR verification UX is still scaffolded (`IdentityVerificationView`).

```mermaid
flowchart TD
  subgraph Current[Implemented]
    Events[Trust events: screenshot / key change / block / report]
    TC[TrustCenter]
    Warn[TrustWarningView]
    Events --> TC --> Warn
  end

  subgraph WIP[WIP: Identity verification product flow]
    UserA[User A]
    UserB[User B]
    QR[QR scan / code compare]
    FP[Identity fingerprint verification]
    IV[IdentityVerificationView scaffold]
    UserA --> QR --> FP --> UserB
    FP --> IV
  end
```

---

## 10) Polling + Push Hybrid Delivery

**Description**

Push notifications are used as a wake-up signal; actual message retrieval still occurs through poll/refresh endpoints. APNs token registration is synced after sign-in.

```mermaid
sequenceDiagram
  participant APNs as APNs
  participant App as VeilAppDelegate
  participant PNC as PushNotificationCoordinator
  participant TS as PushTokenSyncService
  participant BE as Backend
  participant Env as AppEnvironment
  participant Poll as MessagePoller

  App->>PNC: requestAuthorization/registerForRemoteNotifications
  APNs-->>App: deviceToken
  App->>PNC: didRegisterForRemoteNotifications(token)
  PNC->>TS: updateToken(token)
  TS->>BE: POST /v1/push/register

  APNs-->>App: push notification payload
  App->>PNC: handleRemoteNotification(...)
  PNC->>Env: refreshHandler()
  Env->>Poll: refreshNow()
  Poll->>BE: GET /v1/messages/inbox (+ requests refresh)
  BE-->>Poll: envelopes/requests
```

---

## 11) Attachment Encryption Pipeline (WIP)

**Description**

Attachments are currently mock-first. `ChatViewModel.addAttachment` calls `AttachmentService.stripMetadata`, `encryptForUpload`, then `upload`. The default implementation (`MockAttachmentService`) is stubbed and returns mock URLs.

```mermaid
flowchart TD
  User[User selects file] --> ChatView
  ChatView --> VM[ChatViewModel.addAttachment]
  VM --> Validate[Size check vs maxBytes]
  Validate -->|ok| Strip[AttachmentService.stripMetadata]
  Strip --> Encrypt[AttachmentService.encryptForUpload]
  Encrypt --> Upload[AttachmentService.upload]
  Upload --> Ref[attachment://mock URL reference]
  Ref --> VMStatus["Attachment uploaded securely"]

  Upload -.WIP.- BackendBlob[(Encrypted blob storage)]
  Ref -.WIP.- MessageEnvelope[(Send encrypted attachment reference in message envelope)]
```

---

## 12) Backend Architecture Expected by iOS App

**Description**

This backend view is inferred from client DTOs/services and API contract documentation.

```mermaid
flowchart LR
  iOS[iOS Client]

  subgraph API[Node Server]
    UsersAPI[/Users + Registration API/]
    PreKeysAPI[/PreKeys API/]
    MsgAPI[/Messages API/]
    ReqAPI[/Requests Moderation API/]
    PushAPI[/Push Registration API/]
  end

  subgraph Core[Backend Core]
    MQ[(Message Queue)]
    DB[(Database)]
    KS[(Key Store)]
    PushWorker[Push dispatch worker]
  end

  iOS --> UsersAPI
  iOS --> PreKeysAPI
  iOS --> MsgAPI
  iOS --> ReqAPI
  iOS --> PushAPI

  UsersAPI --> DB
  PreKeysAPI --> KS
  MsgAPI --> MQ
  MsgAPI --> DB
  ReqAPI --> DB
  PushAPI --> DB
  MQ --> PushWorker
```

---

## 13) Security Architecture and Cryptographic Boundaries

**Description**

This diagram shows local secret boundaries, session/key derivation components, and transport boundary. Secure Enclave-backed key generation is not yet implemented and remains WIP.

```mermaid
flowchart TD
  subgraph Device[On-device security boundary]
    UI[UI + ViewModels]
    Auth[AuthStore]
    Keychain[KeychainStore]
    KM[KeyManager]
    SM[SessionManager]
    Crypto[AuthenticatedCryptoService]
    Sess[SessionStore InMemory\nWIP: encrypted persistence]
    Attach[AttachmentService\nWIP production implementation]
    Enclave[Secure Enclave\nWIP integration]
  end

  subgraph Transport[Network boundary]
    HTTP[HTTPClient]
    TLS[TLS channel]
  end

  subgraph Server[Backend trust boundary]
    APIs[Users/PreKeys/Messages/Requests API]
    Stored[(Encrypted payload + metadata)]
  end

  UI --> Auth
  Auth --> KM
  KM --> Keychain
  KM --> Enclave
  UI --> SM
  SM --> Sess
  UI --> Crypto
  SM --> Crypto
  UI --> Attach
  Crypto --> HTTP --> TLS --> APIs --> Stored
```
