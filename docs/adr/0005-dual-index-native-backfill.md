# ADR-0005: Use dual-index transition and target-native backfill

**Status:** Accepted  
**Date:** 2026-08-09

## Context

Immediate replacement of a large legacy index creates availability, cost, and rollback risk. Keeping translated vectors forever creates unbounded fidelity debt. During transition, source and target indexes can expose different score scales and semantics, so naïve score averaging can introduce another compatibility defect.

## Decision drivers

- maintain retrieval availability during migration;
- provide measurable canary/progressive cutover and fast rollback;
- avoid cross-space raw-score arithmetic;
- make native-backfill debt visible and exhaustible;
- support partial source-data availability and provider quotas;
- preserve explicit origin/provenance per result and vector.

## Alternatives considered

1. **Big-bang reindex and switch.** Rejected as the default because outage, quota, cost, and rollback blast radius are unnecessarily large.
2. **Translate the legacy corpus once and retire source immediately.** Rejected because translated vectors remain approximations and remove a critical rollback/native baseline.
3. **Query both indexes and average raw similarity scores.** Rejected because incompatible score distributions are not commensurate by default.
4. **Bounded dual-index transition plus native backfill.** Selected for reversibility and measurable convergence.

## Decision

Migration uses bounded source/target index coexistence, explicit source/target space bindings, rank-level fusion by default (or a separately evaluated reranker), canary/progressive traffic stages, rollback windows, and prioritized target-native backfill. The migration reaches its preferred terminal state only when eligible records are target-native and source-retirement evidence is satisfied.

## Consequences

Operators incur temporary dual storage/query cost and must monitor two index paths. Every result and vector records origin. Backfill prioritization becomes an operational product feature. Source index/data retention is governed by rollback criteria rather than by the moment target traffic first exceeds 50%.

## Failure and recovery

If target latency/errors, retrieval fidelity, confidence calibration, provenance reconciliation, provider identity, or backfill integrity crosses a stop threshold, cutover progression freezes and routing returns to the last accepted source/dual stage. Recovery repairs the owning path and resumes only after fresh shadow/canary evidence.

## Security and governance impact

Dual operation doubles some authority surfaces: tenant isolation, provider/vector-store credentials, export/retention, and audit events must be enforced independently on each path. Source retention is not permission to retain data indefinitely; the rollback window remains purpose- and policy-bound.

## Verification and acceptance evidence

Required evidence includes rank-fusion/reranker correctness, source/target isolation, canary traffic accounting, target-native overlap/Recall@k/MRR/NDCG as applicable, OOD/calibration slices, rollback under injected target failure, idempotent backfill/replay, origin reconciliation, capacity/SLO evidence, and exact integrated security/release gates.

## Migration and rollback

The state path is planned → evaluated/shadow → dual-index → canary → progressive cutover → target-primary → native backfill → source retention window → completed. Rollback moves only to a previously accepted routing state and does not delete target evidence. Source retirement is a separately audited transition after rollback acceptance.

## Supersession

A later ADR may replace dual-index routing only if it provides equivalent availability, provenance, native convergence, and rollback evidence. Any new score-fusion method requires its own evaluation contract rather than inheriting approval from this ADR.