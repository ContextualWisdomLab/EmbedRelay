# EmbedRelay UML and Runtime Views

**Status:** Accepted target views; current M1 as-built behavior is marked separately.  
**Last reviewed:** 2026-08-15

## Current M1 registration sequence

```mermaid
sequenceDiagram
    actor Client
    participant Registry as TenantSpaceRegistry
    participant Manifest as Space Manifest
    participant Audit as AuditSink

    Client->>Manifest: canonical manifest
    Manifest-->>Client: embedding-space fingerprint
    Client->>Registry: register(tenant_id, manifest)
    Registry->>Registry: validate UUIDv7 + canonical fingerprint
    Registry->>Registry: reject duplicate tenant/space before audit intent
    Registry->>Audit: space_registration_intent
    alt audit accepted
        Audit-->>Registry: accepted
        Registry->>Registry: make registration observable
        Registry-->>Client: registration
    else audit rejected
        Audit-->>Registry: rejected
        Registry-->>Client: error; state unchanged
    end
```

## Target adapter training sequence

```mermaid
sequenceDiagram
    actor Operator
    participant Registry as Space/Adapter Registry
    participant Anchor as Anchor Evidence
    participant Forge as Adapter Forge
    participant CPU as CPU Reference
    participant GPU as GPU Backend
    participant Bench as Fidelity Bench

    Operator->>Registry: request source→target candidate (input_role=query or document, target_role=legacy_document)
    Registry->>Anchor: resolve authorized paired evidence
    Anchor-->>Forge: train/eval split + provenance
    Forge->>CPU: fit/reference metrics
    opt computationally material GPU path
        Forge->>GPU: fit batched kernel
        GPU-->>CPU: parity evidence
    end
    Forge->>Bench: immutable candidate artifact
    Bench->>Bench: vector + retrieval + OOD + calibration
    Bench-->>Registry: evaluation evidence
    Registry-->>Operator: approve/abstain/reject decision candidate
```

## Target query routing sequence

```mermaid
sequenceDiagram
    actor Client
    participant Encoder as Target Encoder
    participant Validator as Vector Validator
    participant Gateway as Translation Gateway
    participant Gate as Confidence Gate
    participant Target as Target Native Index
    participant Legacy as Legacy Index
    participant Fusion as Rank Fusion/Reranker

    Client->>Encoder: query text
    Encoder-->>Validator: target-space query vector
    Validator-->>Gateway: validated target vector + space id
    par target path
        Gateway->>Target: native target query
        Target-->>Fusion: ranked target results
    and legacy bridge path
        Gateway->>Gate: target→legacy adapter (input_role=query, target_role=legacy_document) + confidence
        alt eligible
            Gate-->>Gateway: translated legacy-space query
            Gateway->>Legacy: legacy query
            Legacy-->>Fusion: ranked legacy results
        else abstain
            Gate-->>Fusion: no legacy result + reason
        end
    end
    Fusion-->>Client: fused results + provenance/origin
```

## Migration state machine

```mermaid
stateDiagram-v2
    [*] --> planned
    planned --> evaluated
    evaluated --> rejected: fidelity/security insufficient
    evaluated --> dual_index: accepted bridge
    dual_index --> canary
    canary --> dual_index: rollback
    canary --> progressive_cutover
    progressive_cutover --> dual_index: rollback
    progressive_cutover --> target_primary
    target_primary --> native_backfill
    native_backfill --> source_retention_window
    source_retention_window --> completed
    rejected --> [*]
    completed --> [*]
```

## Authority flow

```mermaid
flowchart LR
    TENANT[Tenant operator / service identity]
    POLICY[Authorization + policy]
    REG[Space/adapter/migration control]
    COMPUTE[Deterministic/statistical compute]
    AUDIT[Append-only audit]
    ROUTER[Data-plane router]
    STORES[(Vector stores)]

    TENANT --> POLICY
    POLICY --> REG
    REG --> AUDIT
    REG --> COMPUTE
    COMPUTE --> REG
    REG --> ROUTER
    ROUTER --> STORES
```

Vector contents, UUID timestamps, model names, and fingerprints never create authority. Authorization and tenant membership are explicit policy inputs.

## Target deployment view

```mermaid
flowchart TB
    subgraph standalone[Standalone deployment]
        API[EmbedRelay API/control service]
        WORKER[Compute/backfill workers]
        PG[(PostgreSQL control plane)]
        OBJ[(Artifact store/KMS)]
        API --> PG
        WORKER --> PG
        WORKER --> OBJ
    end

    subgraph external[External provider-neutral ports]
        ENC[Embedding providers]
        VDB[Vector stores]
        OBS[Telemetry/audit sinks]
    end

    API --> ENC
    API --> VDB
    WORKER --> ENC
    WORKER --> VDB
    API --> OBS
    WORKER --> OBS
```

Current PR #1 has no deployable API, PostgreSQL control plane, vector-store connector, provider connector, or compute worker; this deployment view is target architecture.

## Maturity rule

Diagrams labelled target must not be used as evidence that the named service/database/adapter exists. When a target component becomes as-built, update these views, PRD/TRD, ERD, ADR status, tests, operability, and traceability in the implementing change.
