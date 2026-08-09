# ADR-0001: Treat translation as a migration bridge

**Status:** Accepted  
**Date:** 2026-08-09

## Context

Embedding models change and full immediate re-embedding may be operationally or economically infeasible. Cross-space transformation can preserve useful continuity, but claiming translated vectors are equivalent to native target embeddings would overstate fidelity.

## Decision

EmbedRelay is a continuity/migration bridge. Translated vectors carry explicit approximation provenance and confidence. The desired terminal state is target-native backfill whenever source data and policy permit it.

## Consequences

Cutover decisions require retrieval-level evidence and rollback. Product UX/API must distinguish vector origin. Translation may remain only where native recovery is impossible or an explicit accepted policy allows it.