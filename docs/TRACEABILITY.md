# EmbedRelay Requirements, Decisions, and Evidence Traceability

**Status:** Accepted baseline  
**Last reviewed:** 2026-08-09

| Product/architecture requirement | Decision/doc | Current source/evidence | Maturity |
|---|---|---|---|
| immutable complete space identity | PRD-FR-001; ADR-0002 | `manifest` Rust domain contract + tests | active PR implemented |
| fail-closed vector/space compatibility | PRD-FR-002; ADR-0002 | `vector` Rust domain contract + vector tests | active PR implemented |
| opaque UUIDv7 durable identifiers | PRD-FR-008 boundary | `identifier` Rust contract + RFC test vector | active PR implemented |
| tenant-isolated audit-before-mutation registration | PRD-FR-008; ADR-0009 | `registry` contract + tenant/audit tests | active PR implemented, in-memory only |
| directional role-specific adapters | PRD-FR-003; ADR-0003 | PRD/TRD/Architecture | planned |
| tiered algorithm portfolio | ADR-0004 | TRD/Test Strategy | planned |
| retrieval-level fidelity evaluation | PRD-FR-004; ADR-0010 | Test Strategy | planned |
| confidence gate/abstention | PRD-FR-010; ADR-0007 | API/TRD/Test Strategy | planned |
| dual-index migration | PRD-FR-006; ADR-0005 | Architecture/UML/Operability | planned |
| target-native backfill | PRD-FR-007; ADR-0001/0005 | Architecture/Operability | planned |
| provider/vector-store neutrality | ADR-0008 | Architecture/API | planned |
| Rust CPU reference/GPU parity | ADR-0006 | TRD/Test Strategy | CPU contract only; GPU planned |
| sensitive asset/provenance boundary | ADR-0009 | Security/Threat/ERD | partial/planned persistence |
| one-hop/release evidence | ADR-0010 | PRD/Test/Operability | accepted target |
| PostgreSQL tenant RLS/audit | PRD-FR-008 | ERD/Security/Operability | planned, not current |

## Current M1 doctoring evidence

The active implementation already carries focused doctoring records under `docs/doctoring/` for:

- vector-safety contract;
- UUIDv7 identifier boundary;
- tenant-registry audit boundary.

Those records contain the exact standards/research and TDD/rollback evidence for implemented M1 slices. Broader adapter/migration references must be added to authoritative doctoring as each algorithm or service boundary becomes executable; planning research alone is not implementation evidence.

## Maturity definitions

- **active PR implemented:** executable source and tests exist on PR #1 but are not protected-main/released behavior.
- **partial:** some domain contract exists, while durable service/persistence enforcement is absent.
- **planned:** accepted product/architecture target with no executable source yet.
- **accepted target:** policy/design gate that applies to future implementation and release.

## Evidence promotion rule

A row moves to protected-main/as-built only after the implementing exact head is merged and protected-main verification exists. Predecessor-head CI, local planning validation, generated downloads, PR-body claims, queued checks, or automated comments are not sufficient promotion evidence.

## Research/standards rule

Each material algorithm, security, interoperability, and database decision must cite primary technical standards and peer-reviewed primary research where applicable in APA 7 style under `docs/doctoring/`. When evidence is later contradicted or superseded, update the ADR/doctoring and preserve the historical rationale rather than silently changing the claim.