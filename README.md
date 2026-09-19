# EmbedRelay

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/ContextualWisdomLab/EmbedRelay)

EmbedRelay provides embedding-continuity infrastructure for safe, evidence-backed migration between vector models and index generations.

## Responsibility

EmbedRelay owns reusable contracts and runtime support for:

- stable embedding-space identity and versioned migration plans;
- compatibility checks before vectors cross model or index boundaries;
- provenance that records the producing model, dimensions, normalization, and migration lineage;
- fail-closed cutover and rollback evidence for consumers.

Product-domain meaning, Ubiquitous Language, source records, authorization, and release decisions remain with each product repository. EmbedRelay does not become a catalog, ontology publisher, model router, or product data authority.

## Public documentation

- [Repository overview](docs/index.md)
- [DeepWiki](https://deepwiki.com/ContextualWisdomLab/EmbedRelay)
- [ContextualWisdomLab organization](https://github.com/ContextualWisdomLab)

## Repository governance

Executable milestones are developed on ordinary protected branches and integrated through normal protected pull requests. The protected default branch must not host or execute temporary branch-writing materializers, self-deleting finalizers, or one-shot bootstrap authority. Any such authority is retired through a reviewed pull request after its bounded purpose. The organization workflow-lifecycle control plane then disables any residual GitHub Actions registry record or explicitly classifies it as orphaned, with follow-up tracked in `ContextualWisdomLab/.github#945`.
