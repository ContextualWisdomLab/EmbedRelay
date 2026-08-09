# Changelog

All notable changes to EmbedRelay are recorded here. The project has not published its first release; entries remain under **Unreleased** until the complete release-acceptance contract is satisfied.

## Unreleased

### Added

- Strict RFC 9562 UUIDv7 identifiers for future registry and audit keys. Generated identifiers are process-locally creation-ordered; external identifiers fail closed unless both the RFC variant and version-7 contract are satisfied, and parse failures do not reflect caller-controlled input.
- Fail-closed Rust `float32` embedding-vector validation bound to the complete canonical embedding-space fingerprint. The contract rejects dimension mismatches, non-finite and subnormal components, zero-norm vectors, and scalar-precision mismatches, and permits a metric operation only after both vectors prove identical embedding-space identity rather than merely matching dimensions.
- Tenant-isolated audit-before-mutation space registration. The storage-independent Rust reference contract keys registration by tenant plus complete canonical space fingerprint, rejects duplicates before emitting another intent, requires audit acceptance before state visibility, leaves state unchanged when audit recording fails, and permits equal space fingerprints to remain isolated across tenants.
- Canonical PRD, TRD, architecture, UML, conceptual ERD, API, security, threat-model, test, operability, traceability, and ten-ADR documentation baselines, plus a Rust documentation contract that prevents planned PostgreSQL, adapter, and migration boundaries from being misrepresented as already implemented.
