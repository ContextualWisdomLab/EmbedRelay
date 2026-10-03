# EmbedRelay Architecture Decision Record Index

Every decision remains `Proposed` while the governing PR stack is unmerged. PRD/TRD/Architecture/ERD state implementation maturity explicitly.

| ADR | Decision | Status |
|---|---|---|
| [0001](0001-product-authority-boundary.md) | Product and authority boundary | Proposed |
| [0002](0002-embedding-space-continuity.md) | Embedding-space continuity and cross-model vector migration | Proposed |
| [0003](0003-published-contract-consumption.md) | Published-contract consumption and MSA 따로 또 같이 | Proposed |
| [0004](0004-product-boundary.md) | Migration bridge converging to target-native embeddings | Proposed |
| [0005](0005-space-fingerprint.md) | Immutable canonical embedding-space fingerprint | Proposed |
| [0006](0006-directed-adapters.md) | Directional, role-specific adapters | Proposed |
| [0007](0007-algorithm-portfolio.md) | Tiered production/advanced/experimental algorithm portfolio | Proposed |
| [0008](0008-dual-index-native-backfill.md) | Dual-index transition with target-native backfill | Proposed |
| [0009](0009-rust-compute-plane.md) | Rust production arithmetic with CPU reference/GPU parity | Proposed |
| [0010](0010-confidence-abstention.md) | Confidence gating and explicit abstention | Proposed |
| [0011](0011-provider-neutral-ports.md) | Provider/vector-store-neutral ports | Proposed |
| [0012](0012-provenance-security.md) | Sensitive-vector/adapter provenance and security | Proposed |
| [0013](0013-release-gates.md) | One-hop production default and evidence-based release gates | Proposed |

Every implementation PR must map affected decisions to exact tests/evaluation evidence. A future incompatible decision uses a new ADR and marks the old record `Superseded`; do not rewrite historical rationale.
