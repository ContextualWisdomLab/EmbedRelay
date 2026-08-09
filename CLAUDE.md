# EmbedRelay Development Context

Read `AGENTS.md` first. The canonical documentation graph is PRD → TRD → Architecture/UML/ERD → API/ADRs → Security/Threat/Test/Operability/Traceability.

Core invariants:

1. `embedding_space_id` compatibility is defined by the complete canonical space fingerprint, never dimension alone.
2. Adapters are directional and role-specific.
3. Translation is fidelity-bounded migration infrastructure, not exact/native equivalence.
4. Low-confidence or OOD cases can abstain.
5. Raw scores from incompatible spaces are not averaged; use rank-level fusion or separately evaluated reranking.
6. Production composition defaults to one adapter hop.
7. Target-native backfill is the preferred terminal migration state.
8. Production arithmetic is Rust-first; CPU is the reference and GPU paths require parity/recovery evidence.
9. Tenant authority is explicit; UUID timestamps and vector contents carry no authorization semantics.
10. Current PR #1 is storage-independent. PostgreSQL/RLS/durable audit, adapter training, routing, backfill, provider/vector-store ports, and GPU compute remain planned until implemented and verified.

When a source change affects these invariants, update the applicable ADR and the canonical product/technical documentation in the same PR.