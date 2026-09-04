# ADR-0004: Use a tiered adapter algorithm portfolio

**Status:** Accepted  
**Date:** 2026-08-09

## Context

No single transformation family is uniformly appropriate across near-isometric revisions, domain shifts, sparse anchors, multi-model settings, and unpaired recovery. Automatically escalating to the most complex method can improve fit on one sample while worsening interpretability, OOD behavior, calibration, resource use, poisoning resistance, and rollback confidence.

## Decision drivers

- prefer the simplest model that passes real retrieval evidence;
- make failure modes diagnosable and reproducible;
- bound training/inference cost and artifact complexity;
- keep experimental research from becoming implicit production authority;
- require complexity to improve held-out/OOD outcomes, not just training loss.

## Alternatives considered

1. **One universal neural translator.** Rejected as the default because it overstates generality and makes data/capacity/security requirements hard to bound.
2. **Linear mappings only.** Rejected as an absolute restriction because some evidenced residual structure may require bounded nonlinearity.
3. **Operator manually chooses any algorithm.** Rejected because release quality would depend on ungoverned preference.
4. **Tiered evidence-driven portfolio.** Selected because it supports conservative escalation and explicit maturity.

## Decision

Production P0 starts with the simplest evidence-sufficient family: orthogonal Procrustes, regularized linear/ridge, low-rank affine, then a bounded residual MLP only when residual diagnostics and held-out evidence justify nonlinearity. Mixture/gating and local-isometry/vector-linking approaches are P1 advanced. Unpaired/bidirectional latent translation remains P1 experimental until a separate accepted decision promotes a specific method.

## Consequences

Algorithm selection becomes an evaluated pipeline rather than a user-facing accuracy knob. Every candidate has explicit algorithm/version identity and comparable baselines. More complex models incur stronger reproducibility, calibration, resource, adversarial, and explainability obligations.

## Failure and recovery

If a candidate overfits, diverges, produces unstable neighborhoods, fails OOD/calibration gates, or exhausts bounded resources, it is rejected without replacing the last accepted artifact. Recovery returns to the last simpler accepted family or gathers better authorized anchors; it does not relax acceptance thresholds.

## Security and governance impact

Training anchors are untrusted/sensitive inputs and may be poisoned. More expressive models can memorize or leak more training information, so privacy/inversion/poisoning review scales with complexity. Experimental algorithms never receive automatic cutover or release authority.

## Verification and acceptance evidence

Each production family requires true-transform/recovery tests where identifiable, held-out geometric and neighborhood evidence, native/source retrieval baselines, realistic domain/language/OOD slices, calibration/abstention metrics, reproducible seeds/manifests, resource bounds, poisoned-anchor/adversarial tests, and exact integrated coverage/security/review evidence.

## Migration and rollback

A newly selected algorithm produces a new immutable adapter artifact; migration plans reference it explicitly. Rollback reactivates the previously accepted artifact/route and preserves both evaluation histories. Changing algorithm family never mutates an approved artifact in place.

## Supersession

A later ADR may promote an advanced or experimental family only with primary research/standards traceability plus repository-owned retrieval, OOD, calibration, security, and operational evidence. That promotion does not erase the conservative escalation rule for other model pairs.