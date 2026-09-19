---
title: EmbedRelay
description: Governed embedding identity and migration infrastructure for ContextualWisdomLab.
---

# EmbedRelay

EmbedRelay helps services change embedding models or index generations without silently mixing incompatible vectors or losing the evidence needed to explain a migration.

## What this repository owns

- versioned identities for embedding spaces;
- model, dimension, normalization, and provenance contracts;
- compatibility validation at producer and consumer boundaries;
- migration, cutover, rollback, and verification evidence.

## Boundary

EmbedRelay transports and verifies embedding identity. It does not own a product's domain truth, Ubiquitous Language, source data, ontology publication, catalog policy, model routing, or authorization decisions. Consumers integrate through released contracts and an Anti-Corruption Layer rather than copying source or querying another service's database.

## Failure behavior

Unknown or incompatible embedding identity fails closed. A migration is not complete until the released producer contract, consumer version, provenance, and rollback evidence agree.

## Navigate

- [Source repository](https://github.com/ContextualWisdomLab/EmbedRelay)
- [README](https://github.com/ContextualWisdomLab/EmbedRelay#readme)
- [DeepWiki](https://deepwiki.com/ContextualWisdomLab/EmbedRelay)
- [ContextualWisdomLab](https://github.com/ContextualWisdomLab)

Publication is complete only after this source reaches the protected default branch and the live GitHub Pages endpoint is verified.
