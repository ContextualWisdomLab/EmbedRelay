# EmbedRelay architecture

## Product responsibility

EmbedRelay is the ContextualWisdomLab authority for **embedding continuity**: deterministic embedding-space identity, fail-closed compatibility admission, governed directional conversion/migration, abstention, rollback evidence, and target-native terminal-state/backfill contracts.

It is not an embedding provider, vector database, retrieval-fusion engine, document chunker, identity provider, or general LLM router.

## Context map

### Core: Embedding Continuity

Owns:

- `embedding_space_identity` as an immutable value object derived from material model/preprocessing/role/metric properties;
- vector compatibility admission and explicit incompatibility evidence;
- directional conversion contracts and conversion receipts;
- abstention/failure results that remain first-class outcomes rather than silent coercion.

### Supporting: Migration Governance

Owns versioned `migration_policy_revision`, `migration_evaluation_run`, approval/hold/reject decisions, rollback evidence, target-native backfill state and release-admission receipts. Thresholds require explicit buyer/SLO/scientific/statistical provenance.

### Supporting: Adapter Fitting and Evaluation

Owns fitting/calibration/evaluation dataset identities and reproducible evaluation receipts. Fitting, calibration and evaluation sets remain disjoint unless a documented statistical design proves otherwise. Numerical/vector/matrix computation is Rust-owned.

### Supporting: Release Admission

Owns stable public payload/service contract versioning, compatibility/deprecation metadata, release artifact digests/signatures/provenance where implemented, and deterministic offline validation. Executable HTTP surfaces require OpenAPI; JSON Schema remains payload-level evidence.

## External boundaries

- **RankWeave**: retrieval fusion, ranking evaluation and statistical comparison.
- **contextual-orchestrator**: production model/provider routing, discovery and credentials.
- **keyverse**: ContextualWisdomLab deployment-profile identity provider and federated identity boundary.
- **Embedding providers/runtimes**: model execution/training.
- **Vector stores**: durable vector persistence and physical index lifecycle.
- **Ingest/retrieval hosts**: source interpretation, DOM/paragraph/phrase/sender-recipient/image-aware semantic chunking and business authorization.

All external DTOs enter through Anti-Corruption Layers. No sibling checkout or foreign application-table SQL is an integration contract.

## Persistence target

No runtime persistence is claimed by the current documentation branch. If relational persistence is introduced:

- authoritative facts remain in 3NF;
- named database objects use two-or-more semantic words and `snake_case` by default;
- every tenant-owned relation carries explicit tenant scope and composite tenant-safe references;
- migration/release/audit records are immutable or append-only where they represent completed evidence;
- item-level UPSERT/idempotency semantics are explicit and concurrency-tested;
- hot-partition/lock behavior is measured before partitioning or read/write separation decisions.

## Security and privacy

OIDC/session/token verification and service-operation authorization occur before tenant-scoped domain work. Raw bearer tokens, provider credentials and unbounded provider payloads never become domain attributes. Migration and provenance evidence may be sensitive and requires purpose-bound authorization, auditability and retention design rather than blanket masking that destroys operational usefulness.

## Release boundary

The current branch provides design and machine-readable pre-release payload evidence only. A production-ready release requires, on the exact candidate head:

1. Rust executable/runtime boundaries for all numerical/vector computation;
2. deterministic compatibility, conversion and abstention tests with realistic vectors and failure denominators;
3. authenticated tenant/actor authorization and tenant-isolation evidence;
4. OpenAPI for executable HTTP surfaces plus versioned payload schemas;
5. security/SBOM/provenance/package/container/recovery evidence appropriate to the shipped runtime;
6. exact-head protected checks and qualifying independent review;
7. immutable release identifiers and rollback/supersession semantics.

No documentation decision alone is production, conformance, certification, customer, or benchmark evidence.
