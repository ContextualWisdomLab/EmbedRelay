use std::collections::BTreeSet;

use thiserror::Error;

use crate::{EmbeddingSpaceManifest, RelayIdentifier};

const SPACE_REGISTRATION_INTENT: &str = "space_registration_intent";

/// Immutable audit material emitted before a tenant registry mutation is exposed.
///
/// The action is intentionally an *intent* rather than a success event. A durable
/// storage adapter can therefore persist this record before mutation without
/// claiming that a later mutation necessarily completed. Production database
/// adapters should commit the intent and registry mutation in one transaction.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpaceRegistrationAuditEvent {
    event_id: RelayIdentifier,
    tenant_id: RelayIdentifier,
    actor_id: RelayIdentifier,
    space_fingerprint: String,
}

impl SpaceRegistrationAuditEvent {
    /// Return the opaque UUIDv7 audit-event identifier.
    #[must_use]
    pub const fn event_id(&self) -> RelayIdentifier {
        self.event_id
    }

    /// Return the tenant whose registry would be mutated.
    #[must_use]
    pub const fn tenant_id(&self) -> RelayIdentifier {
        self.tenant_id
    }

    /// Return the actor responsible for the attempted registration.
    #[must_use]
    pub const fn actor_id(&self) -> RelayIdentifier {
        self.actor_id
    }

    /// Return the canonical embedding-space fingerprint being registered.
    #[must_use]
    pub fn space_fingerprint(&self) -> &str {
        &self.space_fingerprint
    }

    /// Return the stable action code for this pre-mutation audit record.
    #[must_use]
    pub const fn action_code(&self) -> &'static str {
        SPACE_REGISTRATION_INTENT
    }
}

/// Stable reason an audit recorder cannot durably accept a registration intent.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Error)]
pub enum AuditRecordError {
    /// The audit boundary rejected or could not durably accept the event.
    #[error("audit recorder rejected registration intent")]
    Rejected,
}

/// Fail-closed audit boundary required before tenant registry mutation.
///
/// Implementations should durably record the supplied intent before returning
/// `Ok(())`. Returning an error guarantees that [`TenantSpaceRegistry`] leaves
/// its in-memory registry unchanged.
pub trait SpaceRegistrationAuditRecorder {
    /// Record one immutable registration intent before registry mutation.
    ///
    /// # Errors
    ///
    /// Returns [`AuditRecordError`] when the audit boundary cannot durably
    /// accept the event. Callers must treat this as a hard mutation failure.
    fn record_registration(
        &mut self,
        event: &SpaceRegistrationAuditEvent,
    ) -> Result<(), AuditRecordError>;
}

/// Tenant-isolated reference registry for canonical embedding-space identities.
///
/// This in-memory type defines the fail-closed domain contract used by future
/// durable adapters. A space is keyed by both tenant UUIDv7 and the complete
/// canonical fingerprint, so identical models may be registered independently
/// by different tenants without creating cross-tenant visibility.
#[derive(Debug, Default)]
pub struct TenantSpaceRegistry {
    registrations: BTreeSet<(RelayIdentifier, String)>,
}

impl TenantSpaceRegistry {
    /// Create an empty tenant registry.
    #[must_use]
    pub fn new() -> Self {
        Self::default()
    }

    /// Register one canonical embedding space after the audit boundary accepts intent.
    ///
    /// The registry checks idempotency before creating an audit event. It then
    /// requires the supplied recorder to accept a `space_registration_intent`
    /// event before making the new tenant-scoped entry observable. This ordering
    /// ensures audit rejection cannot produce an unaudited registry mutation.
    ///
    /// # Errors
    ///
    /// Returns [`TenantRegistryError::AlreadyRegistered`] when the same tenant
    /// already owns the same canonical space fingerprint. Returns
    /// [`TenantRegistryError::AuditRejected`] when the audit recorder fails; in
    /// that case registry state remains unchanged.
    pub fn register_space<R: SpaceRegistrationAuditRecorder>(
        &mut self,
        tenant_id: RelayIdentifier,
        actor_id: RelayIdentifier,
        manifest: &EmbeddingSpaceManifest,
        audit_recorder: &mut R,
    ) -> Result<SpaceRegistrationAuditEvent, TenantRegistryError> {
        let space_fingerprint = manifest.fingerprint().to_owned();
        let registry_key = (tenant_id, space_fingerprint.clone());
        if self.registrations.contains(&registry_key) {
            return Err(TenantRegistryError::AlreadyRegistered);
        }

        let audit_event = SpaceRegistrationAuditEvent {
            event_id: RelayIdentifier::new(),
            tenant_id,
            actor_id,
            space_fingerprint,
        };
        audit_recorder
            .record_registration(&audit_event)
            .map_err(|_| TenantRegistryError::AuditRejected)?;
        self.registrations.insert(registry_key);
        Ok(audit_event)
    }

    /// Return whether a tenant currently owns the exact canonical space fingerprint.
    #[must_use]
    pub fn contains_space(&self, tenant_id: RelayIdentifier, space_fingerprint: &str) -> bool {
        self.tenant_entries(tenant_id)
            .any(|(_, candidate_fingerprint)| candidate_fingerprint == space_fingerprint)
    }

    /// Count spaces registered to exactly one tenant without exposing other tenants' entries.
    #[must_use]
    pub fn tenant_space_count(&self, tenant_id: RelayIdentifier) -> usize {
        self.tenant_entries(tenant_id).count()
    }

    fn tenant_entries(
        &self,
        tenant_id: RelayIdentifier,
    ) -> impl Iterator<Item = &(RelayIdentifier, String)> {
        self.registrations
            .range((tenant_id, String::new())..)
            .take_while(move |(candidate_tenant, _)| *candidate_tenant == tenant_id)
    }
}

/// Stable, non-reflecting reasons a tenant registration cannot be accepted.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Error)]
pub enum TenantRegistryError {
    /// The tenant already owns the exact canonical space fingerprint.
    #[error("embedding space is already registered for this tenant")]
    AlreadyRegistered,
    /// The audit boundary rejected the mutation intent, so no state was changed.
    #[error("embedding space registration was rejected by the audit boundary")]
    AuditRejected,
}
