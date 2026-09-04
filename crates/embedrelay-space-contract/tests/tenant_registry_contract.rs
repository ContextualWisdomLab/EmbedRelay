//! Regression contracts for tenant-scoped, audit-before-mutation space registration.

use embedrelay_space_contract::{
    AuditRecordError, EmbeddingSpaceManifest, RelayIdentifier, SpaceRegistrationAuditEvent,
    SpaceRegistrationAuditRecorder, TenantRegistryError, TenantSpaceRegistry,
};

const VALID_MANIFEST: &str = r#"{
  "provider_identifier":"example_provider",
  "model_identifier":"example_model",
  "model_revision":"revision_1",
  "modality_code":"text",
  "input_role_code":"document",
  "instruction_template_hash":"sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  "pooling_strategy_code":"mean_pooling",
  "normalization_strategy_code":"l2",
  "vector_dimension":16,
  "numeric_precision_code":"float32",
  "distance_metric_code":"cosine",
  "preprocessing_policy_hash":"sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
}"#;

const TENANT_A: &str = "017f22e2-79b0-7cc3-98c4-dc0c0c0c0739";
const TENANT_B: &str = "017f22e2-79b0-7cc3-98c4-dc0c0c0c073a";
const ACTOR_A: &str = "017f22e2-79b0-7cc3-98c4-dc0c0c0c073b";

#[derive(Default)]
struct RecordingAudit {
    events: Vec<SpaceRegistrationAuditEvent>,
    reject: bool,
}

impl SpaceRegistrationAuditRecorder for RecordingAudit {
    fn record_registration(
        &mut self,
        event: &SpaceRegistrationAuditEvent,
    ) -> Result<(), AuditRecordError> {
        if self.reject {
            return Err(AuditRecordError::Rejected);
        }
        self.events.push(event.clone());
        Ok(())
    }
}

fn relay_identifier(value: &str) -> RelayIdentifier {
    RelayIdentifier::parse(value).expect("fixture must be an RFC 9562 UUIDv7 identifier")
}

fn manifest() -> EmbeddingSpaceManifest {
    EmbeddingSpaceManifest::from_json(VALID_MANIFEST).expect("fixture manifest must be valid")
}

#[test]
fn registration_records_audit_before_exposing_tenant_state() {
    let tenant_id = relay_identifier(TENANT_A);
    let actor_id = relay_identifier(ACTOR_A);
    let manifest = manifest();
    let fingerprint = manifest.fingerprint().to_owned();
    let mut registry = TenantSpaceRegistry::new();
    let mut audit = RecordingAudit::default();

    let event = registry
        .register_space(tenant_id, actor_id, &manifest, &mut audit)
        .expect("registration should succeed after audit acceptance");

    assert!(registry.contains_space(tenant_id, &fingerprint));
    assert_eq!(registry.tenant_space_count(tenant_id), 1);
    assert_eq!(audit.events, vec![event.clone()]);
    assert_eq!(event.tenant_id(), tenant_id);
    assert_eq!(event.actor_id(), actor_id);
    assert_eq!(event.space_fingerprint(), fingerprint);
    assert_eq!(event.action_code(), "space_registration_intent");
    assert_ne!(event.event_id(), tenant_id);
    assert_ne!(event.event_id(), actor_id);
}

#[test]
fn audit_rejection_prevents_registry_mutation() {
    let tenant_id = relay_identifier(TENANT_A);
    let actor_id = relay_identifier(ACTOR_A);
    let manifest = manifest();
    let fingerprint = manifest.fingerprint().to_owned();
    let mut registry = TenantSpaceRegistry::new();
    let mut audit = RecordingAudit {
        events: Vec::new(),
        reject: true,
    };

    assert_eq!(
        registry.register_space(tenant_id, actor_id, &manifest, &mut audit),
        Err(TenantRegistryError::AuditRejected)
    );
    assert!(!registry.contains_space(tenant_id, &fingerprint));
    assert_eq!(registry.tenant_space_count(tenant_id), 0);
    assert!(audit.events.is_empty());
}

#[test]
fn duplicate_registration_fails_without_duplicate_audit_record() {
    let tenant_id = relay_identifier(TENANT_A);
    let actor_id = relay_identifier(ACTOR_A);
    let manifest = manifest();
    let mut registry = TenantSpaceRegistry::new();
    let mut audit = RecordingAudit::default();

    registry
        .register_space(tenant_id, actor_id, &manifest, &mut audit)
        .expect("first registration should succeed");
    assert_eq!(
        registry.register_space(tenant_id, actor_id, &manifest, &mut audit),
        Err(TenantRegistryError::AlreadyRegistered)
    );
    assert_eq!(audit.events.len(), 1);
    assert_eq!(registry.tenant_space_count(tenant_id), 1);
}

#[test]
fn identical_space_fingerprints_remain_isolated_by_tenant() {
    let tenant_a = relay_identifier(TENANT_A);
    let tenant_b = relay_identifier(TENANT_B);
    let actor_id = relay_identifier(ACTOR_A);
    let manifest = manifest();
    let fingerprint = manifest.fingerprint().to_owned();
    let mut registry = TenantSpaceRegistry::new();
    let mut audit = RecordingAudit::default();

    registry
        .register_space(tenant_a, actor_id, &manifest, &mut audit)
        .expect("tenant A registration should succeed");
    registry
        .register_space(tenant_b, actor_id, &manifest, &mut audit)
        .expect("tenant B registration should succeed");

    assert!(registry.contains_space(tenant_a, &fingerprint));
    assert!(registry.contains_space(tenant_b, &fingerprint));
    assert_eq!(registry.tenant_space_count(tenant_a), 1);
    assert_eq!(registry.tenant_space_count(tenant_b), 1);
    assert_eq!(audit.events.len(), 2);
}
