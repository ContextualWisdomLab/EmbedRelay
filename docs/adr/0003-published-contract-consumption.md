# ADR 0003: Published-contract consumption and MSA 따로 또 같이

Status: Proposed

## Context

CWL MSA policy is **따로 또 같이**: a leaf product must remain independently deployable and callable by a composition hub once an executable release exists. Naruon and gyeot are allowed composition hubs. A host that must clone EmbedRelay beside its own tree, or that reads EmbedRelay's private persistence, has collapsed the leaf into a hidden monorepo.

The OpenAPI Specification exists so a consumer can understand an HTTP service without the service's source, extra narrative, or packet inspection (OpenAPI Initiative, 2025). RFC 8259 defines interoperable UTF-8 JSON as the common wire representation (Bray, 2017). Semantic Versioning 2.0.0 requires a declared public API and forbids mutating a released version in place (Preston-Werner, 2013). ISO/IEC/IEEE 42010:2022 treats the architecture description as a first-class artifact distinct from the running system (International Organization for Standardization, International Electrotechnical Commission, & Institute of Electrical and Electronics Engineers, 2022). NIST AI RMF 1.0 asks that accountability and measurement boundaries be explicit before integration (National Institute of Standards and Technology, 2023).

## Decision

### Release contract

1. Every executable release that exposes HTTP publishes an immutable, versioned **OpenAPI document** for paths, methods, status codes, content types, and security schemes. JSON Schema may supplement payload definitions but cannot substitute for the HTTP contract.
2. A host consumes release/tagged contract artifacts; it does not require a sibling checkout and does not copy EmbedRelay internals.
3. Naruon and gyeot may compose EmbedRelay by pinning released contracts in their own repositories. Wiring belongs in the hub's pull request, not a shared working tree.
4. Contract versions follow Semantic Versioning 2.0.0. Breaking space-identity, authorization, result-status, vector-precision, or abstention semantics require a new major version and migration notes.
5. A released contract artifact is immutable. A corrected artifact is a new release/version, never an in-place replacement.

The current documentation-only branch has no live HTTP surface and therefore does not fabricate an endpoint or an OpenAPI file. It defines the required release contract before implementation. The first executable HTTP release is incomplete until its OpenAPI artifact exists and is validated against implementation tests.

### Machine-readable conversion outcome

The public conversion response is a tagged union. Its first executable schema must preserve these required semantics:

| Status | Required contract |
| --- | --- |
| `converted` | `schema_version`, `request_id`, `status`, exact `source_space_id`, exact `target_space_id`, `vector_origin=translated`, immutable `adapter_artifact` identity/digest, `policy_id`, `decision_receipt_id`, and validated result vector |
| `abstained` | `schema_version`, `request_id`, `status`, exact source/target space IDs, no translated vector, and a typed abstention reason |
| `error` | `schema_version`, `request_id`, `status`, stable error code, bounded safe message, and no translated vector |

The initial abstention vocabulary is `low_confidence`, `out_of_distribution`, `policy_hold`, `incompatible_space`, and `no_approved_adapter`. The initial error vocabulary is `invalid_request`, `unauthenticated`, `forbidden`, `space_not_found`, `adapter_not_found`, `policy_not_approved`, and `internal_error`. A client must branch on `status` and the typed code; it must never reinterpret abstention as a zero vector, success, or same-space comparison.

Required fields cannot be removed in a minor version. Existing enum meanings cannot be repurposed. Because the current response objects are closed with `additionalProperties: false`, adding any field to those objects—including an optional field—is a major change. A future minor version may add optional fields only inside an explicitly documented extension object that the already-released schema permits. Removing a field, adding a required field, or changing the meaning of an existing status/code is major. The release OpenAPI/JSON Schema is machine authority; this table is the pre-release design constraint.

### Trusted tenant and actor handoff

Tenant isolation and actor identity are not trusted because a host wrote arbitrary headers or JSON fields. In an executable deployment:

1. The caller presents a bearer credential issued by a deployment-approved OIDC authority. The ContextualWisdomLab deployment profile uses the ecosystem identity authority (Keyverse) rather than embedding identity-provider administration in EmbedRelay.
2. EmbedRelay validates the token itself, or through an explicitly versioned local verification port: signature against the configured issuer/JWKS trust root, exact issuer, deployment-pinned service audience, expiration/not-before semantics, and required tenant and subject/actor claims. Validation failure is `401 unauthenticated` and processing stops before vector or adapter work.
3. Authorization policy evaluates the **verified** tenant and actor against the requested source/target spaces and adapter operation. A valid identity lacking permission is `403 forbidden`.
4. Tenant/actor values supplied in an application payload are identifiers to compare with verified claims, never alternative authentication evidence. A mismatch fails closed.
5. EmbedRelay does not accept a sibling product database, ambient provider credential, or unsigned host assertion as identity authority. Hosts retain their own sessions and persistence; EmbedRelay retains authorization enforcement for operations performed inside its service boundary.
6. Logs, traces, decision receipts, and errors may retain bounded non-secret identifiers needed for audit, but must not expose bearer tokens or embedding content by default.

This split keeps Keyverse/another approved issuer as identity authority, the caller as credential presenter, and EmbedRelay as verifier/enforcer of its own service operation. All hosts therefore consume the same trust contract instead of inventing per-host tenant headers.

### Product ownership

Space identity, vector validation, adapter eligibility, migration-policy decision state, and abstention remain EmbedRelay responsibilities. Ranking/fusion remains RankWeave; LLM/provider routing remains contextual-orchestrator; host application state remains the host's responsibility. No cross-service application-table SQL is an integration mechanism.

## Consequences

- EmbedRelay can be deployed and called without naruon, gyeot, RankWeave, or contextual-orchestrator source once an executable release exists.
- HTTP consumers always receive an OpenAPI authority; JSON Schema alone cannot masquerade as an HTTP API description.
- Conversion, abstention, and error outcomes have stable machine semantics before clients are implemented.
- Tenant and actor trust is verified at the service boundary rather than delegated to arbitrary caller headers.
- Hubs cannot drift onto an unpublished in-tree function signature.
- Missing executable artifacts on the documentation-only branch remain an honest pre-release state, not a license to invent endpoints or require sibling checkouts.

## References

Bray, T. (Ed.). (2017). *The JavaScript Object Notation (JSON) data interchange format* (RFC 8259). Internet Engineering Task Force. https://doi.org/10.17487/RFC8259

International Organization for Standardization, International Electrotechnical Commission, & Institute of Electrical and Electronics Engineers. (2022). *Software, systems and enterprise — Architecture description* (ISO/IEC/IEEE 42010:2022). https://www.iso.org/standard/74393.html

National Institute of Standards and Technology. (2023). *Artificial intelligence risk management framework (AI RMF 1.0)* (NIST AI 100-1). U.S. Department of Commerce. https://doi.org/10.6028/NIST.AI.100-1

OpenAPI Initiative. (2025, September 19). *OpenAPI Specification v3.1.2*. https://spec.openapis.org/oas/v3.1.2.html

Preston-Werner, T. (2013). *Semantic Versioning 2.0.0*. https://semver.org/spec/v2.0.0.html
