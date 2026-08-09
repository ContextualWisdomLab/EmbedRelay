# ADR-0003: Model adapters as directional, role-specific artifacts

**Status:** Accepted  
**Date:** 2026-08-09

## Context

A mapping trained from embedding space A to B does not imply a correct inverse B to A. Query/document roles can also use different prefixes, training objectives, and geometries.

## Decision

Adapter identity includes source space, target space, input role, algorithm/version, and artifact digest. Reverse direction is a separately trained/evaluated artifact. Query and document adapters are separate by default.

## Consequences

APIs never infer an inverse adapter. Evaluation and confidence are directional. Migration plans must state which adapter is used on each query/corpus path.