# EmbedRelay Test and Evaluation Strategy

**Status:** Accepted quality baseline  
**Last reviewed:** 2026-08-09

## Goal

Verify numerical fidelity, retrieval usefulness, tenant/security boundaries, migration reversibility, and operational correctness. Passing unit tests or high vector cosine similarity alone does not establish commercial migration safety.

## Repository gates

- Rust workspace tests;
- exact LLVM line, region, function, and branch coverage at 100% for production code;
- `missing_docs = deny` and strict lint policy;
- exact-current-head CI/security/review evidence;
- migration/schema/operator documentation contract tests;
- supply-chain/provenance evidence when artifacts are released.

## M1 registry/vector tests

- canonical fingerprint changes for every material space-contract field;
- same manifest determinism;
- equal dimensions but differing role/revision/normalization/metric remain incompatible;
- dimension/precision mismatch rejection;
- NaN, infinity, subnormal policy, and zero-norm rejection;
- valid `float32` vector acceptance;
- RFC 9562 UUIDv7 generation/parse/version/variant/non-reflecting errors;
- same-tenant duplicate registration;
- equal fingerprint across different tenants remains isolated;
- audit rejection leaves state unchanged;
- audit intent precedes visible state.

## Durable persistence tests

When PostgreSQL work lands:

- migration up/down and rollback;
- forced RLS/cross-tenant negatives;
- concurrent same-space registration produces one durable state;
- tenant-scoped idempotency;
- append-only audit guarantees;
- transaction failure cannot make unaudited state visible;
- immutable canonical space rows after dependent use;
- backup/restore preserves tenant and audit invariants.

## Adapter true-transform recovery

Synthetic tests generate known source vectors and known transforms/perturbations so fitted adapters can be measured against truth. Report transformation parameter error where identifiable, held-out RMSE/alignment, neighborhood preservation, recovery under noise/anchor sparsity, and uncertainty/calibration.

For nonlinear/mixture methods include known-regime assignments and OOD conditions; do not accept a method solely because training loss falls.

## Retrieval-level validity

Every production adapter requires realistic retrieval evaluation against target-native encoding:

- Recall@k;
- MRR/NDCG where task-appropriate;
- overlap with target-native top-k;
- query/document role correctness;
- domain/language/time/OOD slices;
- confidence-calibration and abstention tradeoff;
- error bars/bootstrap where material;
- source-native and target-native baselines.

## Migration tests

- shadow/dual-index/canary/progressive cutover transitions;
- raw cross-space scores are never averaged;
- rank fusion/reranking deterministic contract;
- rollback restores source-primary path;
- source index is not retired before rollback-window/acceptance criteria;
- backfill is idempotent and preserves origin/provenance;
- low-confidence translation routes to documented fallback;
- interrupted backfill resumes without duplicate/corrupt state.

## Drift tests

Simulate a provider returning a materially different output under the same model label. The system must detect fingerprint/statistical incompatibility, prevent mixing into the existing space, and quarantine/register new space state.

## CPU/GPU parity

When GPU compute is introduced:

- CPU reference and GPU backend fit the same deterministic synthetic workload;
- compare objective/loss, fitted parameters/artifact outputs, retrieval metrics, and confidence/calibration within predefined tolerances;
- test precision modes, batch boundaries, memory pressure, and CPU fallback;
- skipped GPU tests in a required GPU lane are failures, not passing evidence.

## Security/adversarial tests

- cross-tenant registry/adapter/migration access;
- anchor poisoning and evaluation leakage;
- forged adapter digest/manifest;
- malformed or oversized vectors/artifacts;
- provider/vector-store response shape/score semantic violations;
- inversion/linkage risk evaluation on representative protected data classes;
- replay/idempotency and concurrent migration-stage mutations;
- ordinary logs do not contain raw vectors/source text/secrets.

## Documentation/traceability tests

The repository should fail CI if canonical PRD/TRD/Architecture/UML/ERD/API/ADR/Security/Threat/Test/Operability/Traceability documents disappear or falsely claim planned persistence/adapter/migration components are implemented.

## Release rule

A release/cutover requires a single exact integrated head with all required numerical, retrieval, security, migration, coverage, package/provenance, and independent-review gates passing. Predecessor-head or synthetic-only evidence does not transfer.