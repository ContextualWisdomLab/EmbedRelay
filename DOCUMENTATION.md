# EmbedRelay Documentation Map

| Area | Canonical document |
|---|---|
| Product requirements | [`docs/PRD.md`](docs/PRD.md) |
| Technical requirements | [`docs/TRD.md`](docs/TRD.md) |
| Architecture | [`ARCHITECTURE.md`](ARCHITECTURE.md) |
| UML/runtime flows | [`docs/UML.md`](docs/UML.md) |
| Conceptual data model / ERD | [`docs/ERD.md`](docs/ERD.md) |
| API/port/version contract | [`docs/API_CONTRACT.md`](docs/API_CONTRACT.md) |
| Documentation fitness / gap matrix | [`docs/DOCUMENTATION_FITNESS.md`](docs/DOCUMENTATION_FITNESS.md) |
| Product / technical gap baseline | [`docs/product-technical-gap-baseline.md`](docs/product-technical-gap-baseline.md) |
| ADR register | [`docs/adr/README.md`](docs/adr/README.md) |
| Security | [`docs/SECURITY.md`](docs/SECURITY.md) |
| Threat model | [`docs/THREAT_MODEL.md`](docs/THREAT_MODEL.md) |
| Test/evaluation strategy | [`docs/TEST_STRATEGY.md`](docs/TEST_STRATEGY.md) |
| Operability/migration/rollback | [`docs/OPERABILITY.md`](docs/OPERABILITY.md) |
| Requirement/evidence traceability | [`docs/TRACEABILITY.md`](docs/TRACEABILITY.md) |
| Implemented-slice doctoring | [`docs/doctoring/`](docs/doctoring/) |
| Agent rules | [`AGENTS.md`](AGENTS.md) |
| Repository context | [`CLAUDE.md`](CLAUDE.md) |
| Product overview | [`README.md`](README.md) |
| Change history | [`CHANGELOG.md`](CHANGELOG.md) |

## Maturity labels

- **active-PR implemented:** executable source exists on PR #1 but is not protected-main/released functionality.
- **protected-main implemented:** executable source has passed protected integration but is not automatically a released product claim.
- **planned:** accepted target architecture without executable implementation yet.
- **accepted target:** governing product/architecture decision.
- **partial:** some authoritative contract exists while an acceptance-critical implementation/evidence boundary is absent.
- **conceptual:** logical entity or service boundary, not a claim of durable persistence/deployment.

`docs/DOCUMENTATION_FITNESS.md` is the authoritative place to determine whether a document family is current, intentionally consolidated, partial, planned, or not yet applicable. File presence alone is not completeness.

Current PR #1 contains the active-PR Rust space/vector/identity/tenant-registry contract **and** the PostgreSQL 18.x canonical-manifest, tenant-registry, append-only audit, forced-RLS, migration/rollback, and logical backup/restore acceptance slices. Those slices remain candidate implementation until the exact current head passes required integration evidence and lands on the protected branch.

Adapter training/evaluation, confidence-gated translation, dual-index routing, native backfill, provider/vector-store ports, deployable service APIs, broader production recovery architecture, and GPU compute remain planned or partial. The documentation map must not promote those target-architecture surfaces to current product behavior merely because their documents or diagrams exist.
