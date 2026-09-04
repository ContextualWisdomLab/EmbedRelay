# ADR-0009: Preserve vector and adapter provenance

**Status:** Accepted  
**Date:** 2026-08-09

## Context

Embedding vectors, paired anchors, query logs, evaluation data, adapter weights, provider metadata, and migration outputs can contain or reveal business-sensitive information. Operators must also be able to prove which tenant, source/target spaces, training/evaluation evidence, confidence policy, artifact, provider/index binding, and migration stage produced a translated result.

## Decision drivers

- make every compatibility/cutover decision auditable and reproducible;
- avoid treating vectors as anonymous or self-authorizing data;
- minimize retained protected payloads while preserving sufficient evidence;
- prevent artifact substitution, anchor poisoning, cross-tenant reuse, and rollback tampering;
- support purpose-bound retention/export and incident investigation.

## Alternatives considered

1. **Store vectors/artifacts without lineage because hashes are sufficient.** Rejected because hashes do not explain authority, tenant, model space, training source, evaluation, or policy.
2. **Copy all source payloads into a central audit store.** Rejected because it expands confidentiality, retention, and breach blast radius unnecessarily.
3. **Treat embeddings as non-sensitive derived data.** Rejected because inversion/linkage and proprietary information risks remain material.
4. **Tenant-scoped minimal provenance plus immutable digest-bound artifacts.** Selected as the balance between explainability and data minimization.

## Decision

EmbedRelay records tenant-scoped provenance for spaces, vectors/references, anchor datasets, adapters, evaluations, confidence policies, migrations, index/provider bindings, backfill, and translated/native origins. Released adapter/evaluation artifacts are immutable and digest-bound; signatures/KMS-backed integrity are added when the artifact store becomes executable. Authorization is explicit and never derived from vector contents, UUID timestamps, model names, or fingerprints.

## Consequences

Promotion and cutover require provenance completeness. Cross-tenant artifact reuse is an explicit policy decision with independent authorization/evidence rather than an optimization inferred from identical fingerprints. Audit records carry bounded metadata/evidence digests rather than unnecessary raw vectors or source text. Data-governance and retention work becomes a release prerequisite for durable milestones.

## Failure and recovery

Missing lineage, digest mismatch, signature/integrity failure, poisoned/unauthorized anchor evidence, cross-tenant mismatch, or audit persistence failure prevents state promotion. Recovery restores from trusted immutable evidence, quarantines suspect artifacts/anchors, reruns evaluation as needed, and records the incident; historical audit evidence is not rewritten to hide the failure.

## Security and governance impact

Embeddings, anchors, weights, query logs, and migration artifacts are treated as potentially sensitive tenant assets. Controls include least privilege, encryption/KMS where persisted, bounded retention/export, purpose-bound service identity, append-only audit target semantics, artifact integrity, and explicit privileged-access evidence. Ordinary logs exclude raw vectors, source text, credentials, and protected payloads.

## Verification and acceptance evidence

Tests must cover cross-tenant denial, missing/wrong provenance, artifact digest substitution, replay/idempotency, audit-before-visible-state, append-only behavior when durable, poisoned/duplicate anchor handling, export/retention policy boundaries, backup/restore evidence continuity, and complete traceability from translated result to source/target/adapter/evaluation/policy. Security reviews include inversion/extraction and artifact/anchor threat paths.

## Migration and rollback

Persistence migrations must preserve provenance identifiers and audit immutability across schema versions. Rollback may restore an earlier runtime/schema version only when it can continue interpreting historical evidence; it must never discard or relabel vector origin. Artifact/key rotation creates new versioned evidence rather than mutating released history.

## Supersession

A later ADR may refine storage, signing, privacy, or governance mechanisms only if tenant isolation, origin traceability, data minimization, audit explainability, and historical readability remain at least as strong. Any reduction in retained evidence requires proof that rollback/incident/release accountability is still sufficient.