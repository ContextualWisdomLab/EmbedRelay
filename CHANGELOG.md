# Changelog

All notable EmbedRelay changes are recorded here. This repository is pre-release; entries under **Unreleased** are not a published artifact or production claim.

## Unreleased

### Added

- Buyer- and integrator-oriented README for embedding-space continuity and governed cross-model migration.
- Apache License 2.0 repository grant after provenance review.
- Embedding-space identity, migration-governance, service-contract, and identity/authorization architecture decisions.
- Draft 2020-12 conversion-response payload contract with typed converted, abstained, and error outcomes.
- Dependency-free documentation contract regression tests for canonical identifiers and digest constraints.
- Regression coverage requiring the canonical repository baselines and their documentation-index links to remain present, non-empty, and consistent with Rust numerical ownership, fail-closed threshold provenance, multiword persistence naming, and pre-release truth boundaries.
- Exact-head `Documentation Quality` GitHub Actions gate using explicit Ubuntu 24.04, immutable checkout pinning, exact-SHA verification, documentation regression execution, and clean diff validation.
- Repository `AGENTS.md` and `CLAUDE.md` development boundaries.
- Root `ARCHITECTURE.md` context map separating EmbedRelay from RankWeave, contextual-orchestrator, keyverse, model providers, vector stores, and ingest/retrieval hosts.
- `docs/PRD.md` and `docs/TRD.md` buyer/product and Rust-first technical requirements for the first executable migration vertical.
- `docs/UML.md` target component, conversion-sequence, release-state and domain-type diagrams with explicit non-as-built labeling.
- `docs/ERD.md` conceptual future 3NF evidence model with tenant-safe references, multiword `snake_case` names, idempotency and measured partition/lock requirements; no current database is claimed.
- Root `SECURITY.md` trust-boundary/threat baseline, including tenant isolation, space confusion, malformed/OOD vector handling, rollback integrity, credential leakage and supply-chain controls.
- `docs/TEST_STRATEGY.md` covering numerical/vector, migration, OOD/abstention, tenant, persistence, HTTP, coverage and realistic test-data evidence.
- `docs/OPERABILITY.md` covering async service lifecycle, Docker/Podman/Colima compatibility, accelerator parity, telemetry, recovery and measured k6/load requirements once a runtime exists.
- `docs/product-technical-gap-baseline.md` commercialization ledger and exact-head verification policy.

### Security

- Explicit fail-closed tenant/actor authorization boundary for future executable service work.
- Explicit prohibition on storing raw bearer tokens/provider credentials as domain attributes or treating sibling repository/database access as an integration contract.

### Changed

- Clarified that the current branch is documentation/design plus pre-release payload-contract evidence only; it does not claim an executable service, package, deployment, benchmark, customer, certification, or released artifact.
