# ADR-0001: Treat translation as a migration bridge

**Status:** Accepted  
**Date:** 2026-08-09

## Context

Embedding models change because of end-of-service, quality, cost, regional availability, security, policy, or provider revision. Full immediate re-embedding may be operationally or economically infeasible, while direct comparison of incompatible spaces can silently corrupt retrieval. Cross-space transformation can preserve useful continuity, but a transformed vector is not automatically equivalent to a target-native embedding.

## Decision drivers

- preserve retrieval availability during model change;
- avoid false mathematical/native-equivalence claims;
- keep every cutover reversible until evidence is sufficient;
- support source-data loss or delayed native backfill without hiding residual risk;
- remain provider and vector-store neutral;
- give operators explicit provenance, confidence, and terminal-state semantics.

## Alternatives considered

1. **Require immediate full re-embedding.** Rejected as the only product mode because it creates avoidable outage/cost risk and cannot help when source content is temporarily unavailable.
2. **Treat translated vectors as permanent target-native replacements.** Rejected because approximation error and OOD behavior remain material and must stay visible.
3. **Promise a universal exact translator.** Rejected because arbitrary embedding spaces need not be bijective or information-equivalent.
4. **Use translation as a bounded migration bridge toward native target state.** Selected because it preserves continuity while keeping fidelity claims measurable and reversible.

## Decision

EmbedRelay is continuity and migration infrastructure. Every translated vector carries explicit source space, target space, directional adapter, approximation origin, evaluation/confidence evidence, and policy provenance. The desired terminal state is target-native backfill whenever source data and policy permit it. Permanent translated state is exceptional and requires an explicit accepted policy plus continuing evaluation.

## Consequences

- product APIs and operator views must distinguish `native`, `translated`, `reconstructed`, and experimentally permitted `composed` origin;
- migration control must retain the source path through a verified rollback window;
- vector-space fit alone is insufficient for cutover; retrieval-level and OOD/calibration evidence are required;
- backfill is a first-class product capability rather than deferred cleanup;
- some migrations legitimately abstain or remain dual-index instead of completing automatically.

## Failure and recovery

If adapter fidelity, calibration, provider identity, artifact integrity, target-index reliability, or tenant-policy evidence fails, progression stops. Routing returns to the last accepted source or dual-index stage; target evidence is retained for RCA and is not silently deleted. Recovery requires correcting the owning boundary and re-running held-out evaluation before progression resumes.

## Security and governance impact

Translation does not grant authority to source content, vectors, or target indexes. Embeddings, anchors, adapter artifacts, and evaluation data remain potentially sensitive tenant assets. A model or autonomous agent may propose an adapter or analysis but cannot independently authorize production cutover, retention exceptions, or release.

## Verification and acceptance evidence

Acceptance requires versioned source/target space identity, directional adapter provenance, held-out transformation evidence, native-target/source baselines, retrieval metrics, OOD slices, confidence/abstention evidence, rollback rehearsal, tenant/security tests, and exact integrated release checks. Planning prose or a successful vector cosine benchmark alone is insufficient.

## Migration and rollback

Migration proceeds through inventory, registration, evaluation/shadow, dual-index, bounded canary, progressive cutover, target-primary, native backfill, and source-retention-window stages. Rollback returns routing to the last accepted stage without rewriting historical evidence. Source collections are retired only after the configured rollback and reconciliation criteria are satisfied.

## Supersession

This decision remains governing until a later accepted ADR, backed by retrieval and security evidence, changes the terminal-state or migration-bridge product boundary. Any such ADR must preserve historical origin/provenance semantics for existing translated vectors rather than silently relabeling them native.