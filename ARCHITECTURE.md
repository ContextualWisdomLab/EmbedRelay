# EmbedRelay Architecture

**Status:** Accepted target architecture; current M1 active-PR scope is explicitly labelled.  
**Last reviewed:** 2026-09-02

## Architectural goal

EmbedRelay is embedding continuity infrastructure, not an embedding provider and not a vector database. It sits between encoders, vector stores, migration operators, and retrieval clients to prevent incompatible-space comparison and to manage measurable, reversible migration toward a target-native state.

## Product planes

```mermaid
flowchart LR
    subgraph clients[Clients]
        Q[Query/RAG client]
        OP[Operator/control client]
    end

    subgraph control[Control plane]
        SR[Space Registry]
        AR[Adapter Registry]
        MC[Migration Control]
        CG[Confidence Policy]
        AU[Audit/Policy]
    end

    subgraph compute[Compute plane]
        AF[Adapter Forge]
        FB[Fidelity Bench]
        CPU[CPU reference]
        GPU[GPU backend]
    end

    subgraph data[Data plane]
        VV[Vector Validator]
        TG[Translation Gateway]
        IR[Dual-Index Router]
        BF[Native Backfill]
    end

    subgraph ports[Provider-neutral ports]
        EP[Embedding providers]
        VS[Vector stores]
        OS[Artifact/KMS/Object store]
        OT[Telemetry]
    end

    OP --> SR
    OP --> AR
    OP --> MC
    SR --> AU
    AR --> AU
    MC --> AU
    AF --> CPU
    AF --> GPU
    AF --> FB
    FB --> AR
    Q --> VV
    VV --> TG
    TG --> CG
    CG --> IR
    IR --> VS
    BF --> EP
    BF --> VS
    SR --> TG
    AR --> TG
    MC --> IR
    AR --> OS
    AU --> OT
```

## Current M1 active-PR boundary

PR #1 now contains two coupled implementation layers:

1. a Rust domain-contract crate implementing canonical embedding-space identity, fail-closed vector validation, RFC 9562 UUIDv7 identifier semantics, tenant-isolated reference registration, and audit-before-mutation intent behavior; and
2. a narrow PostgreSQL 18.x persistence slice implementing tenant/fingerprint registration, durable `space_registration_intent` audit, forced RLS, append-only durability, deterministic duplicate/concurrent rejection, and guarded rollback.

The PostgreSQL slice is active-PR source only, not protected-main or release evidence. Full immutable canonical-manifest persistence, deployable service/API, adapter fitting/evaluation, artifact loading, confidence policy, translation gateway, dual-index routing, native backfill, provider/vector-store ports, broader service/admin roles, backup/restore acceptance, and GPU compute remain incomplete or planned.

```mermaid
flowchart LR
    MAN[EmbeddingSpaceManifest]
    FP[canonical fingerprint]
    V[ValidatedVector]
    ID[RelayIdentifier UUIDv7]
    REG[SpaceRegistry domain boundary]
    DB[(tenant_space_registry)]
    AUD[(space_registration_audit)]

    MAN --> FP
    FP --> V
    ID --> REG
    FP --> REG
    REG -->|transactional registration| AUD
    AUD -->|deferred reference requires row at commit| DB
```

The persistence transaction boundary is one tenant/fingerprint registration attempt. Audit intent is inserted first; registration follows in the same transaction. Duplicate same-item registration is deliberately rejected by the unique `(tenant_id, space_fingerprint)` key and rolls the attempted audit insert back. This is not an implicit UPSERT contract.

## Domain boundaries

### Core subdomain — Embedding Continuity

Owns canonical space identity, compatibility, directional adapter fidelity, abstention, migration correctness, and target-native convergence.

### Supporting subdomain — Registry Governance

Owns tenant-scoped immutable registration, durable audit, drift quarantine, and release evidence. The active M1 PostgreSQL slice belongs here.

### Supporting subdomain — Migration Operations

Owns dual-index state, rollback windows, migration stages, and native-backfill progress. It remains planned.

### Generic integration subdomain

Provider, vector-store, object-store/KMS, telemetry, and identity integrations remain versioned ports behind anti-corruption layers. Vendor SDK types and another ContextualWisdomLab repository's private database model are not shared-kernel contracts.

## Trust boundaries

1. **Vector input boundary:** vectors and manifests are untrusted until space and numeric validation passes.
2. **Tenant authority boundary:** tenant authorization is explicit; UUID/fingerprint/vector content never proves tenancy. Current M1 PostgreSQL tables force RLS against explicit `embedrelay.tenant_id` session context.
3. **Persistence mutation boundary:** registry/audit rows are append-only; destructive rollback is a separately gated operator migration action.
4. **Adapter artifact boundary:** weights/manifests are immutable, digest-bound, signed/reviewed artifacts before production use.
5. **Provider boundary:** provider responses are revalidated for dimension/space contract; model names are not trusted identities.
6. **Vector-store boundary:** score semantics are space/index-specific; the router combines ranks/results, not raw incompatible scores by default.
7. **Automation/release boundary:** model development/review credentials remain separate from protected merge/release authority.

## Space registry

The Rust reference registry proves the domain behavior for `(tenant_id, canonical_fingerprint)` registration and audit-before-visibility semantics. The active PostgreSQL implementation persists the narrow tenant/fingerprint registration and audit intent using descriptive multi-word `snake_case` objects under `embedrelay_registry`.

The physical M1 slice does not yet persist the complete canonical manifest. That follow-up must preserve one canonical versioned source of compatibility truth rather than duplicating mutable fields across relations. If output drift is detected under the same provider/model label, the existing space identity is not mutated; a new or quarantined identity is required.

## Persistence architecture

Current active-PR physical objects:

- `tenant_space_registry` — immutable per-tenant fingerprint registration, PostgreSQL UUIDv7 record ID, unique tenant/fingerprint key;
- `space_registration_audit` — append-only audit intent, PostgreSQL UUIDv7 event ID, actor/action/evidence key;
- `register_tenant_space(uuid, text)` — one-item transactional command;
- forced RLS on both tables;
- update/delete/truncate rejection triggers;
- guarded destructive down migration.

The slice is in 3NF and has no global application lock. Contention is localized to the tenant/fingerprint uniqueness key. No partitioning, read/write split, replica topology, or CQRS is claimed without measured pressure. The database is an internal persistence boundary and is not a public integration surface for downstream repositories.

Broader target persistence still includes immutable canonical manifests, adapter/evaluation artifacts, vector references, migration plans/stages, index bindings, backfill tasks, drift events, policy decisions, and broader audit/provenance records.

## Adapter lifecycle

```text
candidate
→ training
→ evaluated
→ calibrated
→ approved
→ active
→ deprecated
→ retired
```

Rejection or abstention is a normal state. A production adapter references immutable source/target spaces, role, algorithm/version, training/evaluation provenance, artifact digest, confidence policy, and release evidence.

## Migration lifecycle

```text
planned
→ shadow / evaluation
→ dual-index
→ bounded canary
→ progressive cutover
→ target-primary
→ native-backfill-complete
→ source-retained-for-rollback-window
→ completed
```

Rollback remains available until explicit acceptance criteria and retention policy retire the source path.

## Compute architecture

Production arithmetic is Rust-first. CPU is the numerical correctness reference. GPU is introduced only for computationally material workloads after profiling; all GPU outputs require parity/recovery evidence. Transfer overhead, peak VRAM, batch adaptation, precision mode, kernel/runtime version, and fallback cause are observable.

## Provider/vector-store neutrality

Ports expose versioned capabilities such as encode query/document, batch encode, create/read/write index vector, query index, and retrieve source content for native backfill. Core domain code may not import vendor SDK types.

## ContextualWisdomLab ecosystem boundary

- contextual-orchestrator may route model/provider calls but is optional and separately deployable;
- pg-llm-batch may provide batch orchestration through a typed adapter;
- EgressWeave may enforce approved outbound-provider policy;
- Keyverse may provide identity/federation at a service wrapper;
- naruon may consume migration/retrieval capabilities through a public API/SDK;
- no integration requires direct access to another service's private database.

## Release architecture

A released version requires immutable source, exact CI/security/review evidence, locked/reproducible dependencies, exact coverage/docstrings, PostgreSQL migration/RLS/concurrency/rollback verification for the persisted M1 surface, measured recovery evidence appropriate to production persistence, SBOM/provenance, signed adapter/release artifacts where applicable, retrieval-level fidelity gates for adapter/migration capabilities, and post-publication smoke evidence. A model or autonomous agent cannot independently approve its own numerical cutover or release.
