# EmbedRelay

Embedding continuity infrastructure for safe cross-model vector migration.

## Current M1 contract

EmbedRelay is pre-release and the first milestone remains under protected review. The current Rust contract provides:

- canonical embedding-space fingerprints that change when model revision, role, preprocessing, normalization, dimensionality, precision, metric, or other material space identity changes;
- fail-closed `float32` vector validation bound to that complete space identity; and
- opaque RFC 9562 UUIDv7 identifiers for future tenant registry and append-only audit keys.

UUIDv7 values are identifiers only. Their timestamp bits never establish tenant membership, authorization, provenance, or business chronology; those remain explicit policy and audit fields.

The repository uses test-first development. Every production head must regenerate exact line, region, function, and branch coverage and must not reuse predecessor-head CI or review evidence.
