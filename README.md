# EmbedRelay

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/ContextualWisdomLab/EmbedRelay)

EmbedRelay is the bounded home for embedding-space identity and migration contracts. Its goal is to let a product change embedding models or index generations without silently mixing incompatible vectors or losing provenance.

## Current status

EmbedRelay is an early documentation-stage repository. No executable package or release is currently published. There is no supported install command, hosted service, stable API, or production integration yet.

## Responsibility

EmbedRelay is intended to own reusable contracts and runtime support for:

- stable embedding-space identity and versioned migration plans;
- compatibility checks before vectors cross model or index boundaries;
- provenance for the producing model, dimensions, normalization, and migration lineage;
- fail-closed cutover, rollback, and verification evidence.

Product-domain meaning, Ubiquitous Language, source records, authorization, and release decisions remain with each product repository. EmbedRelay does not become a catalog, ontology publisher, model router, or product data authority.

## Evaluate the proposal

1. Read the [repository overview](docs/index.md).
2. Review the [product and technical Gap baseline](docs/product-technical-gap-baseline.md).
3. Confirm that a proposed consumer keeps domain truth and authorization locally and depends only on a future immutable EmbedRelay contract.

This is documentation review, not a software quickstart.

## Integration

Consumers must integrate only through an immutable, versioned release and an Anti-Corruption Layer. No such release exists today, so production consumers must not copy this repository's source, query an internal database, or depend on the pull-request branch.

## Documentation

- [Repository overview](docs/index.md)
- [Product and technical Gap baseline](docs/product-technical-gap-baseline.md)
- [DeepWiki](https://deepwiki.com/ContextualWisdomLab/EmbedRelay)

## Support

Use [GitHub Issues](https://github.com/ContextualWisdomLab/EmbedRelay/issues) for reproducible documentation defects and bounded feature proposals. Do not include credentials, personal data, proprietary embeddings, or customer records.

## License

No repository-level `LICENSE` is present. Public visibility does not establish permission to copy, modify, redistribute, or use the source. A rights and provenance review must precede any license selection or release; this repository does not infer or fabricate those rights.
