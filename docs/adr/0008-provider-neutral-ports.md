# ADR-0008: Keep providers and vector stores behind neutral ports

**Status:** Accepted  
**Date:** 2026-08-09

## Context

Embedding/vector providers differ in model identifiers, input roles, batch limits, response metadata, score semantics, and index APIs. Vendor SDK types in core domain logic would make migrations dependent on the provider being migrated away from.

## Decision

Core EmbedRelay domain/compute code depends on versioned provider-neutral ports. Vendor adapters translate provider/vector-store contracts at the edge and revalidate dimensions, space identity, batch bounds, score semantics, and error classes before data enters the core.

## Consequences

Standalone operation and modular CWL integration remain possible. Direct application-database access across repositories is forbidden. New providers require adapter conformance tests rather than core branching on vendor names.