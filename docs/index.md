# EmbedRelay

EmbedRelay is ContextualWisdomLab's embedding-continuity product for governed cross-model vector migration. It makes embedding-space identity, migration evidence, abstention, rollback, and target-native backfill explicit so retrieval systems can change models without treating incompatible vector spaces as interchangeable.

## Start here

- [Repository README](../README.md) — product responsibility, current maturity, integration boundary, and operator principles.
- [Product requirements](PRD.md) — buyer jobs, first executable vertical, functional/non-functional requirements, and success evidence.
- [Technical requirements](TRD.md) — Rust-first module/runtime shape, numerical/evaluation/service/persistence requirements, and verification boundary.
- [Architecture](../ARCHITECTURE.md) — DDD context map, external authority boundaries, persistence target, security boundary, and executable-release gates.
- [UML baseline](UML.md) — target component, sequence, release-state, and domain-type diagrams without as-built overclaim.
- [Conceptual ERD](ERD.md) — future 3NF tenant-safe evidence model and naming/idempotency constraints; no current database is claimed.
- [Product and technical gap baseline](product-technical-gap-baseline.md) — current commercialization gaps, exact-head verification rules, DDD invariants, and ordered next work.
- [Security baseline](../SECURITY.md) — trust boundaries, threats, tenant isolation, sensitive evidence, supply-chain controls, and compliance posture.
- [Test strategy](TEST_STRATEGY.md) — current documentation gate and first-runtime numerical, migration, tenant, persistence, HTTP, coverage, and test-data acceptance.
- [Operability baseline](OPERABILITY.md) — service lifecycle, compose/container expectations, accelerator handling, telemetry, recovery, and performance/load gates.
- [Architecture decision records](adr/README.md) — embedding-space identity, migration governance, contracts, and identity/authorization decisions.
- [Conversion response contract](contracts/conversion-response-v1.schema.json) — pre-release machine-readable converted, abstained, and error outcomes.
- [References](REFERENCES.md) — scientific and standards basis used by the design.
- [Agent development rules](../AGENTS.md) and [development context](../CLAUDE.md) — repository ownership, Rust numerical boundaries, persistence naming, and governance rules.
- [Changelog](../CHANGELOG.md) — pre-release change history without implying a published artifact.
- [Contributing](../CONTRIBUTING.md) — contribution and repository-boundary guidance.

## Current maturity

EmbedRelay is documentation-first today. This documentation site describes the reviewed product and integration contracts; it does not claim an executable service, package, production endpoint, benchmark, or release before those artifacts exist.

## Ecosystem boundary

EmbedRelay owns embedding-space identity and migration control. Ranking and retrieval-list evaluation belong to RankWeave; LLM routing and provider credentials belong to contextual-orchestrator; the ContextualWisdomLab identity-provider deployment boundary belongs to keyverse; embedding runtimes and vector stores remain behind versioned external ports. Integration is through released contracts rather than sibling checkouts or shared private databases.
