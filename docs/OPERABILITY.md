# EmbedRelay Operability and Migration Runbook

**Status:** Accepted target operating baseline; current PR #1 is not deployable M1 completion.  
**Last reviewed:** 2026-08-09

## Operating principles

- Never mix incompatible embedding spaces silently.
- Keep source retrieval available until rollback criteria expire.
- Treat abstention as normal and observable.
- Prefer reversible staged migration over all-at-once cutover.
- Native target backfill is the desired terminal state where feasible.
- Numerical/retrieval evidence and tenant/security controls are release gates, not dashboards after the fact.

## Migration runbook

1. **Inventory** source/target provider/model/revision/role/preprocessing/normalization/dimension/precision/metric.
2. **Register** immutable source and target spaces.
3. **Acquire anchors** with authorization, leakage control, domain/language/time coverage, and provenance.
4. **Fit candidates** from simplest P0 family upward.
5. **Evaluate** held-out vector, retrieval, OOD, calibration, and security evidence.
6. **Approve or abstain**; never activate an unqualified candidate.
7. **Shadow** target-native and bridge behavior without affecting production ranking.
8. **Dual-index** with rank-level fusion/reranking and explicit source/target origins.
9. **Canary** a bounded traffic fraction with rollback trigger metrics.
10. **Progressive cutover** only while fidelity/SLO/security thresholds remain satisfied.
11. **Backfill native** target vectors, prioritizing risk/usage/uncertainty.
12. **Retain source** through the rollback window.
13. **Complete** only when terminal-state/native and audit/reconciliation criteria are met.

## Key SLIs

- eligible / translated / abstained / native query counts;
- target-native overlap, Recall@k, MRR/NDCG by supported task;
- OOD and language/domain slice fidelity;
- confidence/calibration drift;
- adapter/artifact integrity failures;
- cross-tenant authorization failures;
- source/target index error and latency;
- backfill queue depth, throughput, age, and retry count;
- vector origin distribution;
- migration-stage traffic fraction;
- rollback frequency/cause;
- provider output drift events;
- CPU/GPU time, transfer, memory, fallback when applicable.

## Alert/stop conditions

Immediately halt progression or roll back when required thresholds fail, including: target-native retrieval overlap falls below policy, confidence calibration drifts materially, unexpected abstention spikes, provider fingerprint changes, artifact integrity fails, cross-tenant access is observed, target index errors exceed bound, source path becomes unavailable before rollback acceptance, or reconciliation/provenance becomes incomplete.

## Idempotency and recovery

Registry/migration/backfill mutations use tenant-scoped idempotency. A retry must return/continue the same semantic operation or fail on key mismatch. Backfill records retain origin and source hash/ref so interrupted jobs can resume without duplicate vector identity.

## Rollback

Rollback changes routing to the last accepted source/dual path and freezes further cutover/backfill mutation until RCA. It does not delete target evidence. Preserve source index/manifest/adapter/evaluation/migration/audit evidence through the configured rollback window.

## PostgreSQL target operations

Before enabling durable M1:

- apply migrations in a rehearsal environment;
- verify forced RLS and service roles;
- verify append-only audit semantics;
- run concurrent registration/idempotency tests;
- validate backup/restore and tenant isolation;
- record migration/rollback hashes and release versions.

The current PR #1 has no completed PostgreSQL control plane; these are target procedures.

## Capacity planning

Capacity is driven by anchor count/dimension, candidate algorithm, migration query traffic, source/target index latency, backfill volume, provider quotas, and vector-store throughput. Compute pools use bounded worker counts. GPU workloads are admitted only when profiled and must reserve memory/rollback/fallback capacity.

## Incident RCA

Classify first failing boundary: space identity, vector validation, tenant policy, audit/persistence, anchor evidence, adapter fitting, evaluation/calibration, artifact integrity, provider, vector store, router/fusion, migration state, backfill, or release pipeline. Fix the owning layer and add a regression; do not hide an upstream compatibility defect with downstream reranking.

## Release and rollback artifacts

A release-ready build includes migrations + rollback, API/schema versions, CHANGELOG/version, SBOM/provenance, artifact digests/signatures where used, exact coverage/security/review evidence, retrieval evaluation summary, SLO/capacity notes, and recovery instructions.