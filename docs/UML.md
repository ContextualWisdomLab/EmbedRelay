# EmbedRelay UML baseline

Status: pre-release target model; not as-built runtime evidence
Last reconciled: 2026-09-02

## Bounded-context component view

```mermaid
flowchart LR
    Caller[Consuming application]
    Identity[Keyverse / deployment identity authority]
    API[HTTP API / OpenAPI adapter]
    Admission[Identity admission + operation authorization]
    Continuity[Embedding Continuity core]
    Governance[Migration Governance]
    Evaluation[Adapter Fitting & Evaluation]
    Release[Release Admission]
    Provider[Embedding provider/runtime ACL]
    Store[Vector-store ACL]
    RankWeave[RankWeave evaluation port]
    Orchestrator[contextual-orchestrator, if model routing is required]
    Persistence[(Future evidence persistence)]

    Caller --> API
    API --> Admission
    Admission --> Identity
    Admission --> Continuity
    Continuity --> Provider
    Continuity --> Governance
    Governance --> Evaluation
    Evaluation --> RankWeave
    Governance --> Release
    Release --> Store
    Governance --> Persistence
    Evaluation --> Persistence
    API -. only if LLM/provider routing is required .-> Orchestrator
```

The arrows show target dependency direction, not current deployed services. The domain does not depend on provider SDKs, vector-store implementations, Keyverse internals, RankWeave internals, or contextual-orchestrator persistence.

## Conversion sequence

```mermaid
sequenceDiagram
    participant C as Caller
    participant A as API/Admission
    participant I as Identity authority
    participant E as Embedding Continuity
    participant P as Provider/adapter ACL
    participant G as Migration Governance

    C->>A: conversion request + bearer + source/target IDs
    A->>I: verify issuer/audience/time/tenant/actor
    I-->>A: verified identity evidence
    A->>A: authorize operation
    alt invalid identity or denied/unavailable authorization
        A-->>C: stable fail-closed error
    else admitted
        A->>E: verified tenant/actor + bounded request
        E->>E: validate source vector and space compatibility
        alt unsupported / OOD / insufficient evidence
            E-->>C: abstained/error receipt
        else conversion allowed
            E->>P: directional adapter revision + vector
            P-->>E: converted vector + adapter evidence
            E->>G: bind conversion to policy/release context
            G-->>E: governed receipt context
            E-->>C: converted receipt, origin=translated
        end
    end
```

## Migration-release state model

```mermaid
stateDiagram-v2
    [*] --> Candidate
    Candidate --> Evaluating: immutable adapter/policy/evidence identities pinned
    Evaluating --> Hold: evidence incomplete / uncertainty / OOD gate not satisfied
    Evaluating --> Reject: policy violation or failed acceptance evidence
    Evaluating --> Approved: all versioned evidence gates satisfied
    Hold --> Evaluating: new evidence revision
    Approved --> Released: exact-head artifact admission + governance
    Released --> Superseded: newer admitted release
    Released --> RolledBack: rollback gate invoked
    Superseded --> [*]
    RolledBack --> [*]
    Reject --> [*]
```

No transition is authorized by narrative text alone. Thresholds and decision inputs belong to immutable versioned policy/evaluation evidence.

## Domain type sketch

```mermaid
classDiagram
    class EmbeddingSpaceIdentity {
      +identity_version
      +stable_space_id
      +model_identity
      +dimension
      +precision
      +metric
      +normalization
      +preprocessing_identity
      +role_identity
    }

    class DirectionalAdapterRevision {
      +adapter_revision_id
      +source_space_id
      +target_space_id
      +artifact_digest
    }

    class ConversionReceipt {
      +conversion_receipt_id
      +status
      +source_space_id
      +target_space_id
      +adapter_revision_id
      +vector_origin
      +abstention_reason
      +error_code
    }

    class MigrationPolicyRevision {
      +migration_policy_revision_id
      +threshold_provenance
      +ood_method_revision
      +acceptance_method_revision
    }

    class MigrationEvaluationRun {
      +migration_evaluation_run_id
      +fit_dataset_id
      +calibration_dataset_id
      +evaluation_dataset_id
      +failure_denominator
      +result_digest
    }

    class MigrationRelease {
      +release_artifact_id
      +decision
      +supersedes_release_id
    }

    EmbeddingSpaceIdentity "1" --> "*" DirectionalAdapterRevision : source/target
    DirectionalAdapterRevision "1" --> "*" ConversionReceipt : produces evidence
    MigrationPolicyRevision "1" --> "*" MigrationEvaluationRun : evaluates under
    DirectionalAdapterRevision "1" --> "*" MigrationEvaluationRun : evaluated
    MigrationEvaluationRun "1..*" --> "0..1" MigrationRelease : admits
```

These types are target ubiquitous-language constructs. Their presence in this document does not claim that corresponding Rust structs or database rows exist on the current branch.
