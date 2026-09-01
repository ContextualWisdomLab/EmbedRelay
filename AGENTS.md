# EmbedRelay Development Rules

## Product truth

EmbedRelay is embedding continuity infrastructure. Documentation must distinguish active-PR source, protected-main behavior, and released product evidence. Current PR #1 includes a narrow PostgreSQL tenant registry/audit slice; do not generalize that slice into claims that the full durable control plane, adapter fitting, routing, backfill, provider ports, or GPU components are implemented.

## Numerical rules

- Production transformation arithmetic is Rust-first.
- Do not compare raw vectors from different embedding spaces.
- Equal dimensions do not prove compatibility.
- Adapter direction and input role are explicit.
- CPU is the reference implementation; an accelerator path requires parity and recovery evidence.
- Low-confidence translation may abstain.
- Production composition defaults to one adapter hop.

## Development workflow

Use test-first changes for behavior. Keep exact production coverage and public Rust documentation gates. Keep Rust dependency resolution reproducible from the tracked `Cargo.lock` and use `--locked` in CI/release-bound commands. Never treat queued, cancelled, stale, skipped, or predecessor-head checks as passing. Do not weaken tests or governance gates to obtain a green result.

Before every branch write, re-fetch the PR/head and preserve concurrent agent commits. Do not force-push or destructively rebase shared writer branches.

## Data and identifiers

Use descriptive two-or-more-word `snake_case` persistent names. UUIDv7 is an opaque identifier shape, not authorization or business chronology. Tenant membership and authorization remain explicit. Treat vectors, anchors, query logs, adapter artifacts, evaluation outputs, registry records, and audit evidence as controlled data assets.

## Persistence

Current PR #1 implements the M1 physical `tenant_space_registry` / `space_registration_audit` boundary with PostgreSQL 18.x UUIDv7 identifiers, forced tenant RLS, append-only update/delete/truncate denial, audit-first transactional registration, deterministic duplicate/concurrent rejection, guarded destructive rollback, and exact-head PostgreSQL 18.6 contract testing.

Persistence rules:

- keep transaction boundaries minimal; one registration attempt is one transaction;
- current registration is insert-only and duplicate-rejecting, **not an UPSERT**;
- if replay-safe idempotency is later required, add a stable request key and explicit test-first semantics;
- do not introduce global locks, partitioning, CQRS, or read/write splitting without measured contention/read evidence;
- preserve forced RLS and tenant isolation under any optimization;
- do not expose private database tables as cross-repository integration contracts;
- migration rollback is not backup/restore evidence; measured recovery remains required before production-recoverable claims.

## Documentation

Material changes reconcile PRD, TRD, Architecture, UML, ERD, API, ADRs, Security, Threat Model, Test Strategy, Operability, Traceability, `docs/product-technical-gap-baseline.md`, README, and CHANGELOG as applicable. Accepted target architecture is not the same as implementation maturity. Research-backed database/algorithm decisions belong in `docs/doctoring/` with primary sources and APA 7 references.

## Ecosystem

Preserve standalone operation and use typed provider-neutral ports or anti-corruption layers for optional ContextualWisdomLab integrations. Do not access another product's private database directly. Reusable supplier defects belong in the owning repository and consumers must then be revalidated.

## Release

Release only from an exact integrated protected head after required CI, independent review, numerical fidelity where applicable, PostgreSQL migration/RLS/concurrency/rollback and measured recovery evidence for persisted surfaces, packaging, SBOM/provenance, and operating evidence pass. Do not self-approve, synthesize status, or bypass central required workflows merely to merge.
