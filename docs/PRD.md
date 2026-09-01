# EmbedRelay Product Requirements Document

**Status:** Accepted product baseline; implementation maturity is tracked separately.  
**Product category:** Embedding Continuity Infrastructure  
**Last reviewed:** 2026-09-02

## 1. Product definition

EmbedRelay preserves retrieval continuity when embedding models, revisions, roles, preprocessing, normalization, dimensions, precision, or metric contracts change. It identifies incompatible embedding spaces, learns or registers fidelity-bounded **directional** adapters, operates controlled dual-index migration, abstains when confidence is insufficient, and converges to target-native embeddings as the terminal state.

The product does **not** claim a universal exact inverse between arbitrary embedding models. A translated vector is an approximation with measured fidelity and provenance, never a native target embedding by definition.

## 2. Buyer problem

Enterprise retrieval/RAG systems accumulate large vector corpora that can become expensive or impossible to re-embed immediately when a model is deprecated, revised, compromised, regionally unavailable, or replaced for quality/cost reasons. Equal dimensionality does not imply compatible vector geometry. Blindly comparing vectors from different spaces can silently corrupt retrieval.

EmbedRelay provides a governed migration bridge so operators can change models without treating incompatible vectors as interchangeable or forcing an all-at-once outage.

## 3. Primary users

- **Retrieval/platform engineer:** migrate models while keeping search operational.
- **AI/RAG platform owner:** quantify retrieval fidelity and rollback risk before cutover.
- **Data/security steward:** track tenant, vector, adapter, anchor, migration, and audit provenance.
- **SRE/operator:** run dual-index cutover/backfill with observable confidence, capacity, and rollback.

## 4. Product invariants

1. Raw vectors from different `embedding_space_id` values are never directly compared.
2. Equal dimensions never establish compatibility.
3. A→B and B→A are different directional artifacts.
4. Query and document adapters are distinct by default.
5. Cycle consistency is diagnostic/regularizing evidence, not proof of invertibility.
6. Raw cosine scores from different spaces are not averaged; multi-index combination defaults to rank-level fusion/reranking.
7. Production adapter chains are one hop by default.
8. Low-confidence translation abstains rather than fabricating compatibility.
9. Vector origin is explicit: `native`, `translated`, `reconstructed`, or `composed` where experimentally permitted.
10. Provider/model-name stability does not imply space stability; observed output drift creates a new/quarantined space identity.
11. Source collections remain available until cutover and rollback evidence are complete.
12. The desired terminal state is target-native backfill whenever source data and policy permit it.

## 5. Current M1 implementation maturity

PR #1 currently contains an active-PR Rust domain slice plus a narrow executable PostgreSQL registry/audit slice.

The Rust slice implements:

- canonical embedding-space fingerprints;
- fail-closed `float32` vector validation;
- metric operations only within identical canonical space identity;
- opaque RFC 9562 UUIDv7 identifiers;
- tenant-isolated registry semantics;
- audit-before-mutation `space_registration_intent` behavior;
- exact Rust line/region/function/branch coverage gates;
- reproducible dependency resolution through a tracked `Cargo.lock` and locked CI commands.

The PostgreSQL M1 slice implements on the active PR:

- `tenant_space_registry` and `space_registration_audit` physical relations;
- PostgreSQL 18 UUIDv7 identifiers;
- unique per-tenant space registration keyed by `(tenant_id, space_fingerprint)`;
- forced tenant RLS using explicit `embedrelay.tenant_id` session context;
- append-only update/delete/truncate denial;
- audit-first registration coupled transactionally to registry visibility with a deferred reference;
- deterministic duplicate/concurrent rejection rather than an implicit UPSERT;
- guarded destructive rollback and migration reapplication contracts;
- PostgreSQL 18.6 CI coverage for RLS, UUIDv7, immutability, concurrency, and rollback behavior.

These are active-PR source facts only. They are not protected-main or release evidence until the **current exact head** passes all required PostgreSQL/Rust/security/review gates and merges. M1 still lacks measured backup/restore acceptance and full immutable canonical-manifest persistence. Adapter training, confidence calibration, dual-index routing, migration orchestration, provider/vector-store ports, and release readiness remain later planned/partial capabilities.

## 6. Functional requirements

### PRD-FR-001 Space registry

Every embedding space SHALL be identified by a canonical fingerprint covering model/provider revision, input role, preprocessing, normalization, dimension, scalar precision, metric contract, and other material encoding parameters. Space identity must be immutable once referenced by vectors or adapters.

The current active-PR physical registry persists the tenant/fingerprint registration boundary only. Persisting the complete versioned canonical manifest without duplicating mutable compatibility facts remains an M1 follow-through requirement.

### PRD-FR-002 Vector safety

Vector ingestion SHALL fail closed on precision/dimension mismatch, NaN/infinity, invalid zero norm where the metric requires non-zero norm, and other numerically invalid representations. Metric operations SHALL require complete compatible space identity.

### PRD-FR-003 Directional adapter registry

Adapters SHALL record source space, target space, input role, algorithm family/version, training anchor provenance, evaluation evidence, confidence/calibration metadata, artifact digest/signature, and lifecycle state. Direction is never implicit.

### PRD-FR-004 Fidelity evaluation

Every production adapter SHALL be evaluated on held-out vector fidelity **and retrieval behavior**. Required evidence includes appropriate geometric error/alignment, retrieval Recall@k/NDCG/MRR where applicable, OOD performance, calibration, and uncertainty/abstention behavior. Vector similarity alone is insufficient for cutover.

### PRD-FR-005 Translation gateway

The data/query plane SHALL translate only when an eligible one-hop adapter exists, tenant and role authorization match, the vector passes source-space validation, and confidence policy allows the operation. Results must include origin and provenance.

### PRD-FR-006 Dual-index migration

A migration SHALL support source-native and target-native/translated index coexistence, rank-level fusion or approved reranking, phased traffic, rollback, and measurable cutover criteria.

### PRD-FR-007 Native backfill

The system SHALL prioritize target-native re-embedding based on risk, usage, uncertainty, and available source data until the migration reaches its approved terminal state. Translation is a bridge, not indefinite hidden technical debt.

### PRD-FR-008 Tenant isolation and audit

Registry, adapter, migration, evaluation, and audit state SHALL be tenant-scoped. Authorization may not be inferred from UUID timestamps, model name, vector content, or embedding-space fingerprint alone. State-changing actions require durable audit evidence.

For the current M1 physical slice, direct tenant-scoped tables SHALL use forced RLS; a missing tenant context SHALL fail closed. Durable registry and audit rows are append-only product records. Destructive migration rollback is an explicitly gated operator action rather than ordinary mutation.

### PRD-FR-009 Drift detection

Provider/model output changes that violate the registered fingerprint or statistical drift contract SHALL quarantine or register a new embedding space rather than silently updating the old one.

### PRD-FR-010 Abstention

When fidelity or OOD confidence is below policy threshold, the system SHALL abstain and choose an explicit fallback such as native re-embedding, source-index query, dual retrieval, or operator review.

## 7. Algorithm portfolio

### P0 production

- orthogonal Procrustes where assumptions fit;
- ridge/regularized linear mapping;
- low-rank affine mapping;
- bounded residual MLP when linear residual structure is insufficient and evidence justifies complexity.

### P1 advanced

- mixture/gating approaches for multi-model or OOD regimes;
- local-isometry/vector-linking methods;
- richer confidence models.

### P1 experimental

- unpaired/bidirectional latent translation when paired anchors/source text are unavailable.

Experimental methods may not become automatic production cutover gates without retrieval-level validation, calibration, threat review, and an Accepted ADR.

## 8. Non-goals

- claiming translated vectors are mathematically identical to target-native vectors;
- unlimited multi-hop adapter composition;
- comparing raw scores across incompatible spaces;
- storing tenant identity inside embedding values or UUID timestamp bits;
- treating vector migration as a substitute for eventual native backfill;
- giving an LLM authority over numerical compatibility or cutover gates that deterministic/statistical evidence can decide.

## 9. Quality requirements

- production arithmetic in Rust;
- exact production line/region/function/branch coverage where LLVM tooling exposes it;
- public Rust documentation coverage enforced by lints;
- reproducible Rust dependency resolution from a committed lockfile for release-bound source;
- executable PostgreSQL migration/RLS/concurrency/rollback tests for the M1 persistence slice;
- true-transform/parameter-recovery simulations for adapter algorithms;
- CPU reference and GPU parity when a computationally material GPU backend is introduced;
- realistic retrieval benchmarks, OOD splits, confidence calibration, migration rollback/replay, tenant isolation, poisoned-anchor, inversion, and drift tests;
- no skipped required scientific/security gate counted as passing.

## 10. Security and privacy

Embeddings, anchors, adapter weights, query logs, and migration artifacts are potentially sensitive. Controls SHALL use tenant-bound authorization, encryption/KMS, bounded retention, auditable export, signed artifacts, anchor-poisoning defenses, inversion-risk review, and purpose-bound access rather than assuming vectors are anonymous.

The active-PR registry slice supplies a concrete forced-RLS and append-only persistence boundary but does not yet implement the broader KMS, retention/export, incident, or service/admin-role design. No CSAP or SOC 2 certification is claimed from this M1 evidence alone.

## 11. Standalone and ecosystem compatibility

EmbedRelay must operate independently through provider-neutral ports. Optional CWL integrations may connect contextual-orchestrator, naruon, pg-llm-batch, EgressWeave, Keyverse, or other services through typed versioned interfaces. No integration may require direct access to another application's private database.

## 12. Release acceptance

A release requires integrated protected-head evidence for exact coverage, security, tenant controls, migrations/rollback, backup/recovery appropriate to the persisted surface, adapter/migration evaluation where those capabilities are included, reproducible artifacts, SBOM/provenance, operability, independent review, and real retrieval fidelity. The current PR is pre-release and remains Draft until its M1 exit criteria are met.
