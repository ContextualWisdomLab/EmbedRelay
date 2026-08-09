# EmbedRelay Documentation Fitness Matrix

**Status:** Canonical documentation audit for the accepted product baseline and current M1 active-PR implementation.  
**Last reviewed:** 2026-08-09

## Purpose

This document records whether a product/architecture artifact is merely present, actually code-current, intentionally consolidated into another canonical document, still partial, or intentionally deferred until an executable boundary exists. It prevents planning material, target diagrams, PR prose, and conversation history from being mistaken for protected-main/as-built behavior.

The current documentation baseline is strong enough to guide M1 development, but it is **not complete for the whole commercial product lifecycle**. In particular, adapter evaluation/release evidence, whole-product research traceability, persisted-data governance, machine-readable service schemas, and release/provenance receipts must mature with the executable milestones that own them.

## Fitness vocabulary

- **PRESENT-CURRENT** — canonical artifact exists and matches the current active implementation plus accepted target boundary.
- **PRESENT-STALE** — canonical artifact exists but materially contradicts current source or accepted decisions.
- **PARTIAL** — important content exists, but an acceptance-critical part is still distributed, incomplete, or not yet executable.
- **MISSING** — required authoritative information has no canonical repository home.
- **PLANNED** — intentionally deferred until the executable milestone that can validate the contract.
- **NOT-APPLICABLE** — not currently an honest artifact for the as-built product; a conceptual equivalent may exist.
- **SUPERSEDED** — an earlier planning artifact has been replaced by a canonical repository document.

Implementation maturity is tracked separately as active-PR implemented, protected-main implemented, accepted target, planned, partial, or out of scope. A target diagram or accepted architecture is not evidence that its runtime exists.

## Whole-product documentation matrix

| Documentation family | Fitness | Canonical authority / evidence | Required follow-through |
|---|---|---|---|
| Product requirements | **PRESENT-CURRENT** | `docs/PRD.md` | Reconcile buyer/release criteria when later milestones become executable. |
| Technical requirements | **PRESENT-CURRENT** | `docs/TRD.md` | Keep compute, persistence, ports, and migration maturity explicit. |
| System architecture | **PRESENT-CURRENT** | `ARCHITECTURE.md` | Promote target components to as-built only with protected integration evidence. |
| UML / sequence / state / deployment views | **PRESENT-CURRENT** | `docs/UML.md` | Add concrete deployment/runtime sequences when the API and workers exist. |
| Data model | **PRESENT-CURRENT** | `docs/ERD.md` | Current in-memory model plus explicitly conceptual PostgreSQL target is sufficient for M1 design. |
| Physical PostgreSQL ERD | **NOT-APPLICABLE** | No physical schema is as-built yet. | Replace this status only when migrations, rollback, constraints, indexes, RLS, and recovery are executable and verified. |
| API / port / version contract | **PRESENT-CURRENT** | `docs/API_CONTRACT.md` | Current document is an accepted target contract, not a deployed HTTP service. |
| Machine-readable API and schema artifacts | **PLANNED** | No deployable service/schema artifact is authoritative yet. | Add OpenAPI/JSON Schema only with the implementing service/manifest milestone and executable conformance tests. |
| Security model | **PRESENT-CURRENT** | `docs/SECURITY.md` | Reconcile with RLS/KMS/artifact-signing implementation as those controls land. |
| Threat model | **PRESENT-CURRENT** | `docs/THREAT_MODEL.md` | Add abuse paths from adapters, migration workers, provider ports, and durable operations with their implementation. |
| Test strategy | **PRESENT-CURRENT** | `docs/TEST_STRATEGY.md` | Preserve source-level, retrieval, OOD, calibration, migration, security, and backend-parity gates by maturity. |
| Evaluation protocol | **PARTIAL** | Evaluation requirements are distributed across PRD, TRD, Test Strategy, and ADR-0010. | Before adapter fitting becomes executable, add one canonical protocol defining datasets/splits, native/source baselines, retrieval metrics, OOD/calibration, uncertainty, acceptance, reproducibility, and report schema. |
| Migration runbook | **PRESENT-CURRENT** | `docs/OPERABILITY.md` | Operability intentionally consolidates migration, rollback, stop conditions, recovery, capacity, and release evidence. |
| Operability / recovery | **PRESENT-CURRENT** | `docs/OPERABILITY.md` | Replace target-only PostgreSQL procedures with measured backup/restore and SLO evidence when deployable. |
| Requirements / implementation traceability | **PRESENT-CURRENT** | `docs/TRACEABILITY.md` | Promote rows only after exact protected-main evidence; never from PR-body or predecessor-head claims. |
| Research and standards traceability | **PARTIAL** | Implemented M1 slices have focused records in `docs/doctoring/`. | Before the first adapter algorithm is accepted, add a whole-product research/standards index and APA 7 bibliography linking each material algorithm/security/interoperability decision to primary evidence. |
| ADR register | **PRESENT-CURRENT** | `docs/adr/README.md` | Keep one canonical decision register and explicit supersession. |
| Detailed ADR decision evidence | **PARTIAL** | ADR-0001…0010 contain the accepted decisions but the original versions were intentionally concise. | All governing ADRs must include drivers, alternatives, failure/recovery, security/governance, verification, migration/rollback, and supersession. The documentation contract enforces this in the current change. |
| Data governance / privacy / retention | **PARTIAL** | PRD/TRD/Security classify vectors, anchors, adapter weights, logs, and artifacts as potentially sensitive. | Before durable persistence or export is enabled, define purpose, retention, deletion/export, encryption/KMS, residency, privileged access, and incident-evidence responsibilities. |
| Release / SBOM / provenance | **PARTIAL** | PRD, Architecture, Operability, and ADR-0010 define the target gates. | Add machine-verifiable release receipts, artifact identities, SBOM/provenance policy, reproducibility, rollback compatibility, and post-publication checks with the first releasable milestone. |
| Provider / vector-store capability matrix | **PARTIAL** | Neutrality is an accepted architectural decision. | Create a versioned capability matrix only when the first real ports exist; unsupported semantics must fail closed rather than be implied by docs. |
| AGENTS / CLAUDE / README / CHANGELOG alignment | **PRESENT-CURRENT** | Root repository documents | Recheck whenever ownership, release gates, or product terminology changes. |

## Planning-baseline reconciliation

The pre-implementation planning baseline proposed several standalone files such as a data-model document, evaluation protocol, migration runbook, research traceability, reference bibliography, design-review checklist, OpenAPI, and JSON Schemas. The repository has deliberately **consolidated** some of those concerns where one canonical document is clearer:

- data model → `docs/ERD.md`;
- migration/rollback/operator procedure → `docs/OPERABILITY.md`;
- design/release gate review → PRD/TRD/Test Strategy/ADR-0010 plus this fitness matrix.

That consolidation is not a missing-document defect. By contrast, the matrix keeps evaluation protocol and whole-product research traceability **PARTIAL** because those acceptance contracts become important before adapter algorithms can be promoted. Machine-readable HTTP/schema artifacts remain **PLANNED** because publishing them now would falsely imply an executable service contract.

## Current truth boundary

The current active implementation contains a Rust space/vector/identifier/tenant-registry contract and an audit-intent boundary. The accepted target architecture additionally describes PostgreSQL durability/RLS, adapter training/evaluation, confidence gating, translation, dual-index routing, native backfill, provider/vector-store ports, artifact storage, workers, and optional GPU compute.

This documentation baseline **does not make a deployable API or durable PostgreSQL control plane as-built**. Those claims require executable migrations/services, exact tests, security evidence, operability/recovery proof, and protected integration.

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

- **M1 durable registry:** promote physical data/RLS/audit/recovery facts only after migrations and PostgreSQL tests exist.
- **First adapter-fitting milestone:** create the canonical evaluation protocol and whole-product research/APA-7 index before production acceptance.
- **First service/API milestone:** add machine-readable OpenAPI/schema artifacts generated or checked against the executable contract.
- **First provider/vector-store port:** add the capability/version matrix and real interoperability evidence.
- **First release candidate:** add exact release/provenance/SBOM/reproducibility/rollback receipts and post-publication acceptance.

## Review rule

A documentation family may move to PRESENT-CURRENT only from live repository evidence. Active-PR implementation is not protected-main behavior, and protected-main code is not release evidence until the release acceptance contract is satisfied.