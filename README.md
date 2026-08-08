# EmbedRelay

Embedding continuity infrastructure for safe cross-model vector migration.

## Current M1 contract

EmbedRelay is pre-release and the first milestone remains under protected review. The current Rust contract provides:

- canonical embedding-space fingerprints that change when model revision, role, preprocessing, normalization, dimensionality, precision, metric, or other material space identity changes;
- fail-closed `float32` vector validation bound to that complete space identity;
- opaque RFC 9562 UUIDv7 identifiers for tenant registry and future durable audit keys; and
- a tenant-isolated audit-before-mutation registry contract: duplicate same-tenant registrations fail closed, accepted audit intent precedes state visibility, audit rejection leaves registry state unchanged, and equal space fingerprints remain isolated across tenants.

The registry implementation in this milestone is a storage-independent Rust reference boundary. Durable PostgreSQL persistence, forced RLS, append-only audit storage, transactional concurrency enforcement, migration, and rollback evidence remain later M1 work and are not implied by the in-memory contract.

UUIDv7 values are identifiers only. Their timestamp bits never establish tenant membership, authorization, provenance, or business chronology; those remain explicit policy and audit fields.

The repository uses test-first development. Every production head must regenerate exact line, region, function, and branch coverage and must not reuse predecessor-head CI or review evidence.
