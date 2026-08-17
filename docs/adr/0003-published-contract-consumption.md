# ADR 0003: Published-contract consumption and MSA 따로 또 같이

Status: Proposed

## Context

CWL MSA policy is **따로 또 같이**: a leaf product must run independently
and remain callable by a composition hub. Naruon and gyeot are the allowed
hubs. A host that must clone EmbedRelay beside its own tree, or that reads
EmbedRelay's private database, has collapsed the leaf into a hidden monorepo.

The OpenAPI Specification exists so a consumer can understand a remote service
without the service's source, extra narrative, or packet inspection (OpenAPI
Initiative, n.d.). RFC 8259 defines interoperable UTF-8 JSON as the common
wire representation (Bray, 2017). Semantic Versioning 2.0.0 requires a
declared public API and forbids mutating a released version in place
(Preston-Werner, 2013). ISO/IEC/IEEE 42010:2022 treats the architecture
description as a first-class artifact distinct from the running system
(International Organization for Standardization, International
Electrotechnical Commission, & Institute of Electrical and Electronics
Engineers, 2022). NIST AI RMF 1.0 asks that accountability and measurement
boundaries be explicit before integration (National Institute of Standards
and Technology, 2023).

## Decision

1. EmbedRelay publishes a versioned machine-readable contract (OpenAPI and/or
   JSON Schema) with each executable release. The contract is the supported
   host integration surface.
2. A host consumes that artifact from a release, tag, or documented contract
   path. It does not check out this repository as a sibling of the host, and
   it does not copy EmbedRelay internals.
3. Naruon and gyeot may compose EmbedRelay by pinning the published contract
   in their own repositories. Wiring belongs in the hub's pull request, not
   in a shared working tree.
4. Contract versions follow Semantic Versioning 2.0.0. A released contract
   document is immutable. Breaking space-identity, vector-precision, or
   abstention semantics require a new major version and migration notes.
5. Transport authorization, tenant identity, and host persistence stay in the
   host. Space identity, vector validation, adapter eligibility, and
   abstention stay in EmbedRelay.
6. Until a release publishes OpenAPI or JSON Schema files, this ADR and the
   root README are the consumption rule. Hosts must not invent a package
   coordinate or scrape another CWL product for a substitute API.

## Consequences

- EmbedRelay can be deployed and called without naruon, gyeot, RankWeave, or
  contextual-orchestrator source.
- Hubs cannot drift onto an unpublished in-tree function signature.
- Contract consumers can validate JSON independently of EmbedRelay's
  implementation language.
- Missing machine-readable files on a documentation-only branch are an
  honest pre-release state, not a license to require sibling checkouts.
- Absorbing EmbedRelay into a hub repository, or requiring a monorepo
  checkout to call it, violates this ADR.

## References

Bray, T. (Ed.). (2017). *The JavaScript Object Notation (JSON) data
interchange format* (RFC 8259). Internet Engineering Task Force.
https://doi.org/10.17487/RFC8259

International Organization for Standardization, International
Electrotechnical Commission, & Institute of Electrical and Electronics
Engineers. (2022). *Software, systems and enterprise — Architecture
description* (ISO/IEC/IEEE 42010:2022).
https://www.iso.org/standard/74393.html

National Institute of Standards and Technology. (2023). *Artificial
intelligence risk management framework (AI RMF 1.0)* (NIST AI 100-1).
U.S. Department of Commerce. https://doi.org/10.6028/NIST.AI.100-1

OpenAPI Initiative. (n.d.). *OpenAPI Specification v3.1.2*. Retrieved
August 17, 2026, from https://spec.openapis.org/oas/v3.1.2.html

Preston-Werner, T. (2013). *Semantic Versioning 2.0.0*.
https://semver.org/spec/v2.0.0.html
