# ADR-0002: Use immutable canonical embedding-space fingerprints

**Status:** Accepted  
**Date:** 2026-08-09

## Context

Provider/model names and vector dimensions are insufficient compatibility identities. Revision, input role, preprocessing, normalization, scalar precision, metric, and other encoding parameters can change geometry while dimensions remain equal. Silent provider drift under an unchanged marketing name can therefore corrupt retrieval without an obvious schema error.

## Decision drivers

- fail closed before cross-space metric computation;
- make compatibility independent of mutable provider naming;
- retain exact provenance for vectors, adapters, evaluations, and migrations;
- distinguish query/document roles and material preprocessing changes;
- support deterministic replay and drift quarantine.

## Alternatives considered

1. **Model name + dimension.** Rejected because equal shape does not imply equal geometry.
2. **Provider-issued model ID only.** Rejected because provider identity may not encode role, preprocessing, normalization, metric, or silent revision.
3. **Empirical compatibility test without durable identity.** Rejected because runtime sampling cannot replace provenance and deterministic admission.
4. **Versioned canonical manifest + fingerprint.** Selected because it is explicit, reproducible, and suitable for fail-closed registry enforcement.

## Decision

Every embedding space is identified by a versioned canonical manifest and deterministic fingerprint. Material geometry-affecting fields are included in the manifest. Once referenced by durable vectors, adapters, evaluations, or migrations, the identity is immutable. Observed output drift creates a distinct or quarantined space instead of mutating the prior identity.

## Consequences

Canonicalization and hash-version changes become compatibility events. Registry and API layers must retain the complete manifest and fingerprint lineage. Metric operations can reject incompatible vectors before numerical work. Provider integrations must revalidate observed dimensions and other available fingerprint evidence rather than trusting labels.

## Failure and recovery

Malformed manifests, unsupported canonicalization versions, fingerprint mismatches, or observed provider drift fail closed. Existing records remain unchanged. Recovery registers a corrected/new space identity, quarantines affected observations where required, and reruns evaluation/migration decisions that depended on the prior assumption.

## Security and governance impact

A fingerprint is an integrity/compatibility identifier, not tenant authorization, authenticity, or a bearer credential. Tenant identity and access control stay explicit. Canonical manifests may expose provider/configuration metadata and must follow the repository's sensitive-asset and export policy.

## Verification and acceptance evidence

Acceptance requires deterministic canonicalization vectors, field-order independence where specified, mutation sensitivity for every material field, malformed/duplicate/unknown-field policy tests, vector compatibility tests, provider-drift regressions, and exact coverage/security evidence. Durable M1 must additionally prove immutable persistence and cross-tenant isolation.

## Migration and rollback

Fingerprint schema evolution uses an explicit canonicalization version; existing fingerprints are never silently recomputed in place. Migration creates new versioned identity records with auditable correspondence. Rollback restores the prior registry/runtime interpretation while preserving both identity generations.

## Supersession

A later ADR may change the canonical manifest schema or digest algorithm only with collision/security review, deterministic migration rules, backward readability, and evidence that existing space identities remain unambiguous. Until then this ADR governs all compatibility identity.