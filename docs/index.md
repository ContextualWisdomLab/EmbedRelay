# EmbedRelay

EmbedRelay is ContextualWisdomLab's embedding-continuity product for governed cross-model vector migration. It makes embedding-space identity, migration evidence, abstention, rollback, and target-native backfill explicit so retrieval systems can change models without treating incompatible vector spaces as interchangeable.

## Start here

- [Repository README](../README.md) — product responsibility, current maturity, integration boundary, and operator principles.
- [Architecture decision records](adr/README.md) — product authority, embedding-space continuity, and published-contract decisions.
- [Conversion response contract](contracts/conversion-response-v1.schema.json) — pre-release machine-readable converted, abstained, and error outcomes.
- [References](REFERENCES.md) — scientific and standards basis used by the design.
- [Contributing](../CONTRIBUTING.md) — contribution and repository-boundary guidance.

## Current maturity

EmbedRelay is documentation-first today. This documentation site describes the reviewed product and integration contracts; it does not claim an executable service, package, production endpoint, benchmark, or release before those artifacts exist.

## Ecosystem boundary

EmbedRelay owns embedding-space identity and migration control. Ranking and retrieval-list evaluation belong to RankWeave; LLM routing and provider credentials belong to contextual-orchestrator; embedding runtimes and vector stores remain behind versioned external ports. Integration is through released contracts rather than sibling checkouts or shared private databases.
