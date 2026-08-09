# EmbedRelay Development Rules

## Product truth

EmbedRelay is embedding continuity infrastructure. Documentation must distinguish implemented source from planned architecture. Do not call planned PostgreSQL, adapter fitting, routing, backfill, or GPU components implemented until current protected-main evidence proves them.

## Numerical rules

- Production transformation arithmetic is Rust-first.
- Do not compare raw vectors from different embedding spaces.
- Equal dimensions do not prove compatibility.
- Adapter direction and input role are explicit.
- CPU is the reference implementation; an accelerator path requires parity and recovery evidence.
- Low-confidence translation may abstain.
- Production composition defaults to one adapter hop.

## Development workflow

Use test-first changes for behavior. Keep exact production coverage and public Rust documentation gates. Never treat queued, cancelled, stale, skipped, or predecessor-head checks as passing. Do not weaken tests to obtain a green result.

## Data and identifiers

Use descriptive two-or-more-word `snake_case` persistent names. UUIDv7 is an opaque identifier shape, not authorization or business chronology. Tenant membership and authorization remain explicit. Treat vectors, anchors, query logs, adapter artifacts, and evaluation outputs as controlled data assets.

## Persistence

A PostgreSQL implementation requires reviewed migrations and rollback, tenant isolation, concurrency/idempotency tests, durable audit semantics, and recovery evidence. Current PR #1 is storage-independent.

## Documentation

Material changes reconcile PRD, TRD, Architecture, UML, ERD, API, ADRs, Security, Threat Model, Test Strategy, Operability, Traceability, README, and CHANGELOG as applicable. Accepted target architecture is not the same as implementation maturity.

## Ecosystem

Preserve standalone operation and use typed provider-neutral ports for optional CWL integrations. Do not access another product's private database directly.

## Release

Release only from an exact integrated protected head after required CI, review, numerical fidelity, migration/rollback, packaging, provenance, and operating evidence passes.