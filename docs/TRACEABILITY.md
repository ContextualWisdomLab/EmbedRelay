# EmbedRelay Requirements, Decisions, and Evidence Traceability

**Status:** Accepted active-PR baseline  
**Last reviewed:** 2026-09-02

<!-- status:active-pr-implemented -->
<!-- status:planned -->

The stable status markers above are machine-readable maturity anchors. Executable rows remain active-PR implementation until exact-head promotion; planned rows remain non-executable target capabilities.

| Product/architecture requirement | Decision/doc | Current source/evidence | Maturity |
|---|---|---|---|
| immutable complete space identity | PRD-FR-001; ADR-0002 | Rust `manifest` contract + tests; canonical identity `sha256:<64 lowercase hex>` | active PR implemented |
| exact canonical fingerprint persistence | PRD-FR-001; PostgreSQL doctoring | migration 0001 + registry/recovery contracts; earlier representation repair lineage | active PR implemented; exact-head PostgreSQL CI required |
| full immutable v1 canonical manifest persistence | PRD-FR-001; TRD §3/§10; ERD | `migrations/0002_embedding_space_manifest.*.sql`; `tests/postgres_manifest_persistence_contract.sh`; CI manifest step | active PR implemented; exact-head PostgreSQL 18.6 verification required |
| Rust/PostgreSQL manifest↔fingerprint equivalence | ADR-0002; PostgreSQL doctoring | frozen Rust fingerprint fixture; DB recomputation using the same domain separator, field order, UTF-8 byte-length framing, SHA-256 | active PR implemented; exact-head golden fixture verification required |
| fail-closed vector/space compatibility | PRD-FR-002; ADR-0002 | Rust `vector` contract + tests | active PR implemented |
| opaque UUIDv7 durable identifiers | PRD-FR-008 boundary | Rust `identifier` contract + RFC test vector | active PR implemented |
| tenant-isolated audit-before-mutation registration | PRD-FR-008; ADR-0009 | Rust registry contract + tenant/audit tests | active PR implemented |
| PostgreSQL tenant RLS/audit | PRD-FR-008; ADR-0009 | migration 0001 + registry contract | active PR implemented; exact-head CI required |
| canonical manifest tenant visibility | PRD-FR-008; Security/ERD | forced RLS on `embedding_space_manifest`; visibility derived through current tenant registration; outsider-denial contract | active PR implemented; exact-head CI required |
| append-only canonical registry state | Security/Operability | append-only triggers on registry/audit/manifest + guarded down migrations | active PR implemented; exact-head lifecycle verification required |
| logical backup/restore acceptance | release/operability boundary | `tests/postgres_backup_restore_contract.sh` | active PR candidate; restores exact tenant registrations, audit IDs, canonical manifest material and controls; not production RTO/RPO/PITR |
| locked Rust dependency resolution | quality/release boundary; ADR-0010 | tracked `Cargo.lock`; locked stable tests/LLVM coverage | active PR implemented; exact-head CI required |
| directional role-specific adapters | PRD-FR-003; ADR-0003 | PRD/TRD/Architecture | planned |
| tiered algorithm portfolio | ADR-0004 | TRD/Test Strategy | planned |
| retrieval-level fidelity evaluation | PRD-FR-004; ADR-0010 | Test Strategy | planned |
| confidence gate/abstention | PRD-FR-010; ADR-0007 | API/TRD/Test Strategy | planned |
| dual-index migration | PRD-FR-006; ADR-0005 | Architecture/UML/Operability | planned |
| target-native backfill | PRD-FR-007; ADR-0001/0005 | Architecture/Operability | planned |
| provider/vector-store neutrality | ADR-0008 | Architecture/API | planned |
| Rust CPU reference/GPU parity | ADR-0006 | TRD/Test Strategy | CPU domain contract only; computational GPU path planned |
| sensitive asset/provenance boundary | ADR-0009 | Security/Threat/ERD | partial; M1 registry/manifest/audit persistence active-PR implemented, broader governance planned |
| one-hop/release evidence | ADR-0010 | PRD/Test/Operability | accepted target |

## Current M1 persistence evidence

The active PR now contains three normalized physical relations:

- `embedding_space_manifest` stores one immutable v1 canonical compatibility fact per exact fingerprint;
- `tenant_space_registry` stores one tenant/fingerprint association per `(tenant_id, space_fingerprint)`;
- `space_registration_audit` stores append-only `space_registration_intent` evidence.

The manifest-bearing command `register_tenant_space_manifest(uuid, text, jsonb)` accepts exactly the twelve v1 material keys, validates string/hash/dimension contracts, recomputes the same domain-separated SHA-256 identity as the Rust implementation, rejects mismatch before durable state, performs audit-first tenant registration, and insert-or-matches the canonical manifest in the same transaction. Deferred references require every committed tenant registration to resolve to canonical material while preserving audit-before-visibility ordering.

Tenant registration remains duplicate-rejecting rather than UPSERT-based. Canonical manifest persistence intentionally uses insert-or-match because identical immutable compatibility material can be reused by different tenants; a conflict is accepted only after every stored material field matches. Forced RLS prevents an unregistered tenant from enumerating the shared canonical manifest catalog.

The manifest persistence slice was introduced test-first: `af19815bd8da0ea38f5cd9346abe4bc9b3d4e519` added the failing contract before migration 0002 existed; `2dec733cbe20f021a87e95ca7923bccd2ba7261f` wired it into exact-head CI; `8aa5b3231741b6c1f5a3227c5c3f8cf15926b915` added the production migration/function; `c58edc97c104bda44c2a0e020cf5ad2ec49dc4d7` added guarded rollback; `f1e5ddd5118f4781eefdacf59b62bd6f89596ea4` added migration lifecycle verification; and `b4bbbf291cd69805d476ef5e5dd3c6e62ba92ae4` extended logical recovery to full canonical manifest state. These commit IDs are TDD lineage only; passing evidence must come from the current exact head.

## Research and standards traceability

The database-side equivalence check uses PostgreSQL 18 core `sha256(bytea)` and hexadecimal encoding rather than adding a cryptographic extension. The algorithm itself is not redefined by PostgreSQL: the Rust manifest contract remains the canonical field ordering/domain-framing specification, while PostgreSQL independently recomputes that value as a fail-closed persistence guard. The focused doctoring record for canonical manifest persistence preserves this boundary and the authoritative PostgreSQL reference.

## Maturity definitions

- **active PR implemented:** executable source and tests exist on PR #1 but are not protected-main/released behavior; exact-head verification may still be pending after a new commit.
- **partial:** a bounded subset exists while a materially broader product/service, recovery, or governance contract remains incomplete.
- **planned:** accepted product/architecture target with no executable implementation evidence yet.
- **accepted target:** policy/design gate that applies to future implementation and release.

## Evidence promotion rule

A row moves to protected-main/as-built only after the implementing exact head is merged and protected-main verification exists. Predecessor-head CI, local planning validation, generated downloads, PR-body claims, queued checks, or automated comments are not sufficient promotion evidence. Every documentation-only commit also changes the exact head and therefore requires fresh gate evidence before promotion.

## Research/standards rule

Each material algorithm, security, interoperability, and database decision must cite primary technical standards and peer-reviewed primary research where applicable in APA 7 style under `docs/doctoring/`. When evidence is contradicted or superseded, update the ADR/doctoring record and preserve historical rationale rather than silently changing the claim.
