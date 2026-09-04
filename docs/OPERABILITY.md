# EmbedRelay Operability and Migration Runbook

**Status:** Accepted target operating baseline; PR #1 has a narrow executable PostgreSQL M1 slice but is not deployable M1 completion.  
**Last reviewed:** 2026-09-02

## Operating principles

- Never mix incompatible embedding spaces silently.
- Keep source retrieval available until rollback criteria expire.
- Treat abstention as normal and observable.
- Prefer reversible staged migration over all-at-once cutover.
- Native target backfill is the desired terminal state where feasible.
- Numerical/retrieval evidence and tenant/security controls are release gates, not dashboards after the fact.
- Treat migration rollback and durable data backup/restore as separate evidence surfaces.

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

Only M1 space-registration persistence has executable source today; adapter, routing, canary, and backfill stages remain future product surfaces.

## Current PostgreSQL M1 operating boundary

The active PR contains `migrations/0001_tenant_space_registry.up.sql` and `.down.sql`, `tests/postgres_registry_contract.sh`, and `tests/postgres_backup_restore_contract.sh`. Exact-head CI provisions PostgreSQL 18.6 and is configured to verify both the physical registry boundary and disposable backup/restore acceptance.

Current source-level acceptance includes:

- apply the up migration to an empty M1 contract database;
- operate under a deliberately granted non-superuser/non-`BYPASSRLS` role;
- require explicit `embedrelay.tenant_id` context;
- register canonical tenant/fingerprint items transactionally with audit intent inserted first;
- reject noncanonical fingerprints;
- deny cross-tenant insertion and hide another tenant's rows;
- reject registry/audit `UPDATE`, `DELETE`, and `TRUNCATE` operations;
- race two identical registration attempts and require exactly one committed registry row plus one audit event;
- reject destructive rollback without explicit `embedrelay.allow_destructive_rollback=on`;
- perform the opted-in destructive rollback in the disposable test environment;
- reapply the up migration and verify the registry relation exists;
- seed two tenant-isolated registry/audit pairs, create a custom-format `pg_dump`, restore it into a fresh database, and reconcile exact registry/audit UUID identities and row counts;
- verify enabled + forced RLS, append-only triggers, schema/table comments, and application-role schema/table/function privileges survive restore;
- verify both restored tenants see exactly their own registry/audit row while an outsider sees none;
- verify restored append-only registry/audit mutation protection still fails closed;
- record backup artifact byte size plus measured dump/restore durations as fixture evidence without treating the fixture as a production RTO/RPO claim.

These source-level contracts become operational evidence only after the current exact-head CI actually executes successfully. Queued/pending/predecessor runs are not passing evidence.

This is not a general production database administration procedure. The current M1 migration does not create complete canonical-manifest, adapter, evaluation, migration, routing, backfill, or vector-reference persistence.

## Current registry idempotency and recovery semantics

The current database registration command is **not an UPSERT**. The item-level contract is insert-only and duplicate-rejecting. A retry of an already committed tenant/fingerprint registration receives the unique-key outcome; a concurrent losing transaction rolls back its preceding audit insert. This is deterministic duplicate handling, not network-request idempotency.

If a future service API needs replay-safe idempotency, it must add a stable request/idempotency key and define replay, mismatch, expiry, and audit behavior explicitly before implementation.

The database transaction can recover from a failed registration attempt by rolling back both audit and registry writes. The guarded down migration can remove the entire M1 schema in a disposable/rehearsal context. The new backup/restore contract exercises logical durable-data recovery into a fresh database; it does not prove point-in-time recovery, high availability, production-scale recovery, or a committed RPO/RTO.

## Backup and restore acceptance

`tests/postgres_backup_restore_contract.sh` is the current disposable logical-recovery acceptance candidate. It deliberately uses anonymous/opaque UUID fixtures and generated fingerprints rather than production vectors or PII.

A current-head GREEN run must prove:

- two tenant registrations and their audit events are captured in the backup;
- a custom-format logical backup artifact is non-empty;
- restore into a newly created database succeeds;
- exact registry/audit UUID identities and total row counts reconcile with the source database;
- table constraints/functions, forced RLS policies, append-only triggers, application-role privileges, and schema/table comments remain present after restore;
- tenant isolation still holds under the non-`BYPASSRLS` contract role after restore;
- restored registry and audit rows remain append-only;
- backup size and dump/restore duration are emitted as fixture evidence.

The durations and artifact size from this tiny CI fixture characterize only that fixture. They are not production RTO/RPO, capacity, or durability claims.

PITR, WAL archiving, cross-host/object-store backup transport, encryption/key rotation, failover, and production-scale recovery remain separate future acceptance surfaces when deployment architecture requires them.

## Key SLIs

- eligible / translated / abstained / native query counts;
- target-native overlap, Recall@k, MRR/NDCG by supported task;
- OOD and language/domain slice fidelity;
- confidence/calibration drift;
- adapter/artifact integrity failures;
- cross-tenant authorization failures;
- registry duplicate/conflict counts when the service boundary exists;
- source/target index error and latency;
- backfill queue depth, throughput, age, and retry count;
- vector origin distribution;
- migration-stage traffic fraction;
- rollback frequency/cause;
- provider output drift events;
- CPU/GPU time, transfer, memory, fallback when applicable.

## Alert/stop conditions

Immediately halt progression or roll back when required thresholds fail, including: target-native retrieval overlap falls below policy, confidence calibration drifts materially, unexpected abstention spikes, provider fingerprint changes, artifact integrity fails, cross-tenant access is observed, RLS/recovery evidence fails, target index errors exceed bound, source path becomes unavailable before rollback acceptance, or reconciliation/provenance becomes incomplete.

## Migration rollback

Product migration rollback changes routing to the last accepted source/dual path and freezes further cutover/backfill mutation until RCA. It does not delete target evidence. Preserve source index/manifest/adapter/evaluation/migration/audit evidence through the configured rollback window.

Database schema rollback is different: the current M1 down migration is deliberately destructive and requires explicit opt-in. It is intended for disposable rehearsal/test rollback before protected release, not as the ordinary way to undo a production registration.

## Capacity planning

Capacity is driven by anchor count/dimension, candidate algorithm, migration query traffic, source/target index latency, backfill volume, provider quotas, and vector-store throughput. Compute pools use bounded worker counts. GPU workloads are admitted only when profiled and must reserve memory/rollback/fallback capacity.

For the current registry tables, no partitioning or read/write split is assumed. Measure unique-key contention, tenant distribution, registry read pressure, WAL/backup volume, and lock wait time before introducing partitioning/replicas/CQRS. Preserve forced RLS and one-item transaction boundaries under any later optimization.

## Incident RCA

Classify the first failing boundary: space identity, vector validation, tenant policy, audit/persistence, migration/restore, anchor evidence, adapter fitting, evaluation/calibration, artifact integrity, provider, vector store, router/fusion, migration state, backfill, or release pipeline. Fix the owning layer and add a regression; do not hide an upstream compatibility defect with downstream reranking.

The central GitHub Dependency Review availability incident is tracked in `ContextualWisdomLab/.github#810`; when reproduced on an exact public non-fork head it is a shared control-plane evidence failure, not a reason to weaken EmbedRelay repository protection.

## Release and rollback artifacts

A release-ready build includes applicable migrations + guarded rollback, current-head measured backup/restore evidence for persisted production surfaces, API/schema versions, CHANGELOG/version, locked/reproducible dependency resolution, SBOM/provenance, artifact digests/signatures where used, exact coverage/security/PostgreSQL/review evidence, retrieval evaluation summary for adapter/migration features, SLO/capacity notes, and recovery instructions.
