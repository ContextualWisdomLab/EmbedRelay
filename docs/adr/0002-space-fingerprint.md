# ADR-0002: Use immutable canonical embedding-space fingerprints

**Status:** Accepted  
**Date:** 2026-08-09

## Context

Provider/model names and vector dimensions are insufficient compatibility identities. Revision, input role, preprocessing, normalization, scalar precision, metric, and other encoding parameters can change geometry while dimensions remain equal.

## Decision

Every embedding space is identified by a versioned canonical manifest and deterministic fingerprint. Once referenced by durable vectors/adapters/migrations, that identity is immutable. Observed output drift creates a distinct or quarantined space rather than mutating the existing identity.

## Consequences

Metric comparison can fail closed before corrupted retrieval. Canonicalization itself is a versioned contract. Registry storage and APIs must retain the complete manifest/fingerprint lineage.