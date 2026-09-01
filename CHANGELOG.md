# Changelog

All notable EmbedRelay changes are recorded here. This repository is pre-release; entries under **Unreleased** are not a published artifact or production claim.

## Unreleased

### Added

- Buyer- and integrator-oriented README for embedding-space continuity and governed cross-model migration.
- Apache License 2.0 repository grant after provenance review.
- Embedding-space identity, migration-governance, service-contract, and identity/authorization architecture decisions.
- Draft 2020-12 conversion-response payload contract with typed converted, abstained, and error outcomes.
- Dependency-free documentation contract regression tests for canonical identifiers and digest constraints.
- Regression coverage requiring the canonical repository baselines and their documentation-index links to remain present, non-empty, and consistent with Rust numerical ownership, fail-closed threshold provenance, and multiword persistence naming.
- Exact-head `Documentation Quality` GitHub Actions gate using explicit Ubuntu 24.04, immutable checkout pinning, exact-SHA verification, documentation regression execution, and clean diff validation.
- Repository `AGENTS.md` and `CLAUDE.md` development boundaries.
- Root `ARCHITECTURE.md` context map separating EmbedRelay from RankWeave, contextual-orchestrator, keyverse, model providers, vector stores, and ingest/retrieval hosts.
- `docs/product-technical-gap-baseline.md` commercialization ledger and exact-head verification policy.

### Security

- Explicit fail-closed tenant/actor authorization boundary for future executable service work.
- Explicit prohibition on storing raw bearer tokens/provider credentials as domain attributes or treating sibling repository/database access as an integration contract.

### Changed

- Clarified that the current branch is documentation/design plus pre-release payload-contract evidence only; it does not claim an executable service, package, deployment, benchmark, customer, certification, or released artifact.
