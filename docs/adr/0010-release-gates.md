# ADR-0010: Limit production composition and require evidence-based release gates

**Status:** Accepted  
**Date:** 2026-08-09

## Context

Chaining multiple approximate adapters compounds error and makes confidence harder to interpret. A numerically successful transform is also insufficient if retrieval quality, calibration, tenant isolation, migrations, or rollback are unproven.

## Decision

Production translation uses one adapter hop by default. Multi-hop composition remains experimental unless separately accepted with end-to-end evidence. Release/cutover requires exact integrated evidence for vector/retrieval fidelity, OOD/calibration, tenant/security controls, migrations/rollback, exact coverage/docstrings, operability, SBOM/provenance, and independent review.

## Consequences

Operators receive explicit failure/abstention rather than opaque chains. One green unit test, vector cosine metric, or model judgment cannot authorize a migration cutover or release.