# EmbedRelay Technical Requirements Document

Status: pre-release target baseline; not as-built runtime evidence  
Last reconciled: 2026-09-02

## Runtime shape

The first executable implementation is a Rust-first modular service/library boundary. Domain computation is independent of HTTP, provider SDKs, vector stores, and persistence adapters.

Target modules:

- `space_identity`: immutable embedding-space value objects and canonical identity derivation;
- `vector_validation`: precision/dimension/finite-value/norm and compatibility admission;
- `adapter_contract`: directional adapter identity and deterministic conversion interface;
- `migration_governance`: policy revision, evaluation receipt, approval/hold/reject, rollback and supersession;
- `abstention_policy`: calibrated OOD/insufficient-evidence outcomes;
- `release_admission`: immutable candidate/release evidence;
- `identity_admission`: verified tenant/actor context and operation authorization;
- `http_api`: OpenAPI-bound transport only after the core is proven;
- persistence/provider/vector-store integrations behind ports and Anti-Corruption Layers.

## Numerical requirements

All production vector, matrix, linear-algebra and token-size computation is Rust-owned. Implementations must:

- reject NaN, infinity, unsupported precision/dimension and incompatible space identity before computation;
- define deterministic normalization/metric semantics per space identity;
- document floating-point tolerance from a numerical error model or validated implementation requirement rather than convenience constants;
- support CPU parallelism without changing result semantics;
- add GPU execution only with CPU/GPU parity evidence and explicit device/fallback reporting;
- preserve a complete failure denominator in evaluation.

Python may orchestrate tests/research only where it is not a production numerical core.

## Migration evaluation contract

A `migration_evaluation_run` binds:

- source and target space identities;
- adapter revision identity and digest;
- fitting, calibration and evaluation dataset/snapshot identities;
- sample design and exclusion/failure denominator;
- metric definitions and estimator/statistical method revisions;
- target-native baseline identity;
- uncertainty/OOD method and calibration evidence;
- policy revision;
- reproducible result digest and decision evidence.

Fitting/calibration/evaluation evidence is disjoint unless an explicit statistical design records why reuse is valid. Acceptance thresholds cannot exist without provenance.

## Service contract

Any executable network service:

- publishes OpenAPI 3.1.x for paths, operations, status/error behavior and security;
- uses versioned JSON Schema-compatible payload definitions;
- validates trusted OIDC identity and operation authorization before tenant-scoped vector work;
- supports asynchronous handling for work that can exceed request deadlines rather than blocking indefinitely;
- returns stable typed conversion/abstention/error contracts;
- never accepts caller-supplied tenant/actor identity as authoritative when it conflicts with verified claims.

## Persistence target

No runtime database is claimed today. If introduced, PostgreSQL or equivalent relational persistence must use:

- 3NF authoritative facts;
- descriptive two-or-more-word `snake_case` tables, constraints, indexes, policies and migration objects;
- explicit tenant scope and tenant-safe composite foreign keys;
- forced RLS/equivalent fail-closed isolation for shared-tenancy designs;
- append-only completed evidence where history is authoritative;
- item-level UPSERT/idempotency rules with conflict rejection;
- transaction/lock boundaries matched to minimal aggregates;
- measured contention/hot-partition evidence before partitioning/read-write separation.

Conceptual future relations may include `embedding_space_record`, `adapter_revision_record`, `migration_policy_revision`, `migration_evaluation_run`, `conversion_receipt_record`, `release_admission_record`, and `rollback_receipt_record`. These are target names, not current tables.

## Security and privacy

- Keyverse is the CWL deployment-profile identity authority, integrated through an ACL.
- Raw bearer tokens/provider keys are transport secrets, never domain attributes.
- Logs/audit must identify action, actor reference, tenant, correlation, policy/release identities and outcome without copying vector/provider payloads by default.
- Non-masking protection for operationally required sensitive evidence uses authorization, purpose binding, encryption, audit, retention/legal-hold and export controls.
- Secrets remain in the platform secret boundary; public packages/releases contain no embedded secrets.

## Operability and performance

Network runtime, when present, requires health/readiness, structured telemetry, bounded queues/timeouts, graceful shutdown and connection-lifecycle tests. Container delivery should remain compose-compatible with Docker/Podman/Colima and avoid assuming Kubernetes-specific behavior.

The user-specified p95 <=20 ms page/request objective is a release target only for synchronous endpoints whose workload permits it; it must be measured with realistic hardware/data and k6 after a network surface exists. Expensive migration/evaluation work belongs in asynchronous jobs and is not misrepresented as a 20 ms operation.

## Verification

Each executable slice follows RED -> smallest root-cause GREEN -> exact-head full verification. Release evidence includes relevant Rust fmt/test/clippy/rustdoc/coverage, contract tests, security/SAST/dependency review, tenant/adversarial tests, SBOM/provenance, recovery evidence when persistence exists, and qualifying independent review.
