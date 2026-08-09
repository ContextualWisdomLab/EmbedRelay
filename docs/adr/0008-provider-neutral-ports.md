# ADR-0008: Keep providers and vector stores behind neutral ports

**Status:** Accepted  
**Date:** 2026-08-09

## Context

Embedding providers and vector stores differ in model identifiers, input roles, batch/timeout limits, authentication, response metadata, score semantics, filtering, index lifecycle, and consistency behavior. Vendor SDK types in core domain logic would make migrations depend on the provider being migrated away from and could leak vendor-specific assumptions into compatibility decisions.

## Decision drivers

- preserve standalone operation and vendor portability;
- isolate credentials/network policy from numerical/domain logic;
- make score/capability differences explicit rather than inferred;
- prevent direct private-database coupling to other CWL products;
- support deterministic conformance tests for every provider/store adapter.

## Alternatives considered

1. **Import vendor SDKs in core domain code.** Rejected because it couples compatibility and migration state to mutable external APIs.
2. **Normalize every provider into one lowest-common-denominator implementation internally.** Rejected because unsupported semantics can become silent feature loss.
3. **Directly query another CWL service's private database.** Rejected because it violates modular service ownership and independent operability.
4. **Versioned provider-neutral ports with edge adapters.** Selected because it keeps capabilities explicit and replaceable.

## Decision

Core EmbedRelay domain and compute code depends only on versioned provider-neutral ports. Vendor adapters translate provider/vector-store contracts at the edge and revalidate response dimension/space evidence, batch and payload bounds, score semantics, capabilities, identity, and error classes before data enters the core. Unsupported capabilities return explicit typed failures.

## Consequences

New providers require conformance suites and capability declarations rather than vendor-name branches in the core. Some vendor-specific optimizations stay in edge adapters. Interface evolution requires versioning and compatibility tests. Optional integrations such as contextual-orchestrator or pg-llm-batch remain replaceable adapters, not mandatory runtime dependencies.

## Failure and recovery

Provider timeout, malformed response, identity drift, unsupported capability, score-semantic mismatch, rate limit, or vector-store inconsistency is classified at the port boundary. Core migration state does not reinterpret those failures as successful numerical evidence. Recovery may retry only classified transient failures, select another accepted provider/path, or pause migration; permanent contract failures require adapter/source changes.

## Security and governance impact

Credentials remain scoped to edge adapters and are never encoded in vector/space identity. Egress, TLS, secret, tenancy, data-residency, and provider-use policies are enforced before calls. Returned metadata and logs are treated as untrusted; ordinary telemetry excludes raw vectors, source text, secrets, and sensitive provider payloads.

## Verification and acceptance evidence

Each adapter requires contract tests for query/document roles, dimensions/fingerprints, batching, timeouts, retries, error translation, score semantics, filtering/capability behavior, secret/log redaction, malformed provider responses, and tenant separation. Real integration smoke tests must run against supported versions before claiming compatibility; a mock-only pass is insufficient for release claims.

## Migration and rollback

Port/version upgrades are canaried independently from embedding-space migrations. A migration manifest records the exact provider/store adapter versions and external bindings. Rollback restores the prior accepted adapter/binding without mutating canonical space or migration history.

## Supersession

A later ADR may standardize a broader protocol or shared service only if standalone operation, explicit capability negotiation, credential isolation, and provider/vector-store replacement remain intact. Direct vendor SDK/domain coupling requires a separately accepted exception.