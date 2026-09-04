# EmbedRelay API and Port Contract

**Status:** Accepted target contract; current PR #1 exposes Rust domain APIs only.  
**Last reviewed:** 2026-08-09

## Principles

- Every request is tenant-scoped and versioned.
- Space, adapter, migration, and vector origins are explicit opaque identifiers.
- Raw vectors from different spaces are never implicitly compared.
- Translation may abstain; abstention is not an HTTP/SDK transport failure.
- State-changing requests are idempotent and auditable.
- External provider/vector-store details remain behind adapters.

## Target control-plane operations

```text
POST /v1/embedding-spaces
GET  /v1/embedding-spaces/{embedding_space_id}
POST /v1/adapters
GET  /v1/adapters/{adapter_artifact_id}
POST /v1/adapters/{adapter_artifact_id}/evaluations
POST /v1/migrations
GET  /v1/migrations/{migration_plan_id}
POST /v1/migrations/{migration_plan_id}/stages
POST /v1/migrations/{migration_plan_id}/rollback
GET  /v1/migrations/{migration_plan_id}/evidence
```

These HTTP paths are target service semantics, not current deployed endpoints.

## Target data-plane operations

```text
translate_vector(source_space_id, target_space_id, input_role, vector, policy)
query_migration(migration_plan_id, query_input, top_k, policy)
submit_backfill(migration_plan_id, source_record_refs)
```

A successful translation result includes:

- source/target space IDs;
- adapter artifact ID/digest;
- vector origin=`translated`;
- confidence/calibration policy version;
- bounded confidence/evidence fields;
- abstention status/reason when no vector is returned.

## Error/abstention taxonomy

Transport/domain errors include invalid vector, unknown/inactive space, tenant mismatch, invalid role, adapter unavailable, artifact integrity failure, policy denial, idempotency conflict, and migration-state conflict.

Normal abstentions include low confidence, OOD, source-only fallback, and native-reencode-required. Clients must not collapse abstention into a zero vector or silent source-space comparison.

## Idempotency

Create/mutate operations use a caller-provided idempotency key scoped to tenant + operation. Replaying the same semantic request returns the existing result; reusing a key for a different request fails closed.

## Schema/versioning

Public service contracts are versioned independently from adapter artifact schema and embedding-space canonicalization version. Changing canonical fingerprint semantics, artifact manifest schema, or vector wire precision requires explicit compatibility/migration guidance.

## Current Rust M1 boundary

PR #1 currently provides in-process Rust types/functions for canonical space manifests/fingerprints, vector validation, UUIDv7 identifiers, and tenant registration/audit intent. It does not yet provide HTTP/RPC endpoints. Service APIs must wrap those domain contracts rather than reimplement numerical or tenant invariants.

## Provider/vector-store port requirements

Ports must state exact capabilities, batch/size limits, score direction/range semantics, supported roles/metrics, retry/idempotency behavior, and error classification. Provider responses are validated against the registered target space before acceptance.

## Security

Tenant/actor authorization is transport/service responsibility and is never inferred from vector content, UUID timestamp, model name, or space fingerprint. Raw vector/anchor export requires explicit policy and audit.