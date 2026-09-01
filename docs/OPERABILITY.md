# EmbedRelay operability baseline

Status: pre-release target; no operated-service claim  
Last reconciled: 2026-09-02

## Current state

The current documentation branch does not ship a network service, production database, container image, package or deployment. The requirements below become executable gates only as those runtime surfaces are introduced.

## Service lifecycle

A future service must provide:

- explicit startup configuration validation;
- health and readiness separation;
- graceful shutdown with bounded in-flight work;
- cancellation/timeout propagation;
- bounded worker queues for migration/evaluation jobs;
- async job APIs for expensive work rather than holding a synchronous request indefinitely;
- explicit connection lifecycle behavior that does not assume `close_connection` exists only as an instance attribute;
- deterministic correlation identifiers and structured outcome/error telemetry without leaking vectors or credentials by default.

## Deployment

Prefer a compose-compatible service definition that works with Docker, Podman or Colima and preserves a straightforward Kubernetes migration path. Do not make Kubernetes a requirement for local verification.

If native CPU/GPU modules need isolation, expose them through a versioned service/port boundary rather than embedding host-specific assumptions throughout the domain.

CPU, CUDA, OpenCL and MLX support is capability-driven. Every enabled accelerator path reports the selected backend and has deterministic CPU parity evidence for supported operations. Unsupported accelerators fail or fall back according to an explicit contract; no silent precision/semantic change is allowed.

## Database and storage, when introduced

- Configure PostgreSQL/application pools from measured hardware/workload constraints rather than fixed folklore constants.
- Tune container shared memory and database memory only from detected/declared resources and record the applied values.
- Measure lock contention, hot keys/partitions and queue depth before partitioning or read/write separation.
- Backup/recovery evidence must restore immutable identities, migration/release receipts and tenant-isolation invariants.
- Logical backup alone is not advertised as PITR/HA. WAL/PITR/failover require separate implemented evidence and measured RPO/RTO.
- Migration rollback/reapply and compatibility/supersession semantics are part of release acceptance once durable state exists.

## Observability

Telemetry should cover:

- request/job counts and outcomes by stable operation code;
- latency and queue time separated for synchronous and asynchronous work;
- abstention/error reason codes;
- provider/vector-store dependency availability without logging credentials or unbounded provider payloads;
- conversion/evaluation policy and release revision identities;
- tenant-safe audit events using opaque actor references;
- resource/worker saturation and accelerator backend selection.

Logs must not emit raw bearer tokens, provider API keys, private vector bodies, or customer dataset contents by default.

## Performance

For synchronous web/API surfaces, the commercialization target is p95 <=20 ms only where the endpoint's defined work can realistically fit that budget. Measure with k6 on realistic hardware, data size, authentication and dependency behavior. Do not report an in-memory unit benchmark as E2E latency.

Numerically expensive migration fitting/evaluation/backfill is asynchronous. Its readiness criteria are correctness, throughput/capacity, bounded resource use, resumability and recovery rather than falsely forcing the 20 ms synchronous target.

## Failure and recovery

- Identity/authorization unavailable => fail closed before tenant work.
- Unsupported/OOD/insufficient conversion evidence => abstain or fail according to the versioned contract.
- Provider/vector-store unavailable => bounded retry/backoff only when idempotency permits; otherwise return/record a stable failure.
- Worker/process crash => completed immutable receipts remain authoritative; partial jobs are resumable or safely abandoned without promoting partial output.
- Release regression => explicit rollback/supersession returns consumers to the last admitted release without rewriting historical evidence.

## Release operations

A deployable release requires immutable version/artifact identity, changelog, exact-head tests/security/reviews, SBOM/provenance, configuration schema, rollback instructions and recovery evidence appropriate to its stateful surfaces. Public distribution assumes no embedded secret and retains third-party license/attribution obligations.
