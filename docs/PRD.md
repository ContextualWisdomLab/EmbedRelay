# EmbedRelay Product Requirements Document

Status: pre-release product baseline
Last reconciled: 2026-09-02

## Product problem

Embedding model upgrades can change tokenization, task prefixes, normalization, pooling, dimensionality, metric assumptions, provider preprocessing, and latent geometry. Equal vector dimensions do not make two embedding spaces interchangeable. A naive migration can silently corrupt retrieval quality, make rollback impossible, or mix source and target vectors without auditable evidence.

EmbedRelay exists to make cross-model embedding migration **explicit, directional, measurable, abstaining, and reversible**.

## Primary users and jobs

### Retrieval platform operator

Needs to migrate from one embedding space to another without silently mixing incompatible vectors, while retaining evidence that a migrated index satisfies a declared release policy and can be rolled back.

### Search / RAG product engineer

Needs a stable contract to identify embedding spaces, ask whether a source vector can be converted, distinguish target-native from translated vectors, and handle abstention/error outcomes deterministically.

### Security / governance reviewer

Needs exact tenant/actor authorization, immutable migration evidence, provenance-bound thresholds, failure denominators, release/rollback receipts, and no hidden provider credentials or cross-service database coupling.

### Applied research / evaluation owner

Needs disjoint fitting/calibration/evaluation evidence, target-native comparison, uncertainty/OOD analysis, and reproducible statistical acceptance without undocumented rules of thumb.

## Product responsibility

EmbedRelay owns:

- deterministic embedding-space identity;
- fail-closed compatibility admission;
- directional adapter/conversion contracts;
- conversion/abstention/error receipts;
- migration-policy and evaluation evidence;
- approval/hold/reject and rollback/supersession semantics;
- target-native terminal-state/backfill contracts.

It does not own model training/execution, vector-store persistence, retrieval fusion/statistical ranking evaluation, source document interpretation/chunking, identity-provider infrastructure, or general LLM/provider routing.

## First executable commercial vertical

A bounded first executable release must support one complete migration decision path:

1. register/construct immutable source and target `EmbeddingSpaceIdentity` values;
2. validate a source vector against its declared space;
3. evaluate a pinned directional adapter revision;
4. return one typed result: `converted`, `abstained`, or `error`;
5. bind the result to source/target space identities and adapter provenance;
6. evaluate the adapter/migration revision against a versioned migration policy using disjoint evidence and a full failure denominator;
7. produce approval/hold/reject evidence;
8. preserve target-native backfill and rollback/supersession semantics;
9. expose the proven boundary through an authenticated OpenAPI HTTP surface only after the deterministic core is GREEN.

## Functional requirements

- Space identity changes whenever any material model/preprocessing/role/metric field changes.
- Same dimension is never sufficient compatibility evidence.
- Invalid/non-finite/wrong-dimension vectors fail closed.
- OOD, insufficient evidence, unsupported space, and ambiguous conversion conditions abstain or fail; they never silently emit a zero or source-space vector as target-native.
- Every numerical acceptance/OOD/rollback threshold identifies its provenance and policy revision.
- Converted vectors remain distinguishable from target-native vectors until a governed migration/backfill transition completes.
- Every completed conversion and migration decision is reproducibly attributable to exact source/target/adapter/policy/evaluation identities.
- Tenant/actor authorization is established before tenant-scoped vector/migration work.

## Non-functional requirements

- Production numerical/vector/matrix/token-size computation is Rust-owned.
- CPU multithreading and any GPU path have explicit deterministic contracts and parity tests.
- Touched production surfaces target 100% statement/branch/function/region coverage where available and complete public Rust documentation.
- No undocumented heuristic or rule-of-thumb acceptance weight/threshold.
- No provider credential, bearer token, copied provider payload, or sibling private database becomes domain state.
- Future relational persistence is 3NF with descriptive multiword `snake_case`, tenant-safe references, explicit item-level UPSERT/idempotency, concurrency evidence, and measured hot-partition/lock behavior.
- Any HTTP release publishes OpenAPI and versioned payload schemas.
- Release artifacts have immutable identity, changelog, SBOM/provenance/security evidence appropriate to the shipped form.

## Success evidence

The first executable release is successful when a buyer can demonstrate, on one immutable exact release:

- deterministic space identity across independent implementations;
- numerically correct conversion for the supported adapter class against known expected outputs;
- calibrated abstention/OOD behavior with disclosed denominator and method;
- target-native retrieval comparison using RankWeave for ranking/statistical evaluation where applicable;
- fail-closed tenant and authorization tests;
- reproducible migration approval/hold/reject and rollback evidence;
- fresh exact-head tests/security/reviews and immutable release provenance.

No benchmark number, customer claim, conformance claim, or production-readiness claim exists until that evidence exists.
