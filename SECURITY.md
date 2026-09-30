# EmbedRelay security baseline

Status: pre-release security design; no production certification claim
Last reconciled: 2026-09-02

## Trust boundaries

EmbedRelay treats the following as separate trust boundaries:

- caller / consuming application;
- identity and authorization authority (Keyverse in the CWL deployment profile);
- EmbedRelay service/domain runtime;
- embedding provider/runtime;
- vector store;
- persistence/audit store if later introduced;
- release/artifact distribution system.

Provider SDKs, tokens, vector-store credentials and sibling private databases are never trusted domain state.

## Principal threats

### Cross-tenant vector or migration access

Risk: a caller reads, converts, evaluates or releases another tenant's spaces/migrations.

Controls: verified issuer/audience/time/subject/tenant claims, service-operation authorization before tenant work, tenant-safe references, forced RLS/equivalent isolation where persistence exists, cross-tenant negative tests, and no caller-supplied tenant override.

### Embedding-space confusion

Risk: equal dimensions or similar model names are treated as compatibility.

Controls: immutable material `embedding_space_identity`, fail-closed mismatch, explicit source/target/adapter identities, no silent same-space fallback.

### Numerical poisoning or malformed vectors

Risk: NaN/infinity/subnormal/zero-norm/wrong precision/dimension or adversarial values corrupt conversion/evaluation.

Controls: Rust boundary validation before numerical work, bounded payload sizes, deterministic error/abstention outcomes, fuzz/property/edge tests with a full failure denominator.

### Unsupported/OOD vectors accepted as valid conversions

Risk: low-confidence or distribution-shifted vectors silently enter a target index.

Controls: calibrated OOD/abstention policy with versioned evidence; no unproven threshold; fail closed when calibration/policy evidence is absent.

### Migration evidence tampering or rollback ambiguity

Risk: an operator cannot prove which adapter/policy/evaluation released a migration or restore the prior state.

Controls: immutable digests/identities, append-only completed receipts when persisted, release/rollback/supersession evidence, signed/provenance-bound artifacts where supported, recovery tests before durability claims.

### Credential/provider payload leakage

Risk: tokens, provider responses or sensitive vectors leak via domain records/logs/public artifacts.

Controls: secret manager/platform secret boundary, redaction/exclusion of secrets in logs and errors, minimum necessary audit metadata, authorization/purpose/retention controls for non-masked operational evidence, no secrets in public packages/SBOM/provenance.

### Supply-chain compromise

Risk: mutable CI actions/dependencies or unsafe release artifacts modify evidence.

Controls: commit-pinned GitHub Actions, dependency/SAST/security review, lockfiles/checksums for runtime dependencies, SBOM/provenance, exact-head release evidence, no protected-branch self-materializer as durable authority.

## PII and sensitive evidence

EmbedRelay should not require ordinary personal identity attributes. Tenant and actor references should be opaque verified identities. Where raw vectors or migration datasets can encode sensitive information, protect them through access control, purpose limitation, encryption, retention/legal hold, auditable export, and least-privilege storage. Blanket masking must not destroy numerical validity or incident/recovery evidence.

## Incident and vulnerability handling

Security findings remain fail-closed. Do not suppress scanners/deprecation warnings or convert an unavailable required security check into success. Affected release identities, source/target spaces, adapter/policy revisions and provenance should be sufficient to scope an incident without copying provider secrets into issue text.

## Compliance posture

Architecture should support evidence useful for SOC 2 and CSAP-style controls, but this repository does not claim certification. Implementation evidence, organizational control operation and external certification remain separate.

## Reporting

Use the repository/organization private security reporting path when available. Do not post credentials, private vectors, customer data or exploit-bearing sensitive artifacts into a public issue.
