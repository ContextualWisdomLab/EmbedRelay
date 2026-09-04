# ADR-0003: Model adapters as directional, role-specific artifacts

**Status:** Accepted  
**Date:** 2026-08-09

## Context

A mapping trained from embedding space A to B does not imply a correct inverse B to A. Query/document roles can also use different prefixes, training objectives, normalization, truncation, and geometries. Treating direction or role as implicit can therefore create silent retrieval defects even when source and target dimensions match.

## Decision drivers

- prevent accidental inverse reuse;
- preserve query/document asymmetry;
- make training/evaluation provenance explicit;
- keep confidence and release evidence bound to the exact operation;
- support rollback without ambiguous adapter identity.

## Alternatives considered

1. **One bidirectional adapter object.** Rejected because cycle consistency does not prove inverse correctness and obscures direction-specific evidence.
2. **Infer reverse direction from matrix inversion/pseudoinverse.** Rejected as a default because transformations may be non-square, regularized, nonlinear, lossy, or poorly conditioned.
3. **Share query/document mappings whenever dimensions match.** Rejected because input roles may define materially different spaces.
4. **Separate directional, role-specific artifacts.** Selected because it makes operational authority and evidence unambiguous.

## Decision

Adapter identity includes tenant, source space, target space, input role, algorithm family/version, artifact digest, training/evaluation provenance, and confidence-policy version. Reverse direction is separately trained and evaluated. Query and document adapters are separate by default; any proven shared mapping requires explicit evidence and an accepted contract rather than inference.

## Consequences

APIs never infer an inverse adapter. Migration plans explicitly name the adapter used on each corpus/query path. Evaluation, calibration, lifecycle, artifact signing, and rollback are directional. Storage cost may increase because paired directions and roles can produce several artifacts for the same model pair.

## Failure and recovery

If a requested direction/role has no active eligible artifact, translation returns an explicit adapter-unavailable or abstention result; it never substitutes another direction. Recovery fits or activates the correct artifact after its own evaluation. Corrupt or revoked artifacts are quarantined without changing sibling directions.

## Security and governance impact

Direction and role are authorization-relevant metadata because an approved artifact for one path must not gain authority over another. Artifact digests/signatures and tenant ownership are validated before loading. Training data, weights, and evaluation evidence remain potentially sensitive and governed assets.

## Verification and acceptance evidence

Tests must reject swapped source/target IDs, wrong role, wrong tenant, wrong digest, stale lifecycle, and implicit inverse requests. Algorithm milestones require directional recovery/retrieval/OOD/calibration evidence. Production activation requires artifact-integrity and exact release evidence on the same immutable artifact.

## Migration and rollback

Migration manifests persist exact directional artifact IDs for every route. Rollback restores the previously accepted route/artifact set rather than recomputing direction. Artifact replacement creates a new immutable ID so historical migration evidence remains reproducible.

## Supersession

This ADR may be superseded only if a later accepted design proves a genuinely shared/bidirectional representation with independent forward/reverse and role-specific acceptance evidence. Existing artifacts remain interpreted under this directional contract.