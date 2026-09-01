# EmbedRelay Security Contract

**Status:** Accepted target security baseline; active-PR M1 implementation maturity is explicit.  
**Last reviewed:** 2026-09-02

## Security objective

Prevent incompatible-space corruption, cross-tenant access, poisoned or substituted adapter artifacts, sensitive-vector disclosure, provider drift, and unreviewed migration cutover while keeping provenance sufficient for rollback and audit.

## Sensitive assets

- embedding vectors and query logs;
- paired anchors and source text references;
- embedding-space manifests/fingerprints;
- adapter weights and manifests;
- evaluation and calibration datasets/results;
- migration plans, routing/index bindings, backfill queues;
- tenant/actor policy and audit records;
- provider/vector-store credentials and artifact-signing keys.

None are assumed anonymous merely because they are vectors.

## Core controls

- tenant identity and authorization are explicit inputs;
- UUIDv7 timestamps, vector contents, provider model names, and fingerprints never establish authority;
- cross-space metric operations fail closed unless complete space identity matches;
- adapter artifacts are immutable/digest-bound after promotion;
- training/evaluation provenance and policy version are retained;
- vectors/anchors/artifacts are encrypted and export-controlled according to data classification;
- ordinary logs exclude raw vectors, source text, secrets, and unbounded provider responses;
- provider responses are dimension/space validated before persistence or routing;
- provider output drift quarantines/registers a new space rather than mutating compatibility identity;
- production translation can abstain and fall back rather than forcing unsafe output;
- source indices remain available through the defined rollback window.

## Current tenant and PostgreSQL M1 boundary

PR #1 now carries a narrow active-PR PostgreSQL security boundary in addition to the Rust reference registry. It is not protected-main or release evidence until its current exact head passes hosted PostgreSQL/security/review gates.

Current physical controls:

- `tenant_space_registry` and `space_registration_audit` are tenant-scoped relations under `embedrelay_registry`;
- both relations enable and **force** RLS;
- policy expressions require an explicit `embedrelay.tenant_id` session context and apply both `USING` and `WITH CHECK` tenant equality;
- the contract exercises access under a non-superuser, non-`BYPASSRLS` role;
- missing tenant context fails closed;
- cross-tenant insertion is denied and a different tenant sees zero rows;
- public/default table/function privileges are revoked by migration and service access must be granted explicitly;
- both registry and audit relations reject ordinary `UPDATE`, `DELETE`, and `TRUNCATE` operations;
- duplicate/concurrent same-tenant registration is unique-key rejected so the losing transaction cannot leave a second audit intent;
- destructive schema rollback is unavailable unless the operator explicitly sets `embedrelay.allow_destructive_rollback=on`.

This is deliberately not an UPSERT surface. A future idempotent network API must use a stable request/idempotency key rather than silently interpreting a conflicting domain fact as success.

## Remaining persistence-security requirements

The M1 persistence implementation still must prove or add:

- current exact-head PostgreSQL 18.6 RLS/concurrency/rollback results after every source/doc change;
- complete immutable canonical-manifest persistence rather than fingerprint-only registration;
- measured backup/restore acceptance without cross-tenant mixing;
- bounded production service/admin/audit roles and privileged-access evidence;
- encryption/KMS boundaries for persistence and artifact storage where required;
- retention, deletion/export, residency, and incident-evidence responsibilities;
- recovery procedures that preserve RLS, append-only triggers, constraints, functions, and policy state.

Broader adapter, migration, vector-reference, and provider persistence requires its own tenant and threat tests when introduced.

## Anchor/adapter supply-chain security

Anchor selection and adapter training are in threat scope for poisoning and substitution. Release artifacts require exact source/target spaces, role, dataset/evidence hashes, algorithm/toolchain version, artifact digest/signature, evaluation result, and approver/policy provenance.

No LLM judgment alone can promote an adapter or authorize a migration cutover.

## Privacy

Do not default to blanket masking that destroys embedding/retrieval semantics. Prefer purpose-bound authorization, selective disclosure, encryption, opaque references, bounded retention, controlled export, tenant/service identity, and auditable access. Native source text need not be retained by EmbedRelay if a secure external reference/hash can support authorized backfill/provenance.

The current M1 registry persists identifiers/fingerprints and audit metadata, not raw production vectors. That narrower surface does not eliminate privacy obligations for the future assets listed above.

## Secrets

Provider/vector-store/KMS credentials live only in edge adapters or secret managers and are never embedded in adapter artifacts, vector metadata, logs, or model prompts. GitHub autonomous-development agents use approved secret-backed tooling and never introduce `COPILOT_GITHUB_TOKEN` as a workflow dependency.

## Compliance direction

Current forced-RLS, explicit-privilege, append-only, deterministic-concurrency, and exact-head evidence contracts are consistent with designing toward auditable CSAP and SOC 2 controls. They are **not** a certification claim. Certification/compliance evidence requires the broader organizational, operational, monitoring, incident, access-review, encryption, retention, and recovery controls that are outside this M1 slice.

## Release security gate

Required exact-head SAST/security/coverage/PostgreSQL/review/provenance results must be passing. Failed, queued, skipped-required, cancelled, absent, stale-head, synthetic-only, or rate-limited evidence is not acceptance. The central dependency-review availability incident tracked by `ContextualWisdomLab/.github#810` must be resolved or otherwise produce policy-valid fail-closed evidence; it may not be bypassed or replaced by an unrelated scanner merely to merge.
