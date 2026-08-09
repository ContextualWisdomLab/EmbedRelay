# ADR-0010: Limit production composition and require evidence-based release gates

**Status:** Accepted  
**Date:** 2026-08-09

## Context

Chaining multiple approximate adapters compounds transformation error, obscures provenance, and makes confidence harder to calibrate. A numerically successful transformation is also insufficient if retrieval quality, OOD behavior, tenancy, artifact integrity, migrations, rollback, operability, or reproducibility are unproven. Release policy must therefore bind product, numerical, security, persistence, and operational evidence to one exact integrated revision.

## Decision drivers

- bound approximation depth and explainability;
- make all production acceptance evidence exact-revision and artifact-bound;
- prevent local/partial/model-only evidence from authorizing cutover;
- require realistic retrieval and OOD/calibration evidence, not vector similarity alone;
- preserve independent review, rollback, supply-chain, and operational gates.

## Alternatives considered

1. **Allow arbitrary adapter chains when each hop is individually approved.** Rejected because end-to-end error/confidence is not the product of independent hop approvals.
2. **Release on vector-space metrics alone.** Rejected because retrieval behavior and operational/security controls can still fail.
3. **Treat aggregate green workflow conclusions as sufficient.** Rejected when required steps are skipped, stale, predecessor-head, or synthetic-only.
4. **One-hop production default plus exact integrated multi-dimensional release evidence.** Selected as the bounded, auditable policy.

## Decision

Production translation uses one adapter hop by default. Multi-hop composition is experimental until a separate ADR accepts a bounded composition regime with end-to-end calibration/retrieval/security evidence. A release or migration cutover requires one unchanged exact integrated head and immutable artifacts that satisfy applicable vector/retrieval fidelity, native/source baselines, OOD/calibration/abstention, tenant/security/privacy, persistence/migration/rollback, coverage/docs, compatibility, operability/SLO/recovery, SBOM/provenance/reproducibility, artifact integrity, and independent-review gates.

## Consequences

Some apparently useful routes will abstain instead of composing. Product teams must maintain a real evaluation/release evidence bundle. A passing unit suite, one cosine benchmark, PR-body claim, automated reviewer comment, or model judgment cannot authorize a cutover or release. Experimental chaining remains clearly labeled and cannot silently enter production.

## Failure and recovery

Any required gate that is failed, absent, queued, skipped-required, stale, predecessor-head, synthetic-only where exact source is required, integrity-invalid, or unreviewed is non-passing. A release/cutover remains blocked while other non-conflicting work continues. Recovery fixes the owning boundary and regenerates evidence on the unchanged candidate rather than bypassing or relabeling the gate.

## Security and governance impact

Release authority remains separate from model/agent training and review credentials. No self-approval or synthesized reviewer evidence is accepted. Supply-chain artifacts, migrations, adapter weights, configuration, and provenance are immutable/digest-bound as applicable. Tenant/security/privacy controls are release criteria, not post-release hardening.

## Verification and acceptance evidence

The release evidence manifest records exact source head, live protected base/integration identity, dependency locks, tests/coverage/docstrings, numerical recovery/parity where material, retrieval/OOD/calibration results, migrations/rollback/recovery, security scans, SBOM/provenance/reproducible-build identities, compatibility matrix, artifact digests/signatures, operator acceptance, independent approval, and post-publication smoke evidence. Required skipped or infrastructure-only steps remain explicitly non-passing.

## Migration and rollback

Migration cutover applies the same evidence discipline at each stage. Rollback selects a previously accepted adapter/routing/schema/runtime bundle whose artifacts and compatibility remain verifiable. Release rollback never rewrites historical evidence or declares an incompatible artifact equivalent; it publishes/restores a separately identified accepted state.

## Supersession

A later ADR may permit bounded multi-hop composition or change release evidence only after end-to-end error propagation, calibration, retrieval, security, operability, and rollback are proven at least as strongly. Any relaxation must be explicit and cannot retroactively promote prior experimental evidence.