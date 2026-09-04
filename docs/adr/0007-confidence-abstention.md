# ADR-0007: Make abstention a first-class production outcome

**Status:** Accepted  
**Date:** 2026-08-09

## Context

An adapter can look adequate on average while failing on OOD queries, languages, domains, sparse neighborhoods, low-support regions, or changed provider outputs. Always returning a translated vector converts uncertainty into silent retrieval corruption and makes failure invisible to callers.

## Decision drivers

- fail visibly when evidence is insufficient;
- calibrate risk at the actual translation boundary;
- preserve safe source/native/dual fallbacks;
- expose OOD and policy failure separately from numerical success;
- make uncertainty observable to operators without leaking protected vector content.

## Alternatives considered

1. **Always translate and attach a score.** Rejected because callers may ignore the score and still receive corrupted retrieval.
2. **Use one global similarity threshold.** Rejected because confidence depends on algorithm, domain, language, role, support density, and evaluation regime.
3. **Fallback only after downstream retrieval looks bad.** Rejected because the invalid vector may already have influenced state/latency and feedback loops.
4. **Versioned confidence gate with explicit abstention outcomes.** Selected because it makes uncertainty enforceable rather than advisory.

## Decision

Every production translation is evaluated by a versioned confidence/policy gate bound to the exact adapter, source/target space, role, tenant policy, and supported evaluation regime. Low-confidence, OOD, authorization, incompatible-space, unavailable-adapter, or invalid-vector cases return explicit typed outcomes and invoke only policy-approved fallbacks.

## Consequences

Calibration and abstention curves become release evidence. APIs/metrics distinguish successful translation from every abstention/fallback class. Product availability planning must account for native encode, source-index, dual retrieval, queued backfill, or operator-review fallback capacity.

## Failure and recovery

A missing/invalid confidence model, unsupported slice, calibration drift, or confidence-policy mismatch fails closed to abstention. Recovery regenerates evaluation/calibration evidence or selects another accepted route; it does not relax the threshold silently. Sudden abstention spikes are an incident signal for provider drift, OOD traffic, or artifact/configuration failure.

## Security and governance impact

Authorization/policy abstention cannot be overridden by numerical confidence. Confidence evidence can reveal dataset/domain characteristics and is tenant-scoped where sensitive. A model cannot self-certify confidence or bypass policy based on its own generated rationale.

## Verification and acceptance evidence

Acceptance requires held-out calibration, reliability diagrams/appropriate calibration metrics, OOD and domain/language slices, error-versus-coverage/abstention curves, threshold sensitivity, fallback correctness, wrong-policy/wrong-adapter negative tests, drift alarms, and retrieval-level outcomes for accepted versus abstained cases. Thresholds and policy versions are immutable release inputs.

## Migration and rollback

Confidence-policy changes create a versioned policy state and are canaried with the associated adapter/migration stage. Rollback restores the prior accepted adapter+confidence-policy pair and corresponding fallback routing. Historical outcomes remain interpretable via recorded policy version.

## Supersession

A later ADR may change confidence/calibration methodology only with stronger held-out/OOD evidence and equivalent fail-closed fallbacks. The requirement that uncertainty can result in explicit abstention remains unless separately superseded with defensible safety evidence.