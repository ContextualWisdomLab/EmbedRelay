---
title: EmbedRelay
description: Governed embedding identity and migration infrastructure for ContextualWisdomLab.
---

# EmbedRelay

EmbedRelay is the proposed bounded owner for embedding-space identity, compatibility, provenance, migration, cutover, rollback, and verification contracts.

## Current status

No executable package or release is currently published. The repository has no supported install command, hosted service, stable API, or verified GitHub Pages publication. This page describes the intended responsibility boundary, not production availability.

## Boundary

EmbedRelay transports and verifies embedding identity. It does not own a product's domain truth, Ubiquitous Language, source data, ontology publication, catalog policy, model routing, or authorization decisions. Consumers integrate through a future immutable release and an Anti-Corruption Layer rather than copying source or querying another service's database.

Unknown or incompatible embedding identity must fail closed. A migration is not complete until producer and consumer versions, provenance, verification, and rollback evidence agree.

## Integration readiness

Production integration is blocked until a versioned contract, conformance fixtures, security evidence, SBOM/provenance, license decision, and immutable release are available. Until then, consumers may use only a local test double behind their own port and feature flag.

## Navigate

- [README](../README.md)
- [Product and technical Gap baseline](product-technical-gap-baseline.md)
- [Source repository](https://github.com/ContextualWisdomLab/EmbedRelay)
- [DeepWiki](https://deepwiki.com/ContextualWisdomLab/EmbedRelay)

## License

No repository-level `LICENSE` is present. Do not infer reuse rights from public visibility. License selection requires verified ownership, inbound provenance, and third-party obligation review.
