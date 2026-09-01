# EmbedRelay Development Context

Read `AGENTS.md` first. The canonical documentation graph is PRD → TRD → Architecture/UML/ERD → API/ADRs → Security/Threat/Test/Operability/Traceability → `docs/product-technical-gap-baseline.md`.

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
10. Current PR #1 includes a narrow active-PR PostgreSQL 18.x persistence slice for `tenant_space_registry` and `space_registration_audit`, with forced tenant RLS, append-only mutation denial, audit-first transactional registration, deterministic duplicate/concurrent rejection, guarded rollback, and PostgreSQL 18.6 contract CI. It is not protected-main or release evidence until the current exact head passes all required checks/reviews.
11. The physical M1 registration contract is insert-only and duplicate-rejecting, not an implicit UPSERT. A future replay-idempotency API requires a stable request key and explicit tests.
12. Full canonical-manifest persistence, backup/restore acceptance, adapter training/evaluation, routing, backfill, provider/vector-store ports, service/admin roles, and GPU compute remain incomplete/planned until implemented and verified.
13. Private PostgreSQL objects are not cross-repository integration contracts; ContextualWisdomLab integrations use typed public ports or anti-corruption layers.
14. Predecessor-head checks, comments, or mergeability never promote a later exact head. Do not self-approve or weaken required governance gates.

When a source change affects these invariants, update the applicable ADR/doctoring record and canonical product/technical documentation in the same PR. Before every branch write, re-fetch current PR/head state and preserve concurrent writer commits without force-push or destructive rebases.
