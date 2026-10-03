# Tenant registry audit-before-mutation boundary

## Decision

EmbedRelay's tenant registry key is the pair `(tenant_id, canonical_space_fingerprint)`. The same canonical embedding space may therefore exist independently in multiple tenants, while duplicate registration of the same fingerprint inside one tenant fails closed.

Every accepted registration must cross an audit boundary **before** the new registry entry becomes observable. The Rust reference contract emits a `space_registration_intent` containing an opaque event identifier, explicit tenant identifier, explicit actor identifier, and the complete canonical embedding-space fingerprint. If the audit recorder rejects the intent, the registry remains unchanged.

The pre-mutation event is deliberately named an **intent**, not a success event. A recorder can durably accept evidence before mutation without falsely claiming that a later storage mutation completed. A durable persistence adapter must bind the accepted intent and the registry mutation in one database transaction and, when an operator needs an outcome trail distinct from transaction commit evidence, append a separate outcome record rather than reinterpret the intent.

## Product and acquisition boundary

A buyer must be able to prove that model-space registration cannot silently cross tenant boundaries or create unaudited state. The reference contract therefore makes four guarantees explicit:

1. tenant identity is part of the registry key rather than an ambient process assumption;
2. the complete canonical space fingerprint, not vector dimension or model name alone, identifies the registered space;
3. duplicate same-tenant registration is rejected before another audit record is emitted; and
4. audit rejection prevents registry mutation.

This slice is intentionally storage-independent so standalone callers and future CWL services can share one Rust domain contract without hidden coupling to a database, naruon, contextual-orchestrator, or the organization control plane.

## Durable PostgreSQL boundary

The current slice does **not** create a database schema. The later PostgreSQL adapter must preserve the Rust ordering and isolation contract rather than weaken it.

The current PostgreSQL 18 documentation specifies that enabling Row-Level Security (RLS) makes normal row access policy-controlled and default-deny when no applicable policy exists. Table owners normally bypass RLS unless `FORCE ROW LEVEL SECURITY` is enabled, and roles with `BYPASSRLS` always bypass it. Accordingly, the production adapter acceptance contract is:

- use descriptive relation names such as `tenant_space_registry` and `space_audit_event`;
- keep the application role distinct from the table owner and do not grant it `BYPASSRLS`;
- enable and force RLS on tenant-bearing relations;
- use explicit tenant predicates for both `USING` and `WITH CHECK` behavior so reads and mutations are tenant-scoped;
- make audit history append-only for the application role;
- write the audit intent and registry mutation in one transaction, with uniqueness enforced over the tenant identifier plus canonical space fingerprint;
- treat backup, restore, migration, break-glass administration, and referential-integrity behavior as explicit privileged paths rather than assuming RLS covers them; and
- test rollback and tenant-isolation behavior against the exact supported PostgreSQL minor release before release acceptance.

As of this doctoring decision, PostgreSQL 18.4 was released on May 14, 2026. The PostgreSQL project states that an 18.x-to-18.4 upgrade does not require dump/restore. This version reference is an implementation baseline, not permission to ship a database adapter without its own migration, rollback, security, and exact-head evidence.

## Audit evidence boundary

NIST SP 800-53 Rev. 5's Audit and Accountability family provides a useful control vocabulary for the later durable audit implementation, including event selection and audit-record content. NIST finalized minor Release 5.2.0 on August 27, 2025 and updated related-control mappings that include AU-02 and AU-03.

The Rust domain event intentionally contains only stable identity material needed at this boundary: event ID, tenant ID, actor ID, action code, and canonical space fingerprint. The durable adapter must add authoritative event time, execution outcome where applicable, source/session provenance, and other locally required audit fields. UUIDv7 timestamp bits are never a substitute for an authoritative audit timestamp, business chronology, authorization decision, or tenant membership.

## Concurrency and atomicity

The in-memory `TenantSpaceRegistry` is a deterministic reference contract, not a concurrent persistence engine. It proves ordering inside one mutable registry instance: duplicate check, accepted audit intent, then state visibility. It does not claim process-wide or distributed serializability.

A durable adapter must use database transaction semantics and a tenant-plus-fingerprint uniqueness constraint to close races between concurrent writers. If two transactions attempt the same tenant registration, at most one may commit the new registry row. The losing path must not claim a successful registration. The append-only audit design must distinguish attempted intent from committed outcome so concurrent failure remains forensically interpretable.

## Security and privacy boundary

- Tenant and actor identifiers are explicit opaque UUIDv7 values; no authorization is inferred from UUID timestamp bits.
- The canonical fingerprint identifies embedding-space configuration material, not customer vector contents.
- The domain error surface is stable and non-reflecting; it does not echo tenant-controlled payloads.
- Audit acceptance is fail-closed. Failure cannot be converted into an unaudited mutation.
- Cross-tenant equality of an embedding-space fingerprint does not create cross-tenant registry visibility.
- Database privileges, RLS, retention, deletion policy, encryption, backup handling, and incident-access policy remain mandatory independent controls in the durable adapter.

## TDD evidence

The fail-first commit `aba20e43ba63b54a2ead6b809fb8ffe10f25e574` introduced the tenant-registry integration contract before any registry implementation existed. Exact-head CI run `31242243987`, job `93065044830`, failed in `cargo test --workspace` with Rust `E0432` unresolved imports for the intentionally absent registry and audit types. That failure proves the test did not pass against predecessor production code.

Commit `58c5111b2827d8ffe4f3d7e37c622f7b1a6bf0d6` then made the event semantics explicit by requiring the pre-mutation action code `space_registration_intent`. Production implementation followed in `7c1a1fd42086caf7517024f3ceb025d016228596`, with public export wiring in `0973fc0b56611d5d56851f6a517388d962ab9edc`.

On exact head `0973fc0b56611d5d56851f6a517388d962ab9edc`, CI run `31242335957` passed stable workspace tests and the repository's exact LLVM line, region, function, and branch coverage gate. Security Scan `31242335948` and SAST Semgrep `31242335947` also passed. These are predecessor-head evidence after this documentation commit and must not be reused as the final merge gate; every subsequent head must regenerate its own evidence.

## Rollback

This slice introduces no persisted production schema or customer data. Rollback before a durable adapter ships is a code-only revert of the registry module, tests, exports, documentation, README, and changelog entry.

After a database adapter exists, rollback must preserve already issued identifiers and audit evidence. A migration may disable a new write path only through an explicitly tested rollback procedure; it must not delete or rewrite audit history merely to restore older application behavior.

## Acceptance criteria

1. A registration accepted by the audit recorder becomes visible only after the recorder returns success.
2. Audit rejection returns a stable error and leaves registry state unchanged.
3. Duplicate registration of one fingerprint inside one tenant fails without emitting another audit intent.
4. The same fingerprint can be registered independently in distinct tenants without cross-tenant visibility.
5. Public Rust APIs remain documented and production code retains exact 100% line, region, function, and branch coverage.
6. Future PostgreSQL persistence preserves tenant isolation, audit-before-mutation ordering, transactional uniqueness, append-only audit semantics, migration/rollback evidence, and forced RLS for the application access path.
7. No UUID timestamp field is treated as authorization, tenant membership, provenance, or authoritative business/audit chronology.

## References

Davis, K., Peabody, B. G., & Leach, P. J. (2024). *Universally Unique IDentifiers (UUIDs)* (RFC 9562). RFC Editor. https://doi.org/10.17487/RFC9562

Joint Task Force. (2020). *Security and privacy controls for information systems and organizations* (NIST Special Publication 800-53 Rev. 5). National Institute of Standards and Technology. https://doi.org/10.6028/NIST.SP.800-53r5

PostgreSQL Global Development Group. (2026, May 14). *PostgreSQL 18.4 release notes*. https://www.postgresql.org/docs/release/18.4/

PostgreSQL Global Development Group. (n.d.). *Row security policies (PostgreSQL 18 documentation)*. Retrieved August 8, 2026, from https://www.postgresql.org/docs/18/ddl-rowsecurity.html
