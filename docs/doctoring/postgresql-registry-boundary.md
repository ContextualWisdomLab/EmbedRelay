# Doctoring: PostgreSQL Tenant Registry / RLS / Audit Boundary

**Status:** active-PR implementation evidence; current exact head must still pass hosted verification  
**Last reviewed:** 2026-09-02  
**Product boundary:** M1 Space Registry and Vector Safety

## Problem and product risk

The Rust `TenantSpaceRegistry` reference contract established tenant/fingerprint uniqueness and audit-before-observable-state semantics, but an in-memory contract alone could not prove durable tenant isolation, append-only audit, concurrent registration behavior, or rollback safety. A commercial embedding-continuity control plane must not silently expose another tenant's registered embedding space, create duplicate durable audit intents under a race, or let ordinary application writes rewrite historical registry/audit evidence.

The bounded repair is intentionally smaller than the full future control plane. It persists only tenant/fingerprint registration and `space_registration_intent` audit evidence. It does not yet persist complete canonical manifests, adapters, evaluations, migrations, vectors, or provider state.

## Test-first lineage

`tests/postgres_registry_contract.sh` existed on PR #1 before the physical migrations. Its initial executable contract failed closed when `migrations/0001_tenant_space_registry.up.sql` and `.down.sql` were absent. That was the RED boundary for durable persistence rather than a post-hoc test added after implementation.

Implementation then proceeded on the existing writer branch without force-push or destructive history rewriting:

1. `e4638ef78155795805f7144f9461f6e4ce1a530f` introduced the up migration for tenant registry, durable audit, RLS, append-only triggers, and transactional registration.
2. `68f4acac2a4c059ad9aaecd2bf5e6bcd50b6ae55` introduced the explicitly gated destructive rollback migration.
3. `616dd5be29af741b13a9010172a1b82f1fa2fcec` corrected the RLS policy composition before any success claim: the first draft used only `AS RESTRICTIVE` policies, but PostgreSQL's current `CREATE POLICY` documentation states that at least one permissive policy must grant access before restrictive policies can narrow it. The current migration therefore uses the default permissive tenant policy and retains `FORCE ROW LEVEL SECURITY` plus negative cross-tenant tests.
4. `dbd1d33a75f08302328966e3daaf06ce13acaf64` expanded the PostgreSQL contract for missing tenant context, canonical fingerprint rejection, UUIDv7 registry/audit IDs, registry and audit immutability, cross-tenant denial, concurrent duplicate registration, guarded rollback, and migration reapplication.
5. `4691e89266bbe27f08b7f2d869ad411f02eff378` wired the contract into exact-head CI using PostgreSQL 18.6.

Subsequent documentation commits change the exact PR head. Predecessor-head results are historical implementation/TDD lineage only and are never merge evidence for a later head.

## Current physical contract

### Relations

`embedrelay_registry.tenant_space_registry`

- `tenant_space_record_id uuid PRIMARY KEY DEFAULT uuidv7()`
- `tenant_id uuid NOT NULL`
- `space_fingerprint text NOT NULL`
- `created_at timestamptz NOT NULL`
- unique `(tenant_id, space_fingerprint)`
- canonical lower-case 64-hex fingerprint check

`embedrelay_registry.space_registration_audit`

- `audit_event_id uuid PRIMARY KEY DEFAULT uuidv7()`
- `tenant_id uuid NOT NULL`
- `space_fingerprint text NOT NULL`
- `actor_id uuid NOT NULL`
- `action_code text NOT NULL = 'space_registration_intent'`
- `occurred_at timestamptz NOT NULL`
- deferred foreign key from `(tenant_id, space_fingerprint)` to the registry natural key

The relations are in 3NF for the current slice: tenant-space registration facts and audit-event facts are separate, and no mutable adapter/manifest facts are duplicated into audit rows.

### Transaction and item-level mutation contract

`register_tenant_space(registration_actor_id uuid, requested_space_fingerprint text)` is one minimal transaction-scoped command:

1. require explicit `embedrelay.tenant_id` context;
2. validate actor and canonical fingerprint;
3. insert the append-only audit intent;
4. insert the tenant/fingerprint registration;
5. commit both or neither.

The deferred foreign key permits the deliberate audit-first insertion order while still requiring a matching registry row at transaction commit.

The current item-level write contract is **insert-only and duplicate-rejecting; it is not an UPSERT**. A second same-tenant/fingerprint insertion raises the unique-key outcome. Under two concurrent attempts, exactly one transaction can commit; the losing transaction rolls back its audit intent with the failed registration. If a future network API requires retry idempotency rather than duplicate rejection, it must introduce a stable request/idempotency key and a separate test-first contract instead of heuristic conflict handling.

### Tenant isolation

Both current tables:

- enable RLS;
- force RLS;
- use an explicit `embedrelay.tenant_id` session setting in `USING` and `WITH CHECK` policy expressions;
- are exercised under a non-superuser, non-`BYPASSRLS` test role;
- expose zero rows for another tenant and deny cross-tenant insertion.

A missing tenant context is not treated as a wildcard. The registration function fails closed and the policy expression cannot authorize a tenant row from a missing value.

### Append-only evidence

Ordinary `UPDATE`, `DELETE`, and `TRUNCATE` operations on both current relations are rejected by trigger functions. PostgreSQL supports statement-level triggers on `TRUNCATE`; the contract tests that boundary explicitly. Public/default privileges are revoked and service-role access must be granted deliberately.

The down migration is destructive by definition and therefore refuses to run unless `embedrelay.allow_destructive_rollback=on` is explicitly set. This operator migration escape hatch is not an application mutation surface.

## Concurrency and performance boundary

The only expected serialization point today is the unique `(tenant_id, space_fingerprint)` key for identical registrations. There is no global application lock. This is deliberate because two attempts to create the exact same domain fact must establish one durable winner.

No hash partitioning, tenant sharding, read/write split, replica topology, or CQRS is introduced without measured evidence. If a high-volume tenant creates hot uniqueness pages or registry reads dominate later workloads, mitigation must be benchmarked while preserving forced RLS, one-item transaction boundaries, and the same uniqueness/audit invariant.

## Failure and recovery

Expected fail-closed outcomes include:

- missing tenant context → registration denied;
- malformed/noncanonical fingerprint → invalid parameter;
- another tenant's row → invisible/denied through RLS;
- duplicate or concurrent identical registration → one unique-key winner only;
- ordinary update/delete/truncate → rejected as append-only violation;
- destructive down migration without explicit opt-in → rejected.

The current down/up migration contract proves schema rollback/reapplication behavior only. It does **not** prove backup, restore, PITR, RPO, or RTO. Measured backup/restore acceptance remains a separate P1 commercialization gap and must be added before persistence can be described as operationally recoverable for production.

## Security and governance interpretation

Embeddings and their provenance can be sensitive; a space fingerprint or UUID is not an authorization token. This boundary therefore keeps tenant authority explicit rather than inferring it from object identifiers, vector content, or UUIDv7 timestamps.

The active-PR RLS/append-only evidence supports a design direction toward auditable CSAP/SOC 2 controls but does not constitute certification. Broader privileged-role governance, KMS/encryption, retention/deletion/export, residency, incident evidence, and service authentication remain future implementation responsibilities.

## Exact-head acceptance

A current PR head may promote this boundary only when all of the following are true for that same head:

- `cargo test --workspace --locked` passes;
- PostgreSQL 18.6 starts and `tests/postgres_registry_contract.sh` passes;
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
