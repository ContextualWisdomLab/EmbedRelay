//! Canonical embedding-space identity contracts for EmbedRelay.

#![forbid(unsafe_code)]
#![deny(missing_docs)]

mod manifest;

pub use manifest::{EmbeddingSpaceManifest, EmbeddingSpaceManifestInput, ManifestValidationError};
