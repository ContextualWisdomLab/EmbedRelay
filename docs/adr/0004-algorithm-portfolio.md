# ADR-0004: Use a tiered adapter algorithm portfolio

**Status:** Accepted  
**Date:** 2026-08-09

## Context

No single transformation family is uniformly appropriate across near-isometric model revisions, domain shifts, sparse anchors, multi-model settings, and unpaired recovery. Automatically escalating to the most complex method would make failure modes and validation harder to understand.

## Decision

Production P0 starts with the simplest evidence-sufficient family: orthogonal Procrustes, regularized linear/ridge, low-rank affine, then bounded residual MLP when residual diagnostics justify nonlinearity. Mixture/local-isometry approaches are P1 advanced. Unpaired bidirectional translation remains experimental until separately accepted.

## Consequences

Model complexity must earn its way through held-out retrieval, OOD, calibration, stability, and security evidence. Experimental algorithms cannot be automatic cutover authorities.