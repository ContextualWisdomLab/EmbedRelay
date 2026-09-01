# EmbedRelay test strategy

Status: pre-release test baseline  
Last reconciled: 2026-09-02

## Principles

Tests prove the current product boundary rather than planned features. Behavior changes begin with a realistic failing contract where technically possible, followed by the smallest root-cause repair and exact-head GREEN evidence. Predecessor-head results are historical only.

## Current documentation contract

`python3 -m unittest tests/test_documentation_contracts.py -v` currently verifies:

- exact embedding-space identifier/digest syntax including LF/CRLF and uppercase rejection;
- presence and non-empty content of canonical `AGENTS.md`, `CLAUDE.md`, `ARCHITECTURE.md`, `CHANGELOG.md`, and `docs/product-technical-gap-baseline.md`;
- discoverability of canonical product/engineering authority from `docs/index.md`;
- Rust ownership of production numerical/vector computation;
- fail-closed prohibition on undocumented rule-of-thumb thresholds;
- descriptive multiword `snake_case` persistence naming.

The exact-head `Documentation Quality` workflow executes that regression set and `git diff --check` after explicit head-SHA checkout.

## First runtime test matrix

### Space identity

- golden canonicalization fixtures across at least Rust and an independent fixture generator;
- all material-field changes create a different identity;
- explicit defaults canonicalize identically;
- malformed/unknown material fields fail according to contract versioning.

### Vector validation

- correct precision/dimension;
- wrong dimension/precision;
- NaN, +/-infinity, zero norm and subnormal policy;
- extreme magnitudes and numerical stability;
- deterministic normalization/metric behavior;
- fuzz/property cases for parser/validation boundaries.

### Conversion

- known source/target/adapter fixtures with expected numerical outputs and error bounds derived from implementation/numerical analysis;
- source/target mismatch;
- unsupported adapter or space;
- deterministic `converted`, `abstained`, `error` result shapes;
- CPU multithread consistency;
- CPU/GPU parity if a GPU path is introduced.

### Migration evaluation and abstention

- disjoint fitting/calibration/evaluation identities;
- full denominator accounting including parser/provider/timeout/conversion failures;
- calibrated OOD and abstention behavior;
- missing threshold provenance fails closed;
- target-native embedding/retrieval comparison;
- RankWeave-based ranking/statistical comparison where retrieval-level evidence is required;
- rollback and supersession decision replay.

### Identity and tenant isolation

- invalid issuer/audience/time/subject/tenant claim rejection before vector work;
- mismatched payload identity rejection;
- operation authorization deny/unavailable fail closed;
- cross-tenant reads/writes/references zero;
- raw tokens/provider credentials absent from persisted/logged domain evidence.

### Persistence, when introduced

- clean install, rollback/reapply and migration ordering;
- 3NF and naming fitness checks;
- exact idempotent retry vs conflicting key reuse;
- concurrent duplicate/conflicting writes cannot create two authorities;
- forced RLS/equivalent tenant isolation with a non-superuser role;
- backup/restore/recovery and integrity checks;
- measured hot-key/partition/lock behavior.

### HTTP, when introduced

- OpenAPI contract and status/error/security behavior;
- payload size limits and hostile input;
- async job lifecycle for expensive migration/evaluation work;
- connection close/shutdown behavior, including missing/alternate `close_connection` paths;
- authentication/authorization order;
- k6 realistic concurrency and latency after the service exists.

## Coverage and documentation gates

Touched production Rust targets 100% line/statement, branch, function/region coverage where supported by the selected toolchain, with complete beginner-readable public rustdoc and meaningful edge-case coverage. Coverage exclusions require an explicit architectural reason and review rather than a blanket pragma.

Deprecation warnings are fixed at the source rather than suppressed.

## Test data

Synthetic data is acceptable for unit/property tests. Production paths and readiness evidence must not silently depend on synthetic demo vectors. Migration acceptance uses versioned representative evaluation evidence, including target-native comparison and disclosed denominator/design.

Real person/institution identifiers are not required; fixtures use anonymous/opaque identifiers.
