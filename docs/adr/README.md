# EmbedRelay Architecture Decision Record Index

`Accepted` means a decision governs target architecture; it does not imply the capability is already implemented. PRD/TRD/Architecture/ERD state implementation maturity explicitly.

| ADR | Decision | Status |
|---|---|---|
| [0001](0001-product-boundary.md) | Migration bridge converging to target-native embeddings | Accepted |
| [0002](0002-space-fingerprint.md) | Immutable canonical embedding-space fingerprint | Accepted |
| [0003](0003-directed-adapters.md) | Directional, role-specific adapters | Accepted |
| [0004](0004-algorithm-portfolio.md) | Tiered production/advanced/experimental algorithm portfolio | Accepted |
| [0005](0005-dual-index-native-backfill.md) | Dual-index transition with target-native backfill | Accepted |
| [0006](0006-rust-compute-plane.md) | Rust production arithmetic with CPU reference/GPU parity | Accepted |
| [0007](0007-confidence-abstention.md) | Confidence gating and explicit abstention | Accepted |
| [0008](0008-provider-neutral-ports.md) | Provider/vector-store-neutral ports | Accepted |
| [0009](0009-provenance-security.md) | Sensitive-vector/adapter provenance and security | Accepted |
| [0010](0010-release-gates.md) | One-hop production default and evidence-based release gates | Accepted |

Every implementation PR must map affected decisions to exact tests/evaluation evidence. A future incompatible decision uses a new ADR and marks the old record `Superseded`; do not rewrite historical rationale.