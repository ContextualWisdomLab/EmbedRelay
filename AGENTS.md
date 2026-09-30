# EmbedRelay agent development rules

EmbedRelay is the ContextualWisdomLab bounded context for embedding-space identity, fail-closed vector compatibility, governed cross-model migration, abstention, rollback evidence, and target-native backfill contracts.

## Repository responsibility

- Keep EmbedRelay independently buildable, testable, deployable, and callable. Do not require sibling-repository checkouts, submodules, or cross-service application-table SQL.
- RankWeave owns retrieval-list fusion/evaluation/statistical comparison. contextual-orchestrator owns production LLM/provider routing and credentials. keyverse owns the ContextualWisdomLab deployment-profile identity-provider boundary. Embedding providers own model execution; vector stores own durable vector persistence; ingest/retrieval hosts own source interpretation and chunking.
- External provider/vector-store/identity DTOs remain behind Anti-Corruption Layers. Do not copy their private persistence models into EmbedRelay.

## Domain and computation

- Core bounded context: **Embedding Continuity**. Supporting contexts may include Migration Governance, Adapter Fitting/Evaluation, Release Admission, and Operator Evidence.
- Ubiquitous language includes `embedding_space_identity`, `migration_policy_revision`, `migration_evaluation_run`, `conversion_receipt`, `rollback_receipt`, `target_native_backfill`, `abstention_reason`, and `release_artifact`.
- Mathematical/vector/linear-algebra/token-size production computation is Rust-owned. Do not add Python numerical kernels. CPU multithreading and GPU paths require explicit contracts and measured evidence before release claims.
- Acceptance, OOD, rollback, and abstention thresholds must be derived from explicit buyer/SLO/scientific/statistical provenance. Do not introduce undocumented rule-of-thumb constants.

## Persistence and security

- Relational persistence, when introduced, uses third normal form and descriptive two-or-more-word `snake_case` object names. A generic one-word persistence object such as `id` is not an acceptable named database object.
- Tenant-owned relations carry explicit tenant scope; cross-tenant references fail closed. Item-level UPSERT/idempotency semantics must be specified and tested before persistence is accepted.
- Treat embedding vectors, model/provider identifiers, migration evidence, and source provenance as potentially sensitive. Preserve purpose/authorization/audit evidence without copying credentials or provider payloads into domain objects.
- OIDC/session/token verification belongs at the identity/authorization boundary; do not make a raw bearer token a domain value.

## Testing and release evidence

- Behavior changes are test-first. Preserve exact-head RED -> smallest root-cause repair -> exact-head GREEN evidence.
- Touched production surfaces target 100% statement/branch/function/region coverage where tooling exposes them, complete public Rust documentation, meaningful edge cases, and no suppressed deprecation warnings.
- Executable HTTP releases require OpenAPI plus the payload schemas they expose. A JSON Schema alone is not a service contract.
- Merge/release evidence is exact-head only. Queued, pending, cancelled, skipped-required, stale, predecessor-head, author-only, or model-only evidence is non-passing.
- Do not self-approve, weaken required gates, fabricate releases/benchmarks/customers/certifications, force-push, or destructively rebase concurrent writer work.

## Product truth

The current documentation branch is pre-release design/contract evidence. Until protected-main integration and executable runtime evidence exist, do not claim a production service, installable package, benchmark result, deployed identity integration, or customer deployment.
