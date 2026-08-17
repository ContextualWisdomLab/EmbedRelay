# EmbedRelay

**Change embedding models. Keep retrieval running.**

EmbedRelay is a ContextualWisdomLab leaf product: embedding-continuity
infrastructure for safe cross-model vector migration. It runs on its own, and a
host calls it through a published, versioned contract. That hub-and-leaf call is
the supported MSA path — **따로 또 같이** — not a reason to merge repositories
or require a sibling checkout.

Operators use EmbedRelay when an embedding model, revision, role, prefix,
normalization, preprocessing, dimension, precision, or metric contract changes
and the existing vector corpus cannot be treated as interchangeable. Equal
dimension is not compatibility. Blind comparison across spaces silently corrupts
retrieval.

## What EmbedRelay is

EmbedRelay identifies incompatible embedding spaces, registers directional
adapters with measured fidelity, keeps source and target indexes available
during cutover, and treats target-native re-embedding as the desired terminal
state. A translated vector is an approximation with provenance. It is never a
native target embedding by definition.

The product owns:

- canonical embedding-space identity (more than a provider model name);
- fail-closed vector validation bound to that identity;
- directional adapter and migration control;
- confidence, abstention, and rollback semantics for cross-space work.

## What EmbedRelay is not

| Concern | Owner |
| --- | --- |
| Ranking, fusion, TREC evaluation, and statistical comparison of retrieval lists | [`RankWeave`](https://github.com/ContextualWisdomLab/RankWeave) |
| LLM routing, cost control, and upstream provider keys | [`contextual-orchestrator`](https://github.com/ContextualWisdomLab/contextual-orchestrator) |
| Embedding model training or hosting | an embedding provider |
| Durable vector storage | a vector store behind a port |
| Document segmentation / semantic-unit chunking | the ingest or retrieval host |

Do not fold EmbedRelay into a hub repository. Do not give an LLM authority over
numerical compatibility or cutover gates.

## Composition hubs

Leaf products stay independently deployable. Composition hubs call them as
published dependencies.

| Hub | Role | How it calls EmbedRelay |
| --- | --- | --- |
| [`naruon`](https://github.com/ContextualWisdomLab/naruon) | Judgments, email workspace, and retrieval composition | Consume the published EmbedRelay contract from a release or tagged path. Naruon wiring is a separate repository pull request. |
| [`gyeot` (곁)](https://github.com/ContextualWisdomLab/gyeot) | On-device wellness composition hub | Call EmbedRelay only when a host needs embedding-space continuity; copy or pin the same published contract. |

No hub may read EmbedRelay's private database, and EmbedRelay may not read a
hub's private database.

## Run it independently

This default branch is documentation-first. It does not ship a package, service
binary, or test harness. Independent use means:

1. Treat this repository as the product authority for embedding continuity.
2. When a release exists, deploy or import **this** product only — not a
   monorepo, submodule farm, or sibling checkout of naruon, gyeot, RankWeave,
   or contextual-orchestrator.
3. Bind providers and vector stores through versioned ports. Core domain rules
   must not import vendor SDK types.
4. Keep source collections available until rollback evidence is accepted.
   Translation is a bridge, not a permanent substitute for native backfill.

Until a release publishes runtime artifacts, operators plan against the
decisions in [`docs/adr/`](docs/adr/) and the consumption rule below. Do not
invent a local package name or clone another CWL repository to “complete”
EmbedRelay.

## How a host consumes published contracts

A host does **not** check out this repository as a sibling of its own source
tree. It pins a published contract the same way it pins any other dependency:

1. Take the versioned OpenAPI or JSON Schema artifact from an EmbedRelay
   release, tag, or documented contract path.
2. Generate or hand-write a client against that artifact.
3. Call the deployed EmbedRelay base URL. Tenant, actor, and transport
   authorization stay in the host. Space identity, vector safety, adapter
   eligibility, and abstention stay in EmbedRelay.

Contract transport is UTF-8 JSON ([RFC 8259](https://www.rfc-editor.org/rfc/rfc8259)).
Public HTTP descriptions follow the [OpenAPI Specification](https://spec.openapis.org/oas/v3.1.2.html).
Contract versions follow [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html).

This branch publishes the consumption rule. Machine-readable OpenAPI or JSON
Schema files land with the first executable release. Until those files exist,
hosts use the ADRs as the authority boundary and do not scrape implementation
from another product's tree.

A successful translation result is expected to name source and target space
identities, the adapter artifact, vector origin (`native` or `translated`), and
an abstention status. Clients must not collapse abstention into a zero vector
or a silent same-space comparison.

## Operator notes

- Register every embedding space before comparing or translating vectors.
- Fail closed on dimension, precision, non-finite, or metric-contract mismatch.
- Treat A→B and B→A as different artifacts. Query and document roles are
  distinct by default.
- Combine cross-index results at rank level. Do not average raw scores from
  incompatible spaces.
- Abstain when confidence is below policy. Fallback is native re-embed, source
  index, dual retrieval, or operator review — never a fabricated mapping.
- Embeddings, anchors, and adapter weights are potentially sensitive. Tenant
  authorization is never inferred from a vector, a model name, or a space
  fingerprint alone.

## Architecture decisions

| ADR | Decision |
| --- | --- |
| [0001](docs/adr/0001-product-authority-boundary.md) | Product and authority boundary versus RankWeave and contextual-orchestrator |
| [0002](docs/adr/0002-embedding-space-continuity.md) | Embedding-space continuity and cross-model vector migration |
| [0003](docs/adr/0003-published-contract-consumption.md) | Published-contract consumption and MSA **따로 또 같이** |

Verified sources: [`docs/REFERENCES.md`](docs/REFERENCES.md).

## Contributing

Human contributor notes live in [`CONTRIBUTING.md`](CONTRIBUTING.md).
