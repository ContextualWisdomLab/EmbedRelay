# Architecture decision records

These records state EmbedRelay product authority on the default branch. They
are decisions, not evidence that a runtime is present on `main`.

| ADR | Status | Decision |
| --- | --- | --- |
| [0001](0001-product-authority-boundary.md) | Proposed | EmbedRelay owns embedding continuity; RankWeave owns retrieval fusion; contextual-orchestrator owns LLM routing |
| [0002](0002-embedding-space-continuity.md) | Proposed | Treat cross-model mapping as a measured, reversible migration bridge |
| [0003](0003-published-contract-consumption.md) | Proposed | Hosts consume versioned published contracts; no sibling checkout |

Semantic-unit embedding chunking is out of product scope, so there is no ADR
0004 for it.

Verified sources used by these ADRs are listed in [`../REFERENCES.md`](../REFERENCES.md).
