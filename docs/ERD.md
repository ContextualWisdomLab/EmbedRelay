# EmbedRelay conceptual ERD

Status: future relational persistence target; **no current database is claimed**
Last reconciled: 2026-09-02

This model exists to constrain naming, tenant isolation, normalization and evidence ownership before persistence implementation. Every object name contains at least two semantic words and uses `snake_case`. The target remains third normal form; vector-store payload/index persistence stays outside this relational authority.

```mermaid
erDiagram
    tenant_partition ||--o{ embedding_space_record : owns
    tenant_partition ||--o{ adapter_revision_record : owns
    tenant_partition ||--o{ migration_policy_revision : owns
    tenant_partition ||--o{ migration_evaluation_run : owns
    tenant_partition ||--o{ conversion_receipt_record : owns
    tenant_partition ||--o{ release_admission_record : owns
    tenant_partition ||--o{ rollback_receipt_record : owns

    embedding_space_record ||--o{ adapter_revision_record : source_space
    embedding_space_record ||--o{ adapter_revision_record : target_space
    adapter_revision_record ||--o{ migration_evaluation_run : evaluates
    migration_policy_revision ||--o{ migration_evaluation_run : governs
    migration_evaluation_run ||--o| release_admission_record : supports
    adapter_revision_record ||--o{ conversion_receipt_record : produces
    release_admission_record ||--o{ rollback_receipt_record : may_rollback

    tenant_partition {
        uuid tenant_partition_id PK
        text tenant_reference UK
    }

    embedding_space_record {
        uuid embedding_space_record_id PK
        uuid tenant_partition_id FK
        text stable_space_identity
        text material_identity_digest
        int identity_version
        timestamptz recorded_at
    }

    adapter_revision_record {
        uuid adapter_revision_record_id PK
        uuid tenant_partition_id FK
        uuid source_space_record_id FK
        uuid target_space_record_id FK
        text adapter_artifact_digest
        text adapter_method_revision
        timestamptz recorded_at
    }

    migration_policy_revision {
        uuid migration_policy_revision_id PK
        uuid tenant_partition_id FK
        text policy_revision_digest
        text threshold_provenance_reference
        text ood_method_revision
        text acceptance_method_revision
        timestamptz recorded_at
    }

    migration_evaluation_run {
        uuid migration_evaluation_run_id PK
        uuid tenant_partition_id FK
        uuid adapter_revision_record_id FK
        uuid migration_policy_revision_id FK
        text fitting_dataset_identity
        text calibration_dataset_identity
        text evaluation_dataset_identity
        bigint evaluation_denominator
        bigint failure_denominator
        text result_digest
        timestamptz completed_at
    }

    conversion_receipt_record {
        uuid conversion_receipt_record_id PK
        uuid tenant_partition_id FK
        uuid adapter_revision_record_id FK
        text conversion_status
        text source_vector_reference
        text target_vector_reference
        text abstention_reason_code
        text error_reason_code
        timestamptz completed_at
    }

    release_admission_record {
        uuid release_admission_record_id PK
        uuid tenant_partition_id FK
        uuid migration_evaluation_run_id FK
        text release_artifact_identity
        text admission_decision
        text release_provenance_digest
        timestamptz admitted_at
    }

    rollback_receipt_record {
        uuid rollback_receipt_record_id PK
        uuid tenant_partition_id FK
        uuid release_admission_record_id FK
        text rollback_reason_code
        text restored_release_identity
        timestamptz completed_at
    }
```

## Normalization and authority

- `embedding_space_record` stores identity/evidence metadata, not vector bodies.
- `adapter_revision_record` references source/target spaces instead of duplicating their material fields.
- `migration_evaluation_run` references one adapter and one policy revision; dataset identities are immutable external evidence references, not copied datasets.
- `conversion_receipt_record` stores bounded evidence/reference metadata; vector bytes remain with the owning runtime/vector store unless a future approved requirement establishes a separate encrypted evidence store.
- release and rollback records are completed facts and therefore append-only after acceptance.

## Tenant isolation

Every tenant-owned relation includes `tenant_partition_id`. Foreign keys between tenant-owned objects must be composite tenant-safe references or equivalent constraints so a valid object identifier from another tenant cannot satisfy a reference. A shared PostgreSQL deployment uses forced RLS or an equivalent fail-closed policy under a `NOSUPERUSER NOBYPASSRLS` application role.

## Identity and idempotency

Stable business/evidence identities require explicit unique constraints separate from surrogate row identifiers. Item-level UPSERT semantics must define exact retry versus conflicting reuse before implementation. Concurrent insert tests must prove that duplicate races cannot create two accepted authorities.

## Partitioning and lock policy

No partitioning or read/write split is prescribed today. Measure row/index contention, hot tenant/space/adapter keys, queue depth and transaction latency first. If partitioning is justified, tenant plus high-cardinality domain identity should be evaluated from measured distribution rather than a rule of thumb.

This ERD is a target fitness constraint. Migrations and actual tables are absent until a persistence slice implements and tests them.
