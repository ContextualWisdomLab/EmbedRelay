//! Canonical embedding-space identity contracts for EmbedRelay.

#![forbid(unsafe_code)]
#![deny(missing_docs)]

mod identifier;
mod manifest;
mod registry;
mod vector;

pub use identifier::{RelayIdentifier, RelayIdentifierParseError};
pub use manifest::{EmbeddingSpaceManifest, EmbeddingSpaceManifestInput, ManifestValidationError};
pub use registry::{
    AuditRecordError, SpaceRegistrationAuditEvent, SpaceRegistrationAuditRecorder,
    TenantRegistryError, TenantSpaceRegistry,
};
pub use vector::{
    ValidatedEmbeddingVector, VectorCompatibilityError, VectorValidationError,
};
