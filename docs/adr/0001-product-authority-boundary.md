# ADR 0001: Product and authority boundary

Status: Proposed

## Context

ContextualWisdomLab composes leaf products instead of merging them.
EmbedRelay, RankWeave, and contextual-orchestrator can appear in the same
buyer workflow: change an embedding model, keep search available, then fuse
or judge results. Mixing those authorities in one repository or process would
hide privilege, force sibling checkouts, and make standalone operation
impossible.

ISO/IEC/IEEE 42010:2022 requires an architecture description to separate the
entity of interest from the concerns of its stakeholders (International
Organization for Standardization, International Electrotechnical Commission,
& Institute of Electrical and Electronics Engineers, 2022). ISO/IEC 23053:2022
likewise distinguishes functional components of a machine-learning system —
data, model, and surrounding software — so that ownership can be named
(International Organization for Standardization & International
Electrotechnical Commission, 2022). NIST AI RMF 1.0 asks organizations to map
which system actually governs validity, accountability, and measurement
(National Institute of Standards and Technology, 2023).

The buyer problem for EmbedRelay is embedding-space change: a provider
revision, prefix, role, normalization, dimension, precision, or metric
contract can invalidate an existing corpus even when dimensions match. That
is not ranking quality, and it is not LLM token routing.

## Decision

EmbedRelay is the authority for embedding-space identity, vector safety,
directional adapters, dual-index migration, abstention, and target-native
backfill policy.

RankWeave remains the authority for store-agnostic retrieval fusion,
evaluation, statistical comparison, and TREC-style ranking evidence. When
EmbedRelay returns ranks or scores from more than one compatible index, a
host may send those lists to RankWeave. EmbedRelay must not reimplement
RankWeave's fusion or significance contracts.

contextual-orchestrator remains the authority for LLM routing, cost control,
allowlists, and upstream provider credentials. EmbedRelay may call it as an
optional, separately deployed gateway when a workflow needs language-model
help. EmbedRelay must not store upstream provider keys or walk a sequential
model list. An LLM must not authorize numerical compatibility or cutover.

Naruon and gyeot are allowed composition hubs. They call EmbedRelay through
the published contract (ADR 0003). They do not absorb EmbedRelay source.

Out of scope for this product: embedding-model training, vector-database
storage, document segmentation, and semantic-unit chunking. Chunking stays
with the ingest or retrieval host.

## Consequences

- Buyers can operate EmbedRelay without checking out RankWeave,
  contextual-orchestrator, naruon, or gyeot.
- Hosts keep tenant transport, identity, and durable application data.
- Retrieval quality gates that need fusion or paired significance tests are
  executed in RankWeave, not inferred from vector cosine alone.
- LLM orchestration failures cannot silently rewrite space identity or
  approve a migration.
- A later transfer of ranking or LLM-routing authority into EmbedRelay is a
  breaking architecture change and requires a superseding ADR.

## References

International Organization for Standardization & International
Electrotechnical Commission. (2022). *Framework for artificial intelligence
(AI) systems using machine learning (ML)* (ISO/IEC 23053:2022).
https://www.iso.org/standard/74438.html

International Organization for Standardization, International
Electrotechnical Commission, & Institute of Electrical and Electronics
Engineers. (2022). *Software, systems and enterprise — Architecture
description* (ISO/IEC/IEEE 42010:2022).
https://www.iso.org/standard/74393.html

National Institute of Standards and Technology. (2023). *Artificial
intelligence risk management framework (AI RMF 1.0)* (NIST AI 100-1).
U.S. Department of Commerce. https://doi.org/10.6028/NIST.AI.100-1
