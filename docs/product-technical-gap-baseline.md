# Product and technical gap baseline

Last reconciled: 2026-09-02

This ledger is derived from the live EmbedRelay repository, current PR #4 product boundary, ADR/reference material, machine-readable conversion contract, and current GitHub review/check state. It is a commercialization planning artifact, not a production, conformance, certification, benchmark, or customer claim.

## Product responsibility

EmbedRelay owns embedding-space identity, fail-closed vector compatibility, governed directional conversion/migration, abstention, rollback evidence, migration-policy/evaluation receipts, and target-native terminal-state/backfill contracts.

Adjacent authorities remain separate:

- RankWeave: retrieval-list fusion, ranking evaluation and statistical comparison;
- contextual-orchestrator: production LLM/provider routing, model discovery and provider credentials;
- keyverse: ContextualWisdomLab deployment-profile identity-provider boundary;
- embedding providers/runtimes: model execution/training;
- vector stores: durable vector/index persistence;
- ingest/retrieval products: source interpretation, semantic-unit chunking and business authorization.

No sibling checkout, submodule farm, shared private application database, or direct foreign-table SQL is an integration contract.

## Current exact-head baseline

Transient workflow status is resolved live from GitHub rather than committed as durable truth. Every merge/release decision must re-fetch the exact PR head, base, review threads, reviews, required checks, workflow jobs/logs, rulesets and mergeability. Predecessor-head evidence is non-passing after any head change.

| Area | Current evidence | Status | Commercialization gap | Next verification |
| --- | --- | --- | --- | --- |
| Product boundary | README, `docs/PRD.md`, root `ARCHITECTURE.md`, ADRs, `AGENTS.md` | Defined | Protected main has not integrated this complete boundary | Merge only through ordinary protected path after fresh exact-head evidence |
| Embedding-space identity | ADR/contract design uses canonical material fields, RFC 8785 serialization and SHA-256 stable identity | Contract candidate | No executable Rust identity package/release on this PR | Add Rust value object and golden cross-language canonicalization fixtures test-first |
| Conversion result | `docs/contracts/conversion-response-v1.schema.json` with `converted` / `abstained` / `error` outcomes | Payload contract candidate | No executable conversion engine or HTTP boundary | Implement Rust-owned numerical boundary; add OpenAPI before any HTTP release claim |
| Numerical/vector computation | `docs/TRD.md`, architecture and agent policy require Rust ownership | Missing runtime | No production vector/matrix migration kernel, CPU multithreading or GPU contract | Build minimal deterministic Rust kernel with realistic numerical accuracy and failure-denominator tests |
| Migration governance | Evidence-derived approval/hold/reject and rollback decisions are documented | Design defined | No executable policy revision, evaluation-run or release-admission state machine | Add versioned value objects/receipts; thresholds require explicit buyer/SLO/scientific/statistical provenance |
| OOD / abstention | Explicit fail-closed abstention design and test strategy | Design defined | No calibrated OOD contract/evaluation evidence | Define calibration dataset identity, estimator/statistical method and reproducible calibration/abstention tests; no rule-of-thumb thresholds |
| Retrieval continuity | Target-native retrieval baseline is required | Planned | No representative retrieval benchmark or exact target-native comparison contract | Use RankWeave for retrieval evaluation/statistical comparison; keep raw ranking math out of ad-hoc Python production paths |
| Identity / authorization | OIDC + operation authorization boundary; keyverse deployment profile | Design defined | No executable token/session verification, authorization adapter or tenant isolation proof | Add identity ACL and authorization port; reject unavailable/invalid identity before tenant work |
| Persistence | `ARCHITECTURE.md`/`docs/TRD.md` plus conceptual `docs/ERD.md` define future 3NF/tenant/idempotency constraints | Not implemented | No migration, RLS, audit, concurrency or recovery evidence | Introduce persistence only when needed; preserve the conceptual ERD invariants with real migrations/tests |
| Service API | Payload schema exists; TRD defines OpenAPI/async boundary | Pre-release only | No OpenAPI, async request lifecycle implementation, error/status transport contract or running service | Add OpenAPI 3.1.x with authenticated tenant/actor context before advertising an endpoint |
| Security/privacy | Root `SECURITY.md`, architecture and identity ADR define trust/fail-closed boundaries | Design baseline | No executable threat controls, retention/access/export/audit implementation or secret/runtime evidence | Add misuse/tenant/adversarial tests with first runtime slice; keep certification claims separate from control design |
| Operability | `docs/OPERABILITY.md` defines service lifecycle, compose, accelerator, observability, recovery and load gates | Design baseline | No deployed compose service, backup/restore, rollback, telemetry or incident evidence | Add deployment/recovery only after runtime/persistence exists; measure rather than invent RPO/RTO |
| Performance | Operability baseline distinguishes synchronous <=20 ms target from async migration work | Unevidenced runtime | No network/load data | Add k6 once a network API exists; measure realistic auth/data/hardware and remove bottlenecks before readiness claim |
| Test/documentation quality | Canonical README/PRD/TRD/UML/ERD/ADRs/references, security/test/operability, `AGENTS.md`, `CLAUDE.md`, architecture, changelog and this ledger; executable `tests/test_documentation_contracts.py`; exact-head `Documentation Quality` workflow | Executable foundation gate | Runtime-specific test/security/operability evidence cannot exist before runtime | Require exact-head documentation gate; keep target diagrams/requirements distinct from future as-built runtime evidence |
| Release/package | Apache-2.0 source/documentation grant; no published package claimed | Missing release | No immutable release, SBOM/provenance/package/container evidence | Establish release artifact identity only after executable exact-head GREEN and governance satisfaction |

## DDD context map

### Core subdomain — Embedding Continuity

Bounded context: **Embedding Continuity**.

Ubiquitous language:

- `embedding_space_identity`
- `vector_compatibility_result`
- `directional_adapter_revision`
- `conversion_receipt`
- `abstention_reason`
- `target_native_backfill`

Candidate aggregates/value objects:

- `EmbeddingSpaceIdentity`: immutable value object for compatibility identity;
- `ConversionReceipt`: completed conversion/abstention/error evidence, immutable after issuance;
- `MigrationRelease`: immutable approved release aggregate only after deterministic admission succeeds.

Invariants:

1. equal vector dimensions never imply compatible spaces by themselves;
2. a conversion never silently becomes target-native truth without a governed migration/release decision;
3. unsupported/OOD/ambiguous inputs abstain or fail closed rather than inventing compatibility;
4. every acceptance threshold carries explicit provenance;
5. raw provider credentials/tokens are outside the domain.

### Supporting subdomain — Adapter Fitting and Evaluation

Owns fitting/calibration/evaluation dataset identities, adapter revision evidence and reproducible evaluation receipts. Fitting/calibration/evaluation data are disjoint unless an explicit statistical design says otherwise. All mathematical/vector/matrix production computation is Rust-owned.

### Supporting subdomain — Migration Governance

Owns `migration_policy_revision`, `migration_evaluation_run`, approval/hold/reject, rollback, supersession and release-admission evidence. It does not own provider training infrastructure or consuming-product authorization.

### Generic/integration boundaries

- Identity/federation: keyverse via ACL.
- LLM/model routing where needed: contextual-orchestrator only.
- Retrieval evaluation/statistical comparison: RankWeave.
- Provider/model/vector-store APIs: ACL/adapters, never shared persistence.

## Persistence and naming acceptance

No production database is present in the current PR. When persistence becomes necessary:

- named database objects contain at least two semantic words and use `snake_case` by default;
- authoritative relational facts remain in 3NF;
- tenant-owned tables include tenant scope and tenant-safe composite references;
- immutable completed receipts/events are append-only;
- item-level UPSERT behavior distinguishes exact idempotent retry from conflicting reuse;
- concurrency tests prove duplicate/conflicting writes cannot create two accepted authorities;
- hot-partition, locking and read/write separation decisions require measured evidence.

## Scientific and numerical acceptance

The numerical core must not use undocumented heuristics. Migration accuracy, OOD/abstention and rollback gates require a registered estimator/statistical/experimental design with a full failure denominator and reproducible dataset/revision identities. Realistic evaluation must compare transformed vectors against target-native embeddings/retrieval behavior; a same-dimension cosine result alone is not sufficient evidence of semantic continuity.

Where retrieval-list evaluation or statistical comparison is needed, consume RankWeave rather than reimplementing a competing evaluation engine inside EmbedRelay. Production vector/linear/matrix computation remains Rust-owned.

## Release gates

A first executable commercial release is not ready until all of the following are true on one exact candidate head:

1. Rust-owned embedding-space identity and numerical conversion/compatibility kernel;
2. deterministic and realistic vector/migration tests, including OOD/abstention and full failure denominators;
3. authenticated tenant/actor authorization and cross-tenant negative evidence;
4. OpenAPI for any executable HTTP surface plus versioned payload schemas;
5. explicit migration-policy/evaluation/release receipts and rollback/supersession behavior;
6. complete current security/test/operability documentation for the shipped runtime;
7. 100% touched production statement/branch/function/region coverage where tooling exposes it plus complete public Rust documentation;
8. dependency/SAST/security/SBOM/provenance/package/container/recovery evidence appropriate to the shipped artifact;
9. fresh exact-head required checks, zero valid unresolved review findings and qualifying independent approval;
10. immutable release identifier and changelog entry without fabricated performance/customer/certification claims.

## Active gap order

1. Integrate the documentation/contract foundation through the normal protected path after fresh exact-head review/check evidence, including the repository-local documentation contract gate.
2. Add the smallest Rust-first `EmbeddingSpaceIdentity` and fail-closed vector-compatibility slice with RED-first tests and cross-language canonicalization fixtures.
3. Define a versioned migration policy/evaluation receipt and calibrated abstention contract without heuristic thresholds.
4. Implement the directional conversion kernel and compare against target-native embeddings/retrieval evaluation; use RankWeave for ranking/statistical comparison.
5. Add authenticated tenant/actor service admission and OpenAPI around the proven deterministic core.
6. Add persistence/audit/recovery only when a real runtime requirement exists, preserving 3NF, tenant isolation, multiword naming and explicit idempotency.
7. Add packaging, compose-compatible deployment, SBOM/provenance, recovery and realistic performance evidence before any production-readiness claim.
