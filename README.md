# EmbedRelay

**Embedding continuity infrastructure for changing models without silently mixing incompatible vector spaces.**

EmbedRelay helps retrieval and RAG platforms move from one embedding model or revision to another while keeping compatibility, tenant boundaries, provenance, and rollback decisions explicit. Equal vector dimensions are not treated as proof that two embedding spaces are comparable.

> **Status:** pre-release. The M1 implementation described below exists on the current Draft PR and is not protected-main or release evidence yet.

## Why EmbedRelay

Embedding providers change model revisions, preprocessing, roles, normalization, precision, dimensions, and metric behavior. Re-embedding an enterprise corpus all at once may be expensive or operationally impossible, while directly comparing vectors from different spaces can silently damage retrieval quality.

EmbedRelay defines a governed bridge:

1. identify every embedding space with a canonical immutable fingerprint;
2. reject vectors that do not satisfy the declared space contract;
3. retain tenant-scoped registration and audit evidence;
4. evaluate directional migration adapters rather than assuming invertibility;
5. abstain when fidelity or out-of-distribution confidence is insufficient; and
6. converge to target-native embeddings as the intended terminal state.

It is **not** an embedding provider, vector database, universal embedding converter, or claim that translated vectors are equivalent to native target embeddings.

## Current M1 candidate

The current Draft branch contains an executable foundation for the registry boundary:

- canonical embedding-space fingerprints covering model revision, role, preprocessing, normalization, dimensionality, precision, metric, and other material identity;
- fail-closed `float32` vector validation, including dimension/precision mismatch and invalid numeric-state rejection;
- RFC 9562 UUIDv7 identifiers used only as opaque identifiers, never as tenant or authorization proof;
- tenant-isolated Rust registry semantics with audit-before-observability behavior;
- PostgreSQL 18.x persistence for canonical manifests, tenant space registration, and append-only registration audit;
- forced tenant RLS and fail-closed tenant context;
- database-side recomputation of the canonical `sha256:<64 lowercase hex>` manifest fingerprint;
- deterministic duplicate/concurrent registration rejection, guarded rollback, and logical backup/restore acceptance; and
- locked Rust dependencies plus exact line, region, function, and branch coverage gates.

These are **active-PR implementation facts**, not shipped capabilities. Adapter fitting/evaluation, confidence-gated translation, dual-index routing, native backfill, provider/vector-store ports, production recovery architecture, service APIs, and GPU compute remain planned or partial until separately implemented and verified.

## Developer quick start

The workspace targets Rust `1.97.1` and tracks `Cargo.lock`.

```bash
cargo test --workspace --locked
```

The repository CI also validates the current PostgreSQL 18.6 registry, canonical-manifest persistence, logical backup/restore contract, and exact LLVM coverage. Those database tests require a reachable PostgreSQL 18.x instance and are documented by the repository workflow and test scripts; a passing local unit test is not a substitute for the full protected integration gate.

## Product boundary

EmbedRelay sits between retrieval clients, migration operators, embedding providers, and vector stores. Its core responsibility is **embedding continuity**: space identity, compatibility, migration fidelity, abstention, and target-native convergence.

The supporting registry-governance boundary owns immutable manifests, tenant-scoped registration, durable audit, drift quarantine, and release evidence. Provider SDKs, vector-store internals, identity providers, object/KMS services, and telemetry systems remain external integrations behind versioned ports. EmbedRelay does not absorb another product's private database model or use cross-service application-table SQL as an integration contract.

See [ARCHITECTURE.md](ARCHITECTURE.md) for the control, compute, data, and provider-neutral port model.

## Safety and evidence principles

- Raw vectors from different canonical space identities are never directly compared.
- Equal dimensions never establish compatibility.
- A→B and B→A adapters are distinct artifacts; query and document roles are distinct by default.
- Low-confidence translation abstains instead of fabricating compatibility.
- Raw similarity scores from different spaces are not averaged as if they shared one metric scale.
- Tenant authority is explicit; UUID timestamps, vector contents, model names, and fingerprints never prove tenancy.
- Provider/model drift creates or quarantines a space identity instead of mutating historical compatibility truth.
- Source collections remain available until cutover and rollback evidence is sufficient.
- A source commit, open PR, local test, or logical restore fixture is not by itself release, production-recovery, RTO/RPO, customer, or certification evidence.

## Documentation

Start with the [documentation map](DOCUMENTATION.md):

- [Product requirements](docs/PRD.md)
- [Technical requirements](docs/TRD.md)
- [Architecture](ARCHITECTURE.md)
- [UML/runtime flows](docs/UML.md)
- [ERD and data model](docs/ERD.md)
- [API and port contracts](docs/API_CONTRACT.md)
- [Security](docs/SECURITY.md) and [threat model](docs/THREAT_MODEL.md)
- [Test strategy](docs/TEST_STRATEGY.md)
- [Operability and recovery](docs/OPERABILITY.md)
- [Requirement/evidence traceability](docs/TRACEABILITY.md)
- [Product and technical gap baseline](docs/product-technical-gap-baseline.md)
- [Architecture decision records](docs/adr/README.md)

Documentation uses explicit maturity labels such as `active-PR implemented`, `protected-main implemented`, `planned`, `partial`, and `accepted target` so target architecture is not confused with current product evidence.

## Contributing and verification

Changes should preserve the product invariants in the PRD and architecture records, update traceability when an authority or maturity boundary changes, and regenerate evidence for the exact current head. Do not reuse predecessor-head CI or review results after a source change.

The repository currently treats missing docs, unsafe Rust, missing public documentation, stale lock state, PostgreSQL contract drift, incomplete exact coverage, and required security/review failures as integration blockers rather than documentation-only warnings.

## License

EmbedRelay source declares `Apache-2.0 OR MIT` in the Rust workspace metadata. This branch materializes that existing dual-license grant as [LICENSE-APACHE](LICENSE-APACHE) and [LICENSE-MIT](LICENSE-MIT).

The grant applies to ContextualWisdomLab-authored EmbedRelay source and documentation. Rust crates, PostgreSQL, provider/vector-store SDKs, future model or adapter artifacts, datasets, standards, external services, and other third-party material retain their own licenses and terms and are not relicensed by EmbedRelay.
