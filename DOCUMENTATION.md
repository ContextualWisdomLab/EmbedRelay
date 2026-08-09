# EmbedRelay Documentation Map

| Area | Canonical document |
|---|---|
| Product requirements | [`docs/PRD.md`](docs/PRD.md) |
| Technical requirements | [`docs/TRD.md`](docs/TRD.md) |
| Architecture | [`ARCHITECTURE.md`](ARCHITECTURE.md) |
| UML/runtime flows | [`docs/UML.md`](docs/UML.md) |
| Conceptual data model / ERD | [`docs/ERD.md`](docs/ERD.md) |
| API/port/version contract | [`docs/API_CONTRACT.md`](docs/API_CONTRACT.md) |
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
- **planned:** accepted target architecture without executable implementation yet.
- **accepted target:** governing product/architecture decision.
- **conceptual:** logical entity or service boundary, not a claim of durable persistence/deployment.

Current PR #1 implements the storage-independent M1 space/vector/identity/tenant-registry contract. PostgreSQL durability/RLS, adapter training, dual-index routing, confidence-gated translation, native backfill, provider/vector-store ports, and GPU compute remain planned.