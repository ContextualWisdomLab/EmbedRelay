# Canonical Manifest Persistence Boundary

**Status:** active-PR implementation evidence; exact-head CI/review promotion pending  
**Last reviewed:** 2026-09-02

## Problem

The first PostgreSQL M1 slice persisted only `(tenant_id, space_fingerprint)`. That protected the exact canonical fingerprint representation but did not make the complete immutable compatibility material durable. A buyer-facing continuity system must be able to reconstruct why two vectors are compatible without relying on an external mutable catalog, while still avoiding duplicated manifest material for every tenant.

## Decision

Persist one immutable v1 canonical manifest row per exact `space_fingerprint` in `embedrelay_registry.embedding_space_manifest`, and keep tenant ownership in the separate `tenant_space_registry` relation. This separates global immutable compatibility facts from tenant association facts and audit-event facts, preserving a narrow 3NF persistence boundary.

The manifest-bearing command `embedrelay_registry.register_tenant_space_manifest(uuid, text, jsonb)` is the M1 write path after migration 0002. It validates exactly the twelve Rust v1 material keys, their JSON/value contracts, canonical SHA-256 material hashes, and the Rust `u32` dimension range. It then independently recomputes the Rust fingerprint before allowing durable state.

The database recomputation follows the Rust contract exactly:

1. domain prefix bytes `embedrelay-space-manifest-v1\0`;
2. fields in Rust manifest order;
3. for each field, UTF-8 byte length rendered as decimal, `:`, then UTF-8 field bytes;
4. SHA-256 digest encoded as lowercase hexadecimal and prefixed with `sha256:`.

PostgreSQL 18 provides core SHA-2 binary-string functions such as `sha256(bytea)`; the official documentation states that SHA-2 functions return `bytea` and can be hex-encoded with `encode(..., 'hex')`. The persistence boundary therefore needs no `pgcrypto` extension for this independent equivalence check.

## Transaction and item-level contracts

One manifest-bearing registration is one transaction:

```text
audit intent
  -> tenant registration
  -> canonical manifest insert-or-match
  -> deferred references checked at commit
```

Tenant registration remains insert-only and duplicate-rejecting. This is deliberately not an UPSERT/replay API. Canonical manifest storage has a different item-level contract: identical immutable compatibility material may be referenced by multiple tenants, so the canonical row uses insert-or-match keyed by fingerprint and verifies every persisted material field after a conflict. A mismatch is an integrity failure, never an overwrite.

The deferred `tenant_space_registry -> embedding_space_manifest` reference lets audit-first ordering remain intact while guaranteeing that no committed tenant registration can point at absent canonical material after migration 0002.

## Authorization and privacy boundary

The canonical manifest is globally deduplicated by fingerprint but is not globally enumerable by application tenants. Forced RLS derives visibility through an `EXISTS` check on `tenant_space_registry` for the explicit `embedrelay.tenant_id` session context. Thus two tenants may safely reference the same immutable compatibility fact while an unregistered tenant sees no row.

The current manifest contains technical model/role/preprocessing identity, not customer PII. It is nevertheless treated as controlled product state because provider/model choices and processing policy can disclose deployment configuration. Ordinary update/delete/truncate operations are denied by the same append-only mutation function used by the registry/audit slice.

## Test-first traceability

- `af19815bd8da0ea38f5cd9346abe4bc9b3d4e519` — RED contract requiring durable canonical manifest material, Rust-fingerprint binding, RLS, append-only behavior, and cross-tenant canonical deduplication.
- `2dec733cbe20f021a87e95ca7923bccd2ba7261f` — exact-head CI executes the new PostgreSQL contract.
- `8aa5b3231741b6c1f5a3227c5c3f8cf15926b915` — migration 0002 and manifest-bearing registration implementation.
- `c58edc97c104bda44c2a0e020cf5ad2ec49dc4d7` — guarded rollback.
- `f1e5ddd5118f4781eefdacf59b62bd6f89596ea4` — migration lifecycle verification.
- `b4bbbf291cd69805d476ef5e5dd3c6e62ba92ae4` — logical backup/restore extended to canonical manifest material and controls.

These commits establish implementation lineage, not passing exact-head evidence. Any later commit requires a new PostgreSQL 18.6 run before promotion.

## Failure and recovery semantics

- malformed/missing/unknown manifest material: SQLSTATE `22023`, no durable state;
- caller fingerprint does not equal recomputed material fingerprint: SQLSTATE `22023`, no durable state;
- duplicate same-tenant registration: unique violation, audit intent rolls back;
- same canonical manifest used by another tenant: one canonical row, independent tenant registration/audit rows;
- conflicting stored material under the same fingerprint: integrity exception, no overwrite;
- update/delete/truncate of canonical material: SQLSTATE `55000`;
- destructive migration rollback: denied unless `embedrelay.allow_destructive_rollback=on` is explicitly set.

Logical backup/restore now verifies manifest material alongside tenant/audit identities, RLS, append-only triggers, comments, and application-role privileges. This is not production RTO/RPO, PITR, HA, encryption-at-rest, or cross-host recovery evidence.

## Research / standards references

PostgreSQL Global Development Group. (2026). *PostgreSQL 18 documentation: Binary string functions and operators*. https://www.postgresql.org/docs/18/functions-binarystring.html

PostgreSQL Global Development Group. (2026, August 13). *PostgreSQL 18.6 release notes*. https://www.postgresql.org/docs/release/18.6/
