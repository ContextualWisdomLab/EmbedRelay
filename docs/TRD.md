# EmbedRelay Technical Requirements Document

**Status:** Accepted target architecture with explicit as-built M1 markers.  
**Last reviewed:** 2026-08-09

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

Current PR #1 implements only the first storage-independent Rust contracts for space identity, vector safety, UUIDv7 identity, tenant registration, and audit-before-mutation intent.

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

The canonical serialization and hash algorithm must be versioned. A change that can alter geometry produces a different space identity; provider marketing/model names are insufficient.

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

Planned durable PostgreSQL state includes tenant records, embedding spaces, vector origins/references, adapter artifacts, training/evaluation runs, migration plans/stages, index bindings, backfill tasks, audit events, and policy decisions. UUIDv7 identifiers are opaque durable IDs only; tenant/authorization/chronology must be explicit columns/relations.

PostgreSQL/RLS durability is not yet implemented by PR #1 and must not be inferred from the current in-memory registry.

## 11. Concurrency and idempotency

Durable registration and migration mutations require transactionally enforced uniqueness/idempotency. Concurrent same-tenant/space registration must produce one durable state plus deterministic duplicate/idempotent outcomes. Audit acceptance must precede visibility atomically or within a transaction/outbox design that preserves audit-before-observable-state semantics.

## 12. API/port contracts

Provider and vector-store integrations sit behind versioned ports. Core logic never assumes a single vendor's model name, index score semantics, batch shape, or identifier format. Every adapter validates provider response dimension/fingerprint before accepting data.

## 13. Security

- embeddings/anchors/adapters are sensitive assets;
- tenant identity is explicit and not vector-derived;
- artifacts are digested/signed and immutable after release;
- training/evaluation input provenance is auditable;
- poisoned anchors, model-output drift, inversion/extraction, cross-tenant query, replay, rollback tampering, and malicious artifact loading are in threat scope;
- PII handling uses purpose-bound access/encryption/retention/export controls rather than default destructive masking.

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

Do not expose raw vectors or protected text in ordinary logs.

## 15. M1 exit criteria

M1 Space Registry and Vector Safety is complete only after:

- durable PostgreSQL migrations and rollback;
- tenant RLS/authorization enforcement;
- immutable space manifest/fingerprint storage;
- append-only durable audit and transactional concurrency behavior;
- exact production coverage/docstrings;
- security/threat tests;
- operability/recovery evidence;
- integrated current-head CI/security/independent review.

Adapter training and dual-index migration belong to later milestones after this substrate is accepted.