# EmbedRelay Data Model and ERD

**Status:** Accepted conceptual target model. Current PR #1 persists none of these tables yet.  
**Last reviewed:** 2026-08-15

The model distinguishes **as-built Rust domain objects** from **planned PostgreSQL persistence**. All persistent object names use descriptive two-or-more-word `snake_case` names.

## Current in-memory domain model

```mermaid
classDiagram
    class RelayIdentifier {
      +UUIDv7 value
    }
    class EmbeddingSpaceManifest {
      +model/revision
      +input_role
      +preprocessing
      +normalization
      +dimension
      +precision
      +metric
      +canonical_fingerprint()
    }
    class ValidatedVector {
      +embedding_space_fingerprint
      +float32 components
    }
    class TenantSpaceRegistry {
      +register(tenant_id, space)
      +lookup(...)
    }
    class AuditSink {
      <<port>>
      +accept(space_registration_intent)
    }

    RelayIdentifier --> TenantSpaceRegistry : tenant identifier
    EmbeddingSpaceManifest --> TenantSpaceRegistry : registered space
    EmbeddingSpaceManifest --> ValidatedVector : validates against
    TenantSpaceRegistry --> AuditSink : audit before visibility
```

## Planned PostgreSQL control-plane ERD

```mermaid
erDiagram
    TENANT_RECORD ||--o{ EMBEDDING_SPACE : owns
    EMBEDDING_SPACE ||--o{ VECTOR_REFERENCE : classifies
    EMBEDDING_SPACE ||--o{ ADAPTER_ARTIFACT : source_space
    EMBEDDING_SPACE ||--o{ ADAPTER_ARTIFACT : target_space
    ADAPTER_ARTIFACT ||--o{ ADAPTER_EVALUATION : evaluated_by
    ADAPTER_ARTIFACT ||--o{ MIGRATION_PLAN : uses
    MIGRATION_PLAN ||--o{ MIGRATION_STAGE : contains
    MIGRATION_PLAN ||--o{ INDEX_BINDING : routes
    MIGRATION_PLAN ||--o{ BACKFILL_TASK : schedules
    MIGRATION_PLAN ||--o{ MIGRATION_EVENT : emits
    TENANT_RECORD ||--o{ AUDIT_EVENT : owns
    ADAPTER_ARTIFACT ||--o{ AUDIT_EVENT : references
    MIGRATION_PLAN ||--o{ AUDIT_EVENT : references
    EMBEDDING_SPACE ||--o{ SPACE_DRIFT_EVENT : observed_for

    TENANT_RECORD {
      uuid tenant_record_id PK
      text tenant_status_code
      timestamptz created_at
    }

    EMBEDDING_SPACE {
      uuid embedding_space_id PK
      uuid tenant_record_id FK
      text canonical_fingerprint
      jsonb canonical_manifest
      text input_role_code
      integer vector_dimension
      text scalar_precision_code
      text metric_code
      text lifecycle_status_code
      timestamptz created_at
      unique tenant_record_id_canonical_fingerprint "tenant_record_id, canonical_fingerprint"
    }

    VECTOR_REFERENCE {
      uuid vector_reference_id PK
      uuid tenant_record_id FK
      uuid embedding_space_id FK
      text external_collection_id
      text external_vector_id
      text vector_origin_code
      text source_content_hash
      timestamptz created_at
    }

    ADAPTER_ARTIFACT {
      uuid adapter_artifact_id PK
      uuid tenant_record_id FK
      uuid source_space_id FK
      uuid target_space_id FK
      text input_role_code
      text algorithm_code
      text algorithm_version
      text artifact_digest_sha256
      text artifact_signature_ref
      text lifecycle_status_code
      text confidence_policy_version
      timestamptz created_at
    }

    ADAPTER_EVALUATION {
      uuid adapter_evaluation_id PK
      uuid adapter_artifact_id FK
      text evaluation_dataset_hash
      jsonb vector_metrics
      jsonb retrieval_metrics
      jsonb calibration_metrics
      jsonb slice_metrics
      text acceptance_status_code
      timestamptz evaluated_at
    }

    MIGRATION_PLAN {
      uuid migration_plan_id PK
      uuid tenant_record_id FK
      uuid source_space_id FK
      uuid target_space_id FK
      uuid adapter_artifact_id FK
      text migration_status_code
      text rollback_policy_version
      timestamptz created_at
    }

    MIGRATION_STAGE {
      uuid migration_stage_id PK
      uuid migration_plan_id FK
      text stage_type_code
      numeric target_traffic_fraction
      text stage_status_code
      timestamptz started_at
      timestamptz completed_at
    }

    INDEX_BINDING {
      uuid index_binding_id PK
      uuid migration_plan_id FK
      text index_role_code
      text provider_code
      text external_index_id
      uuid embedding_space_id FK
      text binding_status_code
    }

    BACKFILL_TASK {
      uuid backfill_task_id PK
      uuid migration_plan_id FK
      text source_record_ref
      text priority_reason_code
      text task_status_code
      integer attempt_count
      timestamptz created_at
    }

    MIGRATION_EVENT {
      uuid migration_event_id PK
      uuid migration_plan_id FK
      text event_type_code
      jsonb bounded_event_data
      timestamptz occurred_at
    }

    AUDIT_EVENT {
      uuid audit_event_id PK
      uuid tenant_record_id FK
      uuid actor_identity_id
      text action_code
      text resource_type_code
      uuid resource_record_id
      text outcome_code
      text evidence_digest
      timestamptz occurred_at
    }

    SPACE_DRIFT_EVENT {
      uuid space_drift_event_id PK
      uuid embedding_space_id FK
      text observed_fingerprint
      text drift_reason_code
      jsonb bounded_metrics
      timestamptz observed_at
    }
```

## Persistence invariants

- Every operational record is tenant-bound either directly or through a transactionally constrained parent.
- UUIDv7 is an opaque identifier shape, not authorization or business chronology.
- `(tenant_record_id, canonical_fingerprint)` is unique; the same canonical fingerprint may exist independently for different tenants.
- `canonical_fingerprint` cannot be mutated after dependent vectors/adapters/migrations exist; drift creates a new/quarantined space.
- A production adapter is immutable after approval; a changed artifact creates a new `adapter_artifact_id`.
- Audit events are append-only under the durable design.
- Adapter direction is explicit through separate `source_space_id` and `target_space_id`; reverse direction is another artifact.
- `vector_origin_code` distinguishes native/translated/reconstructed/composed states.
- Cross-space raw metric computation is forbidden by application/domain constraints even if dimensions match.

## RLS and authorization target

PostgreSQL RLS is planned for tenant-scoped control-plane tables, but it is **not implemented** in the current PR. The durable migration PR must prove forced RLS, service-role policy, cross-tenant negative tests, transaction isolation, and admin/audit access boundaries before this document labels RLS as as-built.

## Lineage view

```mermaid
flowchart LR
    SOURCE[Source content/model input]
    NATIVE[Native vector]
    SPACE[Embedding space]
    ADAPTER[Directional adapter]
    TRANS[Translated vector]
    EVAL[Evaluation evidence]
    MIG[Migration plan]

    SOURCE --> NATIVE
    NATIVE --> SPACE
    SPACE --> ADAPTER
    ADAPTER --> TRANS
    ADAPTER --> EVAL
    EVAL --> MIG
    TRANS --> MIG
```

Every translated result must be traceable to source space, target space, adapter artifact, evaluation/confidence policy, and source vector/content identity where policy allows.

## Migration acceptance

Before these conceptual entities become persisted tables, the implementing PR must include migrations/rollback, RLS/tenant tests, unique/foreign/check constraints, indexes/capacity rationale, audit immutability, transaction/idempotency/concurrency tests, backup/recovery impact, and synchronized API/security/operability/ADR documentation.
