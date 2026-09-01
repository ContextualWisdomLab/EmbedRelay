# EmbedRelay Technical Requirements Document

**Status:** Accepted target architecture with explicit active-PR M1 markers.  
**Last reviewed:** 2026-09-02

## 1. Technical objective

Provide a provider/vector-store-neutral Rust control and compute plane for identifying embedding spaces, validating vectors, registering/evaluating directional adapters, running confidence-gated translation, operating dual-index migrations, and converging to target-native backfill without silently mixing incompatible vector geometries.

## 2. Layered architecture

```text
control plane
  space registry
  adapter registry
  migration control
  policy / audit

data plane
  vector validator
  translation gateway
  index router / rank fusion
  native backfill scheduler
compute plane
  adapter fitting
  evaluation / calibration
  CPU reference + optional GPU kernels
ports
  embedding providers
  vector stores
  object storage / KMS
  telemetry / audit
```

Current PR #1 implements the first Rust contracts for space identity, vector safety, UUIDv7 identity, tenant registration, and audit-before-mutation intent **plus** a narrow PostgreSQL tenant registry/audit persistence boundary. It does not yet implement the full control plane, deployable API, adapter fitting/evaluation, migration orchestration, provider/vector-store ports, or GPU compute.

## 3. Canonical space identity

`embedding_space_id` is derived from a canonical manifest/fingerprint. Material fields include at least:

- provider family and immutable model/revision identity;
- input role (`query`, `document`, or another explicitly versioned role);
- preprocessing/tokenization/truncation policy;
- normalization policy;
- output dimension;
- scalar precision;
- similarity/distance metric contract;
- any provider parameter demonstrated to change vector geometry.

The canonical serialization and hash algorithm must be versioned. A change that can alter geometry produces a different space identity; provider marketing/model names are insufficient. The active-PR PostgreSQL M1 slice persists the tenant/fingerprint registration key only; durable full canonical-manifest storage remains an M1 follow-through requirement.

## 4. Vector validation

Before storage, training, metric comparison, translation, or routing:

- scalar precision must match the registered space;
- dimension must match exactly;
- every component must be finite;
- subnormal/unsupported numerical values follow the explicit fail-closed policy;
- zero norm is rejected when incompatible with the metric/normalization contract;
- vector byte length and batch count are bounded;
- tenant/space authorization is verified outside numerical content.

The current Rust M1 slice implements the core `float32` validation contract.

## 5. Directional adapters

Adapter identity is directional and role-specific:

```text
(source_space_id, target_space_id, input_role, algorithm_version, artifact_digest)
```

A→B does not imply B→A. Query→legacy-document and legacy-document→target-document mappings may have distinct losses and acceptance criteria.

### P0 fitting algorithms

- orthogonal Procrustes;
- ridge/regularized linear regression;
- low-rank affine mapping;
- bounded residual MLP only after a simpler-model residual diagnostic justifies it.

Production training arithmetic is Rust. CPU `f64`/high-precision accumulation is the numerical reference where material. GPU execution is added only after profiling demonstrates benefit and must pass parity/recovery gates.

## 6. Anchor/evaluation data

Paired anchors require provenance, sampling policy, role/language/domain coverage, duplicate control, temporal split where drift matters, tenant authorization, and poisoning checks. Train/evaluation anchors must be separated by content/entity where leakage could inflate fidelity.

Evaluation records include:

- vector-space transformation error/alignment;
- neighborhood preservation;
- retrieval Recall@k, MRR/NDCG as appropriate;
- OOD/domain/language slices;
- confidence calibration/Brier/ECE where applicable;
- abstention/error tradeoff;
- native-target baseline;
- source-space baseline;
- uncertainty intervals/bootstrap where material.

## 7. Confidence gate

Every translation may return:

```text
translated
abstained_low_confidence
abstained_ood
abstained_policy
adapter_unavailable
space_mismatch
invalid_vector
```

The confidence gate never silently substitutes an incompatible adapter. Fallbacks are explicit: native target encode, source-index query, dual retrieval, queued backfill, or operator review.

## 8. Dual-index routing

During migration a query may be evaluated against:

- target-native index;
- source/legacy index via target→legacy query adapter;
- translated target index where policy permits.

Raw similarity scores from different spaces are not averaged. Default fusion is rank-level (for example reciprocal-rank-style fusion) or a separately trained reranker with its own evaluation contract.

## 9. Native backfill

Backfill prioritization can use uncertainty, access frequency, business criticality, source availability, and migration deadline. Each record tracks vector origin and source hash/version. The final accepted state should be target-native for all records that can legally and technically be re-encoded.

## 10. Data and tenant model

The **active-PR M1 physical persistence slice** uses PostgreSQL 18.x and is deliberately narrow:

- schema `embedrelay_registry`;
- table `tenant_space_registry(tenant_space_record_id, tenant_id, space_fingerprint, created_at)`;
- table `space_registration_audit(audit_event_id, tenant_id, space_fingerprint, actor_id, action_code, occurred_at)`;
- unique `(tenant_id, space_fingerprint)` registration identity;
- PostgreSQL `uuidv7()` for durable row/event identifiers;
- deferred foreign key from the audit tenant/fingerprint pair to the registry key, allowing audit-first insertion but requiring a valid registration at commit;
- forced RLS on both tenant-scoped tables using explicit `embedrelay.tenant_id` session context;
- append-only mutation/truncate denial;
- public/default privileges revoked;
- guarded destructive rollback.

This slice is in 3NF: registration facts and audit-event facts live in separate relations. It does **not** yet persist the complete immutable canonical manifest, adapters, vector references, evaluation records, migration plans/stages, index bindings, backfill tasks, drift events, or broader policy state. Those remain planned durable control-plane objects.

UUIDv7 identifiers are opaque durable IDs only; tenant authorization and business chronology remain explicit relational/context data.

## 11. Concurrency and idempotency

Current M1 durable registration has one minimal transaction boundary: one tenant/fingerprint registration attempt. The function inserts `space_registration_intent` audit first, then the registry row, and both commit or roll back together.

The current contract is deliberately **duplicate-rejecting, not UPSERT-based**. Concurrent same-tenant/space registration is serialized by the unique `(tenant_id, space_fingerprint)` key and must produce exactly one committed registry row and one committed audit event; the losing unique-violation transaction rolls its audit insert back. A future idempotent replay API requires a stable request/idempotency key and a separate test-first contract rather than heuristic conflict handling.

No global application lock, partitioning scheme, or read/write split is justified yet. Add partitioning, CQRS, or replicas only from measured hot-key/read pressure while preserving forced RLS and the same item-level invariants.

## 12. API/port contracts

Provider and vector-store integrations sit behind versioned ports. Core logic never assumes a single vendor's model name, index score semantics, batch shape, or identifier format. Every adapter validates provider response dimension/fingerprint before accepting data. The current PostgreSQL schema is a private persistence implementation boundary, not an integration API for another repository.

## 13. Security

- embeddings/anchors/adapters are sensitive assets;
- tenant identity is explicit and not vector-derived;
- the active M1 persistence slice uses forced RLS and a non-`BYPASSRLS` adversarial contract;
- registry/audit rows are append-only; destructive rollback is separately gated;
- artifacts will be digested/signed and immutable after release;
- training/evaluation input provenance is auditable;
- poisoned anchors, model-output drift, inversion/extraction, cross-tenant query, replay, rollback tampering, and malicious artifact loading are in threat scope;
- PII handling uses purpose-bound access/encryption/retention/export controls rather than default destructive masking.

The M1 persistence evidence does not establish broader KMS, retention/export, residency, privileged-admin, incident-response, CSAP, or SOC 2 certification claims.

## 14. Observability

Record per migration/adapter:

- eligible/adapted/abstained/native counts;
- confidence distribution;
- retrieval-fidelity metrics;
- source/target/index versions;
- latency/throughput and compute backend;
- GPU/CPU memory/time where material;
- backfill progress;
- drift/rollback events;
- audit/provenance completeness.

Do not expose raw vectors or protected text in ordinary logs. For the current M1 registry, database verification evidence must identify exact migration/test version and head without logging sensitive payloads.

## 15. M1 exit criteria

M1 Space Registry and Vector Safety is complete only after:

- durable PostgreSQL migrations and guarded rollback — **active-PR implemented; exact-head verification required**;
- tenant RLS/authorization enforcement — **active-PR implemented for the two M1 tables; exact-head verification required**;
- immutable complete space manifest/fingerprint storage — **fingerprint registration implemented; complete manifest persistence still required**;
- append-only durable audit and transactional concurrency behavior — **active-PR implemented; exact-head verification required**;
- exact production coverage/docstrings and locked dependency resolution — **CI contract present; current-head evidence required**;
- security/threat tests — **partial; central dependency-review availability remains an external governance blocker when HTTP 403 recurs**;
- operability/recovery evidence — **migration rollback contract present; measured backup/restore still required**;
- integrated current-head CI/security/independent review — **required before Draft can be considered ready**.

Adapter training and dual-index migration belong to later milestones after this substrate is accepted.
