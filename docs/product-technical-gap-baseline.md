# EmbedRelay product and technical Gap baseline

Status: Proposed

Assessment date: 2026-09-26

Evidence boundary: protected `main@816dcacd4fc1903d91c5cae9b77e37e21811a78d`; public-surface source `0fc8fb34341c43876953e9d72d97060145d61f7f`; RED documentation contract `34c56035c00e18ce81ffa20d30d04ad6064f8c9d`; pull request [#5](https://github.com/ContextualWisdomLab/EmbedRelay/pull/5). Pull-request evidence is Proposed and does not establish protected-branch integration, a release, or publication.

## Goal

Provide a reusable, independently releasable contract for embedding-space identity and migration so consumers can reject incompatible vectors, preserve provenance, and perform observable cutover and rollback without surrendering product-domain authority.

## Context Map

| Context | Relationship to EmbedRelay | Authority retained outside EmbedRelay |
| --- | --- | --- |
| Product consumers | Customer/Supplier through a released contract and consumer-owned Anti-Corruption Layer | Domain truth, Ubiquitous Language, source data, authorization, product release |
| Embedding producers | Upstream producer of model identity, dimensions, normalization, and provenance inputs | Model execution and provider credentials |
| ConceptWeave | Separate ontology generation and publication context | Ontology and semantic-layer releases |
| semantic-data-portal | Separate catalog, governance, search, and serving context | Catalog policy and governed discovery |
| contextual-orchestrator | Separate provider discovery, capability verification, and routing context | Provider/model routing and gateway policy |

No integration in this table is claimed to be released or operational.

## Product and design evidence

| Artifact | Status | Current evidence | Action |
| --- | --- | --- | --- |
| PRD | Missing | No protected or proposed PRD found in the assessed source | Define users, migration scenes, measurable outcomes, exclusions, and acceptance evidence before implementation |
| TRD | Missing | No protected or proposed TRD found | Specify versioned identifiers, compatibility rules, API/schema, failure behavior, observability, rollback, and conformance |
| ADR | Missing | Responsibility prose exists but no reconstructable decision record | Record alternatives, selected boundary, rejected ownership moves, risks, operational scenes, and follow-up |
| UML | Missing | No component, sequence, or state model found | Add only diagrams that bind to the released API and migration lifecycle |
| ERD | Not yet applicable | No persistent store or schema is implemented | Reassess before introducing storage; document keys, constraints, retention, and migrations if persistence is selected |
| Architecture | Partial | README and `docs/index.md` define responsibility and integration boundaries | Bind the boundary to the future TRD, ADR, API schema, conformance fixtures, and release |

## Gap register

| Gap | Evidence | Action | Status |
| --- | --- | --- | --- |
| G-001 — no executable contract or implementation | No package metadata, API schema, runtime, or immutable Release is present | Create PRD/TRD/ADR first; then develop the minimal owner contract RED → GREEN → immutable release | Open |
| G-002 — no conformance and edge-case suite | Only the public-documentation contract exists | Add producer/consumer fixtures for unknown identity, dimension mismatch, normalization mismatch, partial migration, rollback, and provenance loss | Open |
| G-003 — license and provenance unresolved | No repository-level `LICENSE`, NOTICE, third-party notice, SBOM, or package metadata exists | Verify ownership and inbound provenance; select an ecosystem-consistent license only if rights are established; bind NOTICE, SBOM, and provenance to the same release | Blocked on rights evidence |
| G-004 — release and consumer version bump absent | No immutable package or GitHub Release is present | Publish only after exact-head build, schema, conformance, security, SBOM, provenance, license, NOTICE, and third-party obligations pass; then bump a real consumer through its ACL | Open |
| G-005 — Pages publication unverified | `docs/index.md` is proposed source; no live HTTP or rendered-source proof is recorded | Integrate protected source, reconcile Pages settings through the canonical owner, deploy, then verify HTTP 200 and rendered source before claiming publication | Proposed |
| G-006 — security and operations evidence absent | No threat model, SLO, runbook, incident, backup, or rollback drill is present | Define trust boundaries, abuse cases, telemetry, operator actions, failure recovery, and release rollback evidence | Open |

## License and provenance boundary

No repository-level license grant or third-party inventory is present. License selection remains blocked until ownership and inbound provenance are verified; no rights are inferred from repository visibility.

## Release acceptance

A release is acceptable only when the protected owner source and immutable artifact agree on version; API/schema and conformance fixtures pass at the exact revision; security, SBOM, provenance, license, NOTICE, and third-party obligations are bound to that version; a consumer integrates through a released contract and Anti-Corruption Layer; and rollback evidence is reproducible. GitHub Pages is a separate publication claim and requires live verification.
