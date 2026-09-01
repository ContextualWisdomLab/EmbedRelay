# EmbedRelay Documentation Fitness Matrix

**Status:** Canonical documentation audit for the accepted product baseline and current M1 active-PR implementation.  
**Last reviewed:** 2026-09-02

## Purpose

This document records whether a product/architecture artifact is merely present, actually code-current, intentionally consolidated into another canonical document, still partial, or intentionally deferred until an executable boundary exists. It prevents planning material, target diagrams, PR prose, and conversation history from being mistaken for protected-main/as-built behavior.

The current documentation baseline is strong enough to guide M1 development, but it is **not complete for the whole commercial product lifecycle**. The active PR now includes a narrow executable PostgreSQL registry/RLS/audit slice; adapter evaluation/release evidence, whole-product research traceability, broader persisted-data governance, machine-readable service schemas, backup/restore evidence, and release/provenance receipts still must mature with their owning executable milestones.

## Fitness vocabulary

- **PRESENT-CURRENT** — canonical artifact exists and matches the current active implementation plus accepted target boundary.
- **PRESENT-STALE** — canonical artifact exists but materially contradicts current source or accepted decisions.
- **PARTIAL** — important content exists, but an acceptance-critical part is still distributed, incomplete, or not yet executable.
- **MISSING** — required authoritative information has no canonical repository home.
- **PLANNED** — intentionally deferred until the executable milestone that can validate the contract.
- **NOT-APPLICABLE** — not currently an honest artifact for the as-built product; a conceptual equivalent may exist.
- **SUPERSEDED** — an earlier planning artifact has been replaced by a canonical repository document.

Implementation maturity is tracked separately as active-PR implemented, protected-main implemented, accepted target, planned, partial, or out of scope. Active-PR implementation is not protected-main or release evidence until its exact head satisfies repository gates.

## Whole-product documentation matrix

| Documentation family | Fitness | Canonical authority / evidence | Required follow-through |
|---|---|---|---|
| Product requirements | **PRESENT-CURRENT** | `docs/PRD.md` | Keep the narrow durable M1 slice separate from later adapter/migration requirements and release claims. |
| Technical requirements | **PRESENT-CURRENT** | `docs/TRD.md` | Keep compute, persistence, ports, and migration maturity explicit. |
| System architecture | **PRESENT-CURRENT** | `ARCHITECTURE.md` | Promote target components to protected-main only with exact integration evidence. |
| UML / sequence / state / deployment views | **PRESENT-CURRENT** | `docs/UML.md` | Add concrete deployment/runtime sequences when an API and workers exist. |
| Data model | **PRESENT-CURRENT** | `docs/ERD.md` | Current Rust model, executable M1 physical slice, and broader planned control-plane model are separated explicitly. |
| Physical PostgreSQL ERD | **PRESENT-CURRENT** | `docs/ERD.md`; `migrations/0001_tenant_space_registry.*.sql`; `tests/postgres_registry_contract.sh` | Exact-head PostgreSQL 18.6 verification and backup/restore evidence remain required before protected-main/release promotion. |
| API / port / version contract | **PRESENT-CURRENT** | `docs/API_CONTRACT.md` | Current document is an accepted target contract, not a deployed HTTP service. |
| Machine-readable API and schema artifacts | **PLANNED** | No deployable service/schema artifact is authoritative yet. | Add OpenAPI/JSON Schema only with the implementing service/manifest milestone and executable conformance tests. |
| Security model | **PRESENT-CURRENT** | `docs/SECURITY.md`; forced RLS/append-only migration contract | Keep current M1 controls distinct from future KMS, artifact-signing, retention, service-role, and export controls. |
| Threat model | **PRESENT-CURRENT** | `docs/THREAT_MODEL.md` | Add abuse paths from adapters, migration workers, provider ports, and broader durable operations with their implementation. |
| Test strategy | **PRESENT-CURRENT** | `docs/TEST_STRATEGY.md`; Rust and PostgreSQL contracts | Preserve source-level, RLS/concurrency/rollback, retrieval, OOD, calibration, migration, security, and backend-parity gates by maturity. |
| Evaluation protocol | **PARTIAL** | Evaluation requirements are distributed across PRD, TRD, Test Strategy, and ADR-0010. | Before adapter fitting becomes executable, add one canonical protocol defining datasets/splits, native/source baselines, retrieval metrics, OOD/calibration, uncertainty, acceptance, reproducibility, and report schema. |
| Migration runbook | **PRESENT-CURRENT** | `docs/OPERABILITY.md` | Operability consolidates migration, rollback, stop conditions, recovery, capacity, and release evidence; measured restore evidence is still absent. |
| Operability / recovery | **PARTIAL** | `docs/OPERABILITY.md`; guarded down/up migration contract | Add disposable backup/restore acceptance and measured recovery evidence; migration rollback alone is not backup/recovery proof. |
| Requirements / implementation traceability | **PRESENT-CURRENT** | `docs/TRACEABILITY.md`; `docs/product-technical-gap-baseline.md` | Promote rows only after exact protected-main evidence; never from PR-body or predecessor-head claims. |
| Research and standards traceability | **PARTIAL** | Implemented M1 slices have focused records in `docs/doctoring/`. | Complete PostgreSQL boundary doctoring now; before the first adapter algorithm is accepted, add a whole-product research/standards index and APA 7 bibliography linking material algorithm/security/interoperability decisions to primary evidence. |
| ADR register | **PRESENT-CURRENT** | `docs/adr/README.md` | Keep one canonical decision register and explicit supersession. |
| Detailed ADR decision evidence | **PRESENT-CURRENT** | ADR-0001…0010 record drivers, alternatives, failure/recovery, security/governance, verification, migration/rollback, and supersession. | Keep the machine-checkable ADR structure synchronized with every new/superseding decision. |
| Data governance / privacy / retention | **PARTIAL** | PRD/TRD/Security classify vectors, anchors, adapter weights, logs, and artifacts as potentially sensitive. | Before broader persistence or export, define purpose, retention, deletion/export, encryption/KMS, residency, privileged access, and incident-evidence responsibilities. |
| Release / SBOM / provenance | **PARTIAL** | PRD, Architecture, Operability, and ADR-0010 define the target gates. | Add machine-verifiable release receipts, artifact identities, SBOM/provenance policy, reproducibility, rollback compatibility, and post-publication checks with the first releasable milestone. |
| Provider / vector-store capability matrix | **PARTIAL** | Neutrality is an accepted architectural decision. | Create a versioned capability matrix only when the first real ports exist; unsupported semantics must fail closed rather than be implied by docs. |
| AGENTS / CLAUDE / README / CHANGELOG alignment | **PRESENT-CURRENT** | Root repository documents | Recheck whenever ownership, persistence maturity, release gates, or product terminology changes. |

## Planning-baseline reconciliation

The pre-implementation planning baseline proposed several standalone files such as a data-model document, evaluation protocol, migration runbook, research traceability, reference bibliography, design-review checklist, OpenAPI, and JSON Schemas. The repository deliberately consolidates some concerns where one canonical document is clearer:

- data model and physical M1 ERD → `docs/ERD.md`;
- commercialization state/owner/action/verification → `docs/product-technical-gap-baseline.md`;
- migration/rollback/operator procedure → `docs/OPERABILITY.md`;
- design/release gate review → PRD/TRD/Test Strategy/ADR-0010 plus this fitness matrix.

That consolidation is not a missing-document defect. Evaluation protocol and whole-product research traceability remain **PARTIAL** because they become acceptance-critical before adapter algorithms can be promoted. Machine-readable HTTP/schema artifacts remain **PLANNED** because publishing them now would falsely imply an executable service contract.

## Current truth boundary

The current active implementation contains the Rust space/vector/identifier/tenant-registry contract plus a narrow PostgreSQL 18.x persistence slice for tenant-space registration and `space_registration_intent` audit. The physical slice has UUIDv7 identifiers, a tenant/fingerprint uniqueness contract, forced RLS, append-only mutation denial, transactionally coupled audit-first registration, guarded destructive rollback, a two-session concurrency test, and exact-head CI wiring for PostgreSQL 18.6.

The accepted target architecture additionally describes full canonical-manifest persistence, adapter training/evaluation, confidence gating, translation, dual-index routing, native backfill, provider/vector-store ports, artifact storage, workers, broader service/admin roles, KMS/retention/export governance, and optional GPU compute.

This documentation baseline **does not make a deployable API or the full durable PostgreSQL control plane as-built**. The narrow M1 physical slice is active-PR source only until its current exact head passes PostgreSQL/Rust/security/review gates and merges. Backup/restore evidence remains incomplete even after migration rollback tests pass.

## ADR quality gate

Each governing ADR must answer all of the following rather than recording only the preferred design:

1. What context and constraints forced a decision?
2. Which decision drivers mattered?
3. Which materially distinct alternatives were considered and why were they rejected or deferred?
4. What exactly is the decision?
5. What consequences and trade-offs follow?
6. How does the system fail and recover?
7. What security, privacy, and governance effects follow?
8. What tests/evidence accept the decision?
9. How is migration or rollback performed?
10. What later evidence or decision supersedes it?

The repository test `documentation_contract.rs` makes this structure machine-checkable.

## Next documentation promotions

Documentation work must follow executable ownership rather than run ahead of it:

- **M1 durable registry:** exact-head PostgreSQL/Rust/security verification, PostgreSQL doctoring, and measured backup/restore evidence must complete before protected-main/release promotion.
- **Full space manifest persistence:** promote only after the canonical manifest/version schema and migration tests exist; do not duplicate mutable compatibility facts heuristically.
- **First adapter-fitting milestone:** create the canonical evaluation protocol and whole-product research/APA-7 index before production acceptance.
- **First service/API milestone:** add machine-readable OpenAPI/schema artifacts generated or checked against the executable contract.
- **First provider/vector-store port:** add the capability/version matrix and real interoperability evidence.
- **First release candidate:** add exact release/provenance/SBOM/reproducibility/rollback receipts and post-publication acceptance.

## Review rule

A documentation family may move to PRESENT-CURRENT from live active-PR source evidence, but its implementation maturity must remain explicit. Active-PR implementation is not protected-main behavior, and protected-main code is not release evidence until the release acceptance contract is satisfied.
