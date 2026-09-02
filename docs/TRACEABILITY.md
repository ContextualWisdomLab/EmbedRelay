# EmbedRelay Requirements, Decisions, and Evidence Traceability

**Status:** Accepted active-PR baseline  
**Last reviewed:** 2026-09-02

| Product/architecture requirement | Decision/doc | Current source/evidence | Maturity |
|---|---|---|---|
| immutable complete space identity | PRD-FR-001; ADR-0002 | `manifest` Rust domain contract + tests; canonical identity is `sha256:<64 lowercase hex>` | active PR implemented |
| exact canonical identity persistence | PRD-FR-001; PostgreSQL doctoring | `migrations/0001_tenant_space_registry.up.sql`; `tests/postgres_registry_contract.sh`; `tests/postgres_backup_restore_contract.sh`; RED tests `1a5222b0...` / `19e018bd...`, production repair `d218c4a2...` | active PR implemented; successor-head PostgreSQL CI required |
| fail-closed vector/space compatibility | PRD-FR-002; ADR-0002 | `vector` Rust domain contract + vector tests | active PR implemented |
| opaque UUIDv7 durable identifiers | PRD-FR-008 boundary | `identifier` Rust contract + RFC test vector | active PR implemented |
| tenant-isolated audit-before-mutation registration | PRD-FR-008; ADR-0009 | `registry` contract + tenant/audit tests | active PR implemented; Rust reference contract |
| PostgreSQL tenant RLS/audit | PRD-FR-008; ADR-0009 | `migrations/0001_tenant_space_registry.*.sql`, `tests/postgres_registry_contract.sh`, physical ERD | active PR implemented; exact PostgreSQL 18.6 CI pending on each new head |
| logical backup/restore acceptance | PRD release/operability boundary | `tests/postgres_backup_restore_contract.sh`, CI recovery step | active PR implemented candidate; fixture evidence only, not production RTO/RPO/PITR |
| locked Rust dependency resolution | PRD quality/release boundary; ADR-0010 | tracked `Cargo.lock`; CI `cargo test --workspace --locked`; locked LLVM coverage | active PR implemented; exact-head CI required |
| directional role-specific adapters | PRD-FR-003; ADR-0003 | PRD/TRD/Architecture | planned |
| tiered algorithm portfolio | ADR-0004 | TRD/Test Strategy | planned |
| retrieval-level fidelity evaluation | PRD-FR-004; ADR-0010 | Test Strategy | planned |
| confidence gate/abstention | PRD-FR-010; ADR-0007 | API/TRD/Test Strategy | planned |
| dual-index migration | PRD-FR-006; ADR-0005 | Architecture/UML/Operability | planned |
| target-native backfill | PRD-FR-007; ADR-0001/0005 | Architecture/Operability | planned |
| provider/vector-store neutrality | ADR-0008 | Architecture/API | planned |
| Rust CPU reference/GPU parity | ADR-0006 | TRD/Test Strategy | CPU domain contract only; computational GPU path planned |
| sensitive asset/provenance boundary | ADR-0009 | Security/Threat/ERD | partial; M1 registry/audit persistence active-PR implemented, broader persisted-data governance planned |
| one-hop/release evidence | ADR-0010 | PRD/Test/Operability | accepted target |

## Current M1 persistence evidence

The active PR contains a narrow executable PostgreSQL boundary in addition to the Rust reference contract:

- `tenant_space_registry` stores one immutable tenant/fingerprint registration per `(tenant_id, space_fingerprint)`;
- `space_registration_audit` stores the append-only `space_registration_intent` evidence;
- both relations store the Rust domain's exact canonical `sha256:<64 lowercase hex>` fingerprint unchanged and reject bare digests or non-canonical case;
- a deferred natural-key foreign key lets the audit intent be inserted first while requiring the registration to exist at transaction commit;
- both tables enable and force RLS against explicit `embedrelay.tenant_id` session context;
- update/delete/truncate mutations fail closed through append-only triggers;
- duplicate and concurrent same-item registration uses deterministic unique-key rejection rather than an implicit UPSERT;
- the PostgreSQL contract tests missing tenant context, exact canonical fingerprint validation, UUIDv7 IDs, cross-tenant denial, immutability, two-session contention, guarded rollback, and migration reapplication;
- logical backup/restore acceptance carries canonical fingerprints and exact durable UUIDs through `pg_dump`/`pg_restore`, then re-proves RLS, append-only controls, ACLs/comments, tenant views, and outsider denial;
- CI supplies PostgreSQL 18.6 and runs these contracts from the exact pull-request checkout.

The representation repair was test-first: `1a5222b0dcc6d3f03e195bc63811c05da4461aac` made the primary PostgreSQL contract require the exact Rust identity and reject a bare digest; `19e018bd842a38ca523ed9c7e3b6a8a91d928739` did the same for recovery fixtures; `d218c4a24164edf7fc5bd74fc3ca880402fa9ecf` changed the migration/function constraints to `^sha256:[0-9a-f]{64}$`. Successor-head results are still required before promotion.

These are **active-PR implemented** facts only. Until the current exact head passes the PostgreSQL/recovery contracts and all required security/review gates, they are not protected-main or release evidence. Full immutable manifest persistence remains a separate commercialization gap.

## Current M1 doctoring evidence

Focused doctoring records under `docs/doctoring/` cover vector safety, UUIDv7 identity, tenant-registry audit, and PostgreSQL registry/RLS/audit/recovery boundaries. Those records preserve standards/research, TDD lineage, failure/recovery, and rollback evidence for implemented slices. Broader adapter/migration references must be added to authoritative doctoring as each algorithm or service boundary becomes executable; planning research alone is not implementation evidence.

## Maturity definitions

- **active PR implemented:** executable source and tests exist on PR #1 but are not protected-main/released behavior; exact-head verification may still be pending after a new commit.
- **partial:** a bounded subset exists while a materially broader product/service, recovery, or governance contract remains incomplete.
- **planned:** accepted product/architecture target with no executable implementation evidence yet.
- **accepted target:** policy/design gate that applies to future implementation and release.

## Evidence promotion rule

A row moves to protected-main/as-built only after the implementing exact head is merged and protected-main verification exists. Predecessor-head CI, local planning validation, generated downloads, PR-body claims, queued checks, or automated comments are not sufficient promotion evidence. Every documentation-only commit also changes the exact head and therefore requires fresh gate evidence before promotion.

## Research/standards rule

Each material algorithm, security, interoperability, and database decision must cite primary technical standards and peer-reviewed primary research where applicable in APA 7 style under `docs/doctoring/`. When evidence is later contradicted or superseded, update the ADR/doctoring and preserve the historical rationale rather than silently changing the claim.
