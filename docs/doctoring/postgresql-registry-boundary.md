# Doctoring: PostgreSQL Tenant Registry / RLS / Audit Boundary

**Status:** active-PR implementation evidence; current exact head must still pass hosted verification  
**Last reviewed:** 2026-09-02  
**Product boundary:** M1 Space Registry and Vector Safety

## Problem and product risk

The Rust `TenantSpaceRegistry` reference contract establishes tenant/fingerprint uniqueness and audit-before-observable-state semantics, but an in-memory contract alone cannot prove durable tenant isolation, append-only audit, concurrent registration behavior, recovery, or persistence fidelity. A commercial embedding-continuity control plane must not silently expose another tenant's registered embedding space, create duplicate durable audit intents under a race, rewrite historical registry/audit evidence, or transform the canonical space identity at the persistence boundary.

The bounded M1 slice persists tenant/fingerprint registration and `space_registration_intent` audit evidence. It does not yet persist complete canonical manifests, adapters, evaluations, migrations, vectors, or provider state.

## Test-first lineage

`tests/postgres_registry_contract.sh` existed on PR #1 before the physical migrations. Its initial executable contract failed closed when `migrations/0001_tenant_space_registry.up.sql` and `.down.sql` were absent. That was the RED boundary for durable persistence rather than a post-hoc test added after implementation.

Implementation then proceeded on the existing writer branch without force-push or destructive history rewriting:

1. `e4638ef78155795805f7144f9461f6e4ce1a530f` introduced the up migration for tenant registry, durable audit, RLS, append-only triggers, and transactional registration.
2. `68f4acac2a4c059ad9aaecd2bf5e6bcd50b6ae55` introduced the explicitly gated destructive rollback migration.
3. `616dd5be29af741b13a9010172a1b82f1fa2fcec` corrected RLS policy composition before any success claim: PostgreSQL requires at least one permissive policy before restrictive policies can narrow access, so the current migration uses the default permissive tenant policy while retaining `FORCE ROW LEVEL SECURITY` and negative cross-tenant tests.
4. `dbd1d33a75f08302328966e3daaf06ce13acaf64` expanded the PostgreSQL contract for missing tenant context, fingerprint rejection, UUIDv7 registry/audit IDs, registry and audit immutability, cross-tenant denial, concurrent duplicate registration, guarded rollback, and migration reapplication.
5. `4691e89266bbe27f08b7f2d869ad411f02eff378` wired the contract into exact-head CI using PostgreSQL 18.6.
6. Later M1 work added `tests/postgres_backup_restore_contract.sh`, which creates a disposable logical backup and restores it into a fresh database before re-proving tenant isolation and append-only controls.
7. A cross-layer identity defect was then reproduced test-first. Rust `EmbeddingSpaceManifest::fingerprint()` emits the canonical domain value `sha256:<64 lowercase hex>`, while the original SQL accepted only a bare 64-hex digest. Commit `1a5222b0dcc6d3f03e195bc63811c05da4461aac` changed the primary PostgreSQL contract to require the exact Rust representation and explicitly reject the bare digest. Commit `19e018bd842a38ca523ed9c7e3b6a8a91d928739` changed backup/restore fixtures to preserve the same representation. Those RED expectations preceded the production correction.
8. Commit `d218c4a24164edf7fc5bd74fc3ca880402fa9ecf` repaired the migration and registration function so both durable relations accept only `^sha256:[0-9a-f]{64}$`; comments document that callers must not strip or reconstruct the prefix.

Every successor commit changes the exact PR head. These commit IDs are implementation/TDD lineage only and are never merge evidence for a later head.

## Current physical contract

### Relations

`embedrelay_registry.tenant_space_registry`

- `tenant_space_record_id uuid PRIMARY KEY DEFAULT uuidv7()`
- `tenant_id uuid NOT NULL`
- `space_fingerprint text NOT NULL`
- `created_at timestamptz NOT NULL`
- unique `(tenant_id, space_fingerprint)`
- exact canonical `sha256:<64 lowercase hex>` fingerprint check

`embedrelay_registry.space_registration_audit`

- `audit_event_id uuid PRIMARY KEY DEFAULT uuidv7()`
- `tenant_id uuid NOT NULL`
- `space_fingerprint text NOT NULL`
- `actor_id uuid NOT NULL`
- `action_code text NOT NULL = 'space_registration_intent'`
- `occurred_at timestamptz NOT NULL`
- exact canonical `sha256:<64 lowercase hex>` fingerprint check
- deferred foreign key from `(tenant_id, space_fingerprint)` to the registry natural key

The relations are in 3NF for the current slice: tenant-space registration facts and audit-event facts are separate, and no mutable adapter/manifest facts are duplicated into audit rows.

### Canonical identity invariant

The Rust domain owns fingerprint construction and returns a domain-separated string rather than a raw digest. PostgreSQL stores that exact value unchanged. The physical boundary rejects both a bare digest and non-canonical case, so a storage adapter cannot accidentally erase the `sha256:` domain marker and force downstream consumers to infer or reconstruct identity material.

This representation is exercised across normal registration, duplicate registration, two-session concurrency, tenant filtering, `pg_dump`, `pg_restore`, and post-restore reconciliation. Full immutable manifest persistence remains a separate follow-through requirement; preserving the fingerprint does not pretend that the complete manifest is already durable.

### Transaction and item-level mutation contract

`register_tenant_space(registration_actor_id uuid, requested_space_fingerprint text)` is one minimal transaction-scoped command:

1. require explicit `embedrelay.tenant_id` context;
2. validate actor and exact canonical fingerprint;
3. insert the append-only audit intent;
4. insert the tenant/fingerprint registration;
5. commit both or neither.

The deferred foreign key permits the deliberate audit-first insertion order while still requiring a matching registry row at transaction commit.

The current item-level write contract is **insert-only and duplicate-rejecting; it is not an UPSERT**. A second same-tenant/fingerprint insertion raises the unique-key outcome. Under two concurrent attempts, exactly one transaction can commit; the losing transaction rolls back its audit intent with the failed registration. If a future network API requires retry idempotency rather than duplicate rejection, it must introduce a stable request/idempotency key and a separate test-first contract instead of heuristic conflict handling.

### Tenant isolation and append-only evidence

Both current tables enable and force RLS, use an explicit `embedrelay.tenant_id` session setting in `USING` and `WITH CHECK`, and are exercised under a non-superuser, non-`BYPASSRLS` test role. A missing tenant context is not treated as a wildcard. The registration function fails closed and another tenant's rows remain invisible/denied.

Ordinary `UPDATE`, `DELETE`, and `TRUNCATE` operations on both relations are rejected by trigger functions. Public/default privileges are revoked and service-role access must be granted deliberately. The down migration is destructive and refuses to run unless `embedrelay.allow_destructive_rollback=on` is explicitly set; that operator escape hatch is not an application mutation surface.

## Concurrency and performance boundary

The only expected serialization point today is the unique `(tenant_id, space_fingerprint)` key for identical registrations. There is no global application lock. Two attempts to create the exact same domain fact must establish one durable winner and one audit event.

No hash partitioning, tenant sharding, read/write split, replica topology, or CQRS is introduced without measured evidence. If a high-volume tenant creates hot uniqueness pages or registry reads dominate later workloads, mitigation must be benchmarked while preserving forced RLS, one-item transaction boundaries, the exact canonical fingerprint, and the uniqueness/audit invariant.

## Failure and recovery

Expected fail-closed outcomes include:

- missing tenant context → registration denied;
- bare digest, malformed, upper-case, or otherwise noncanonical fingerprint → invalid parameter;
- another tenant's row → invisible/denied through RLS;
- duplicate or concurrent identical registration → one unique-key winner only;
- ordinary update/delete/truncate → rejected as append-only violation;
- destructive down migration without explicit opt-in → rejected.

The active PR now contains a disposable logical backup/restore acceptance candidate. It seeds two tenant-isolated canonical fingerprints, records exact registry/audit UUID identities, creates a custom-format `pg_dump`, restores into a fresh database, reconciles exact identities and row counts, and re-proves forced RLS, append-only triggers, application-role privileges, table comments, both tenant views, and outsider denial. The emitted backup bytes and elapsed dump/restore time are fixture measurements only; they do not establish production RTO/RPO, PITR, HA, cross-host/object-store recovery, or encryption/key-rotation behavior.

## Security and governance interpretation

Embeddings and their provenance can be sensitive; a space fingerprint or UUID is not an authorization token. This boundary therefore keeps tenant authority explicit rather than inferring it from object identifiers, vector content, or UUIDv7 timestamps.

The active-PR RLS/append-only/recovery evidence supports a design direction toward auditable CSAP/SOC 2 controls but does not constitute certification. Broader privileged-role governance, KMS/encryption, retention/deletion/export, residency, incident evidence, service authentication, and production recovery architecture remain future implementation responsibilities.

## Exact-head acceptance

A current PR head may promote this boundary only when all of the following are true for that same head:

- `cargo test --workspace --locked` passes;
- PostgreSQL 18.6 starts and `tests/postgres_registry_contract.sh` passes with the exact canonical `sha256:<digest>` representation;
- `tests/postgres_backup_restore_contract.sh` passes on the same head;
- exact LLVM line/region/function/branch coverage passes;
- central Security/SAST and other required repository workflows complete without an unhandled substantive finding;
- review threads are resolved from current code evidence;
- a qualifying independent non-author approval satisfies repository rules;
- no predecessor-head result is substituted for current-head evidence.

The central ContextualWisdomLab dependency-review HTTP 403 incident is tracked in `ContextualWisdomLab/.github#810`. If it recurs on an otherwise valid exact head, it remains a causal control-plane blocker rather than evidence that this repository's PostgreSQL tests passed.

## References

PostgreSQL Global Development Group. (2025). *PostgreSQL 18 release notes*. PostgreSQL Documentation. https://www.postgresql.org/docs/18/release-18.html

PostgreSQL Global Development Group. (2026). *CREATE POLICY*. PostgreSQL 18 Documentation. https://www.postgresql.org/docs/18/sql-createpolicy.html

PostgreSQL Global Development Group. (2026). *CREATE TRIGGER*. PostgreSQL 18 Documentation. https://www.postgresql.org/docs/18/sql-createtrigger.html

PostgreSQL Global Development Group. (2026). *UUID functions*. PostgreSQL 18 Documentation. https://www.postgresql.org/docs/18/functions-uuid.html

Davis, K., Peabody, B., & Leach, P. (2024). *Universally Unique IDentifiers (UUIDs)* (RFC 9562). RFC Editor. https://www.rfc-editor.org/rfc/rfc9562
