# EmbedRelay Security Contract

**Status:** Accepted target security baseline; implementation maturity is explicit.  
**Last reviewed:** 2026-08-09

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

## Tenant and PostgreSQL target

Durable control-plane tables require tenant scoping and RLS/authorization tests. The current PR #1 uses only a storage-independent Rust registry, so PostgreSQL RLS and append-only audit are **planned**, not implemented security claims.

The persistence implementation must prove:

- forced tenant RLS/service-role behavior;
- cross-tenant negative tests;
- transactionally enforced uniqueness/idempotency;
- audit-before-visible-state semantics;
- immutable space/adapter records after dependent use;
- bounded privileged administrative paths;
- backup/recovery without cross-tenant mixing.

## Anchor/adapter supply-chain security

Anchor selection and adapter training are in threat scope for poisoning and substitution. Release artifacts require exact source/target spaces, role, dataset/evidence hashes, algorithm/toolchain version, artifact digest/signature, evaluation result, and approver/policy provenance.

No LLM judgment alone can promote an adapter or authorize a migration cutover.

## Privacy

Do not default to blanket masking that destroys embedding/retrieval semantics. Prefer purpose-bound authorization, selective disclosure, encryption, opaque references, bounded retention, controlled export, tenant/service identity, and auditable access. Native source text need not be retained by EmbedRelay if a secure external reference/hash can support authorized backfill/provenance.

## Secrets

Provider/vector-store/KMS credentials live only in edge adapters or secret managers and are never embedded in adapter artifacts, vector metadata, logs, or model prompts. GitHub autonomous-development agents use `NVIDIA_NIM_API_KEY` only through approved secret boundaries and never `COPILOT_GITHUB_TOKEN`.

## Release security gate

Required exact-head SAST/security/coverage/review/provenance results must be passing. Failed, queued, skipped-required, cancelled, absent, stale-head, synthetic-only, or rate-limited evidence is not acceptance.