# Changelog

All notable changes to EmbedRelay are recorded here. The project has not published its first release; entries remain under **Unreleased** until the complete release-acceptance contract is satisfied.

## Unreleased

### Added

- Strict RFC 9562 UUIDv7 identifiers for registry and audit keys. Generated identifiers are process-locally creation-ordered; external identifiers fail closed unless both the RFC variant and version-7 contract are satisfied, and parse failures do not reflect caller-controlled input.
- Fail-closed Rust `float32` embedding-vector validation bound to the complete canonical embedding-space fingerprint. The contract rejects dimension mismatches, non-finite and subnormal components, zero-norm vectors, and scalar-precision mismatches, and permits a metric operation only after both vectors prove identical embedding-space identity rather than merely matching dimensions.
- Tenant-isolated audit-before-mutation space registration. The storage-independent Rust reference contract keys registration by tenant plus complete canonical space fingerprint, rejects duplicates before emitting another intent, requires audit acceptance before state visibility, leaves state unchanged when audit recording fails, and permits equal space fingerprints to remain isolated across tenants.
- PostgreSQL 18.x M1 registry migrations for `tenant_space_registry` and `space_registration_audit`, with native UUIDv7 identifiers, unique tenant/fingerprint registration, forced RLS, append-only row/truncate protection, audit-first transactional registration, deterministic duplicate/concurrent rejection, explicit public-privilege revocation, and guarded destructive rollback.
- PostgreSQL 18.6 CI verification for missing tenant context, canonical fingerprint shape, UUIDv7 identifiers, cross-tenant denial, immutable registry/audit rows, concurrent identical registration, guarded rollback, and migration reapplication.
- A tracked Cargo lockfile plus `--locked` stable-test and LLVM-coverage execution so hosted CI cannot silently resolve a different Rust dependency graph for an exact PR head.
- Canonical PRD, TRD, architecture, UML, physical/current-plus-target ERD, API, security, threat-model, test, operability, traceability, commercialization-gap baseline, and ten-ADR documentation baselines, plus a Rust documentation contract that prevents planned adapter/migration boundaries from being misrepresented as already implemented.

### Changed

- Product, technical, architecture, ERD, traceability, and documentation-fitness truth boundaries now distinguish the active-PR PostgreSQL M1 persistence slice from the broader still-planned durable control plane and later adapter/migration product surfaces.
- Registration persistence is explicitly duplicate-rejecting rather than an implicit UPSERT. A future idempotent replay API must introduce a stable request key and a separate tested contract instead of heuristic conflict handling.

### Security

- The current M1 persistence slice requires explicit tenant session context, forces PostgreSQL RLS for its two tenant-scoped relations, denies ordinary update/delete/truncate operations, and keeps destructive rollback behind an explicit operator opt-in. These active-PR controls do not by themselves constitute protected-main, CSAP, SOC 2, or release evidence.
