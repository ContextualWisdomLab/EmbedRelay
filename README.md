# EmbedRelay

**Change embedding models without treating incompatible vector spaces as interchangeable.**

EmbedRelay is ContextualWisdomLab's embedding-continuity product for governed cross-model vector migration. It is designed for retrieval systems that need to change an embedding model, revision, input role, preprocessing contract, dimension, precision, normalization, or metric without silently corrupting retrieval while a corpus is being migrated.

Equal dimension is not compatibility. EmbedRelay makes the space identity, migration evidence, abstention, rollback, and eventual target-native backfill explicit.

## Why teams use it

| Need | EmbedRelay responsibility |
| --- | --- |
| Change embedding models safely | Register the exact source and target embedding-space identities rather than trusting provider/model labels |
| Keep retrieval available during migration | Govern directional migration adapters while source-native retrieval remains available for rollback |
| Know when *not* to translate | Treat low-confidence, out-of-distribution, incompatible, or unapproved cases as typed abstention rather than fabricated vectors |
| Make cutover auditable | Bind adapter, policy, evaluation, decision, source, and target identities to immutable evidence |
| Integrate without repository coupling | Publish versioned service contracts instead of requiring sibling checkouts or shared application databases |

## Product boundary

EmbedRelay owns **embedding-space continuity and migration control**:

`identify space -> fit candidate adapter -> evaluate -> review -> approve/hold/reject -> migrate -> backfill native target vectors`

It does not own adjacent concerns:

| Concern | Authority |
| --- | --- |
| Ranking, fusion, TREC evaluation, and statistical comparison of retrieval lists | [`RankWeave`](https://github.com/ContextualWisdomLab/RankWeave) |
| LLM routing, provider discovery, and provider credentials | [`contextual-orchestrator`](https://github.com/ContextualWisdomLab/contextual-orchestrator) |
| Identity-provider administration | [`keyverse`](https://github.com/ContextualWisdomLab/keyverse) for the ContextualWisdomLab deployment profile |
| Embedding-model training or hosting | the embedding provider/runtime |
| Durable vector storage | the vector store behind a versioned port |
| Document segmentation or semantic-unit chunking | the ingest/retrieval product that owns source interpretation |

No product gains authority over another product's private persistence by integration. Cross-product use is through released contracts and bounded identities.

## Current status

This repository is currently **documentation-first**. It does not yet ship an executable service, package, binary, benchmark, or production HTTP endpoint. The architecture decisions and pre-release payload contract define the implementation boundary; they are not evidence that a runtime release exists.

The first executable release is not complete until it provides, at minimum:

- a runtime that can be deployed independently;
- deterministic embedding-space identity and validation;
- Rust-owned mathematical fitting/evaluation for numerical core operations;
- a versioned migration-policy and decision-receipt contract;
- an OpenAPI document for every HTTP surface;
- authenticated tenant/actor enforcement;
- executable contract, security, numerical-accuracy, and migration-recovery tests; and
- release artifacts whose version and provenance can be pinned by a consumer.

## Start here today

There is no install command to invent yet. For product or integration design, begin with the repository-owned contracts:

1. Read [ADR 0002](docs/adr/0002-embedding-space-continuity.md) for canonical embedding-space identity and migration approval/hold/rollback rules.
2. Read [ADR 0003](docs/adr/0003-published-contract-consumption.md) for the service-contract and authentication boundary.
3. Validate client designs against the [pre-release conversion-response JSON Schema](docs/contracts/conversion-response-v1.schema.json).
4. Use the [reference register](docs/REFERENCES.md) for the scientific and standards basis.

Do not invent a package coordinate, endpoint, badge, benchmark, or release URL before the corresponding artifact exists.

## Core concepts

### Embedding-space identity

An embedding space is more than a model name. `EmbeddingSpaceIdentityV1` binds material encoding properties such as model revision, input role, instruction/preprocessing profiles, tokenizer/truncation behavior when material, normalization, dimension, scalar representation, metric, and projection/post-processing profile.

The canonical record is serialized with RFC 8785 JSON Canonicalization Scheme and SHA-256 identified as:

`urn:cwl:embed-space:v1:sha256:<digest>`

Material changes create a new identity. Existing identities are immutable.

### Directional migration adapters

Adapters are directional: `A -> B` is not `B -> A`. Query and document roles are distinct by default. Orthogonal Procrustes and regularized linear maps are scientific starting points when paired anchors and assumptions support them; no method receives production authority merely because it can produce a vector.

### Evidence-backed migration gates

Each adapter is evaluated under an immutable versioned policy. Fit, calibration, and final evaluation data are separated; target-native retrieval is the reference baseline; approval is based on pre-registered uncertainty-aware criteria rather than an arbitrary point estimate or rule of thumb. OOD or low-confidence requests abstain. Missing evidence or an ungrounded numeric threshold cannot be promoted by an LLM judgement.

See [ADR 0002](docs/adr/0002-embedding-space-continuity.md) for the normative design.

### Typed conversion outcomes

The pre-release payload schema defines three outcomes: `converted`, `abstained`, and `error`. A successful translated result identifies its source/target spaces, adapter artifact, migration policy, decision receipt, vector origin, and vector. Abstention and error use stable typed codes and never masquerade as a zero vector or successful same-space result.

Schema: [`docs/contracts/conversion-response-v1.schema.json`](docs/contracts/conversion-response-v1.schema.json).

## Integration contract

An executable HTTP release must publish an immutable versioned **OpenAPI document**. JSON Schema may define or supplement payloads, but it cannot replace the HTTP contract's paths, methods, status codes, media types, and security schemes.

Consumers pin the released contract and call the deployed service. They do not clone EmbedRelay beside the host, import private implementation modules, or read a private EmbedRelay database.

For authenticated deployments, caller-supplied tenant or actor headers are not trusted identity. The caller presents a credential from a deployment-approved OIDC authority; EmbedRelay validates signature/trust root, issuer, service audience, token time semantics, tenant, and actor/subject claims before vector work. The ContextualWisdomLab deployment profile uses Keyverse as the ecosystem identity authority. Mismatched tenant/actor claims fail closed, and authorization for a requested space/adapter operation is enforced at the EmbedRelay boundary.

Contract transport is UTF-8 JSON ([RFC 8259](https://www.rfc-editor.org/rfc/rfc8259)). HTTP descriptions follow [OpenAPI 3.1.2](https://spec.openapis.org/oas/v3.1.2.html). Released contract versions follow [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html).

## Architecture at a glance

```text
Host / retrieval product
        │
        │ released OpenAPI + verified caller identity
        ▼
┌───────────────────────────────┐
│          EmbedRelay           │
├───────────────────────────────┤
│ space identity / validation   │
│ adapter registry              │
│ migration policy + evidence   │
│ abstention / rollback control │
└──────────────┬────────────────┘
               │
       versioned provider/store ports
               │
        ┌──────┴──────┐
        ▼             ▼
 embedding runtime   vector store
```

Composition products such as `naruon` or `gyeot` may consume the released contract, but they do not become EmbedRelay's implementation host or persistence authority.

## Operator principles

- Register the exact embedding space before comparing or translating vectors.
- Fail closed on identity, dimension, scalar, non-finite, metric, policy, or authorization mismatch.
- Keep source-native retrieval available until the accepted rollback window closes.
- Treat translated vectors as translated evidence, never native target embeddings.
- Combine incompatible indexes at an explicitly owned retrieval/ranking layer; do not average raw scores across incompatible spaces.
- Keep embeddings, anchors, adapter weights, and evaluation data inside their authorized tenant/purpose boundary.
- Never treat model output as migration approval.

## Documentation

| Document | Purpose |
| --- | --- |
| [ADR index](docs/adr/README.md) | Architecture decisions and their status |
| [ADR 0001](docs/adr/0001-product-authority-boundary.md) | Product and ecosystem authority boundaries |
| [ADR 0002](docs/adr/0002-embedding-space-continuity.md) | Space identity, migration science, evidence and decision gates |
| [ADR 0003](docs/adr/0003-published-contract-consumption.md) | Released contract, authentication and host-consumption rules |
| [Conversion-response schema](docs/contracts/conversion-response-v1.schema.json) | Pre-release machine-readable outcome contract |
| [References](docs/REFERENCES.md) | Verified scientific and standards basis |
| [Contributing](CONTRIBUTING.md) | Human contribution and repository-boundary guidance |

## License

EmbedRelay source and documentation in this repository are licensed under the [Apache License 2.0](LICENSE). Third-party works retain their own licenses; future dependencies and imported assets must remain compatible with ContextualWisdomLab's commercial-use policy and retain required notices/attribution.
