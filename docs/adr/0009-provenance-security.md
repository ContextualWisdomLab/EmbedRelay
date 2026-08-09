# ADR-0009: Preserve vector and adapter provenance

**Status:** Accepted  
**Date:** 2026-08-09

## Context

Embedding vectors, paired anchors, evaluation data, adapter artifacts, and migration outputs can contain or reveal business-sensitive information. An operator must also be able to prove which source/target spaces, training evidence, policy, and artifact produced a translated result.

## Decision

EmbedRelay records tenant-scoped provenance for spaces, anchors, adapters, evaluations, migrations, and translated vector origin. Released adapter artifacts are immutable and digest-bound. Access, retention, export, and encryption policies are explicit controls; vector contents do not establish authorization.

## Consequences

Adapter promotion requires provenance and integrity evidence. Cross-tenant reuse is policy-controlled rather than implicit. Audit and lifecycle records must remain sufficient to explain and roll back migration decisions without copying unnecessary protected payloads.