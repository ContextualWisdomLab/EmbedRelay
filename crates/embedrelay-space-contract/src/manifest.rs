use serde::Deserialize;
use sha2::{Digest, Sha256};
use thiserror::Error;

const FINGERPRINT_DOMAIN: &[u8] = b"embedrelay-space-manifest-v1\0";
const LOWER_HEX_DIGITS: &[u8; 16] = b"0123456789abcdef";

/// Strict material inputs that define one embedding vector space.
///
/// All fields are immutable identity material: if any value changes, the
/// resulting embedding-space fingerprint changes as well. Construct this type
/// through [`EmbeddingSpaceManifest::from_json`] so validation cannot be
/// bypassed accidentally.
#[derive(Debug, Clone, PartialEq, Eq, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct EmbeddingSpaceManifestInput {
    provider_identifier: String,
    model_identifier: String,
    model_revision: String,
    modality_code: String,
    input_role_code: String,
    instruction_template_hash: String,
    pooling_strategy_code: String,
    normalization_strategy_code: String,
    vector_dimension: u32,
    numeric_precision_code: String,
    distance_metric_code: String,
    preprocessing_policy_hash: String,
}

impl EmbeddingSpaceManifestInput {
    /// Return the provider identifier used to create vectors in this space.
    #[must_use]
    pub fn provider_identifier(&self) -> &str {
        &self.provider_identifier
    }

    /// Return the provider-specific model identifier.
    #[must_use]
    pub fn model_identifier(&self) -> &str {
        &self.model_identifier
    }

    /// Return the immutable model revision identifier.
    #[must_use]
    pub fn model_revision(&self) -> &str {
        &self.model_revision
    }

    /// Return the modality code, such as `text`.
    #[must_use]
    pub fn modality_code(&self) -> &str {
        &self.modality_code
    }

    /// Return the input-role code, such as `document` or `query`.
    #[must_use]
    pub fn input_role_code(&self) -> &str {
        &self.input_role_code
    }

    /// Return the SHA-256 identity of the instruction template.
    #[must_use]
    pub fn instruction_template_hash(&self) -> &str {
        &self.instruction_template_hash
    }

    /// Return the pooling-strategy code used by the embedding pipeline.
    #[must_use]
    pub fn pooling_strategy_code(&self) -> &str {
        &self.pooling_strategy_code
    }

    /// Return the vector-normalization strategy code.
    #[must_use]
    pub fn normalization_strategy_code(&self) -> &str {
        &self.normalization_strategy_code
    }

    /// Return the exact number of scalar values in each vector.
    #[must_use]
    pub const fn vector_dimension(&self) -> u32 {
        self.vector_dimension
    }

    /// Return the numeric precision code used for stored vector values.
    #[must_use]
    pub fn numeric_precision_code(&self) -> &str {
        &self.numeric_precision_code
    }

    /// Return the distance-metric code permitted for this vector space.
    #[must_use]
    pub fn distance_metric_code(&self) -> &str {
        &self.distance_metric_code
    }

    /// Return the SHA-256 identity of the preprocessing policy.
    #[must_use]
    pub fn preprocessing_policy_hash(&self) -> &str {
        &self.preprocessing_policy_hash
    }

    fn validate(&self) -> Result<(), ManifestValidationError> {
        let text_fields = [
            ("provider_identifier", self.provider_identifier.as_str()),
            ("model_identifier", self.model_identifier.as_str()),
            ("model_revision", self.model_revision.as_str()),
            ("modality_code", self.modality_code.as_str()),
            ("input_role_code", self.input_role_code.as_str()),
            ("pooling_strategy_code", self.pooling_strategy_code.as_str()),
            (
                "normalization_strategy_code",
                self.normalization_strategy_code.as_str(),
            ),
            (
                "numeric_precision_code",
                self.numeric_precision_code.as_str(),
            ),
            ("distance_metric_code", self.distance_metric_code.as_str()),
        ];

        for (field_name, value) in text_fields {
            validate_text_field(field_name, value)?;
        }
        validate_sha256_field(
            "instruction_template_hash",
            &self.instruction_template_hash,
        )?;
        validate_sha256_field(
            "preprocessing_policy_hash",
            &self.preprocessing_policy_hash,
        )?;
        if self.vector_dimension == 0 {
            return Err(ManifestValidationError::ZeroVectorDimension);
        }
        Ok(())
    }

    fn update_fingerprint(&self, hasher: &mut Sha256) {
        update_length_prefixed_text(hasher, &self.provider_identifier);
        update_length_prefixed_text(hasher, &self.model_identifier);
        update_length_prefixed_text(hasher, &self.model_revision);
        update_length_prefixed_text(hasher, &self.modality_code);
        update_length_prefixed_text(hasher, &self.input_role_code);
        update_length_prefixed_text(hasher, &self.instruction_template_hash);
        update_length_prefixed_text(hasher, &self.pooling_strategy_code);
        update_length_prefixed_text(hasher, &self.normalization_strategy_code);
        update_length_prefixed_text(hasher, &self.vector_dimension.to_string());
        update_length_prefixed_text(hasher, &self.numeric_precision_code);
        update_length_prefixed_text(hasher, &self.distance_metric_code);
        update_length_prefixed_text(hasher, &self.preprocessing_policy_hash);
    }
}

/// A validated embedding-space manifest paired with its canonical fingerprint.
///
/// The fingerprint is domain-separated and hashes every material field in a
/// fixed order with length-prefix framing. JSON object key order and cosmetic
/// whitespace therefore cannot change the identity of an otherwise identical
/// manifest.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct EmbeddingSpaceManifest {
    input: EmbeddingSpaceManifestInput,
    fingerprint: String,
}

impl EmbeddingSpaceManifest {
    /// Parse, strictly validate, and fingerprint a JSON manifest.
    ///
    /// Unknown JSON keys fail closed so newly introduced material cannot be
    /// silently ignored by older EmbedRelay components.
    ///
    /// # Errors
    ///
    /// Returns [`ManifestValidationError`] when JSON does not satisfy the
    /// strict schema or when material identity values violate their contracts.
    pub fn from_json(manifest_json: &str) -> Result<Self, ManifestValidationError> {
        let input: EmbeddingSpaceManifestInput = serde_json::from_str(manifest_json).map_err(
            |source| ManifestValidationError::InvalidJson {
                message: source.to_string(),
            },
        )?;
        input.validate()?;

        let mut hasher = Sha256::new();
        hasher.update(FINGERPRINT_DOMAIN);
        input.update_fingerprint(&mut hasher);
        let digest = hasher.finalize();
        let fingerprint = format!("sha256:{}", encode_lower_hex(&digest));

        Ok(Self { input, fingerprint })
    }

    /// Return the validated identity material represented by this manifest.
    #[must_use]
    pub const fn input(&self) -> &EmbeddingSpaceManifestInput {
        &self.input
    }

    /// Return the canonical `sha256:<lowercase-hex>` space fingerprint.
    #[must_use]
    pub fn fingerprint(&self) -> &str {
        &self.fingerprint
    }
}

/// Reasons a strict embedding-space manifest cannot be accepted.
#[derive(Debug, Clone, PartialEq, Eq, Error)]
pub enum ManifestValidationError {
    /// The input is malformed JSON, has missing fields, or contains unknown keys.
    #[error("manifest JSON does not satisfy the strict schema: {message}")]
    InvalidJson {
        /// Human-readable parser detail suitable for diagnostics.
        message: String,
    },
    /// A textual identity field is empty or has leading/trailing whitespace.
    #[error("manifest field `{field_name}` must be non-empty with no outer whitespace")]
    InvalidTextField {
        /// Stable schema field name that failed validation.
        field_name: &'static str,
    },
    /// A material hash is not a lowercase `sha256:` value with 64 hex digits.
    #[error("manifest field `{field_name}` must be sha256:<64 lowercase hex digits>")]
    InvalidSha256Field {
        /// Stable schema field name that failed validation.
        field_name: &'static str,
    },
    /// Vector dimensions must be positive so the space is operationally meaningful.
    #[error("vector_dimension must be greater than zero")]
    ZeroVectorDimension,
}

fn validate_text_field(
    field_name: &'static str,
    value: &str,
) -> Result<(), ManifestValidationError> {
    if value.is_empty() || value.trim() != value {
        return Err(ManifestValidationError::InvalidTextField { field_name });
    }
    Ok(())
}

fn validate_sha256_field(
    field_name: &'static str,
    value: &str,
) -> Result<(), ManifestValidationError> {
    let is_valid = value
        .strip_prefix("sha256:")
        .is_some_and(|digest| digest.len() == 64 && digest.bytes().all(is_lower_hex_digit));
    if !is_valid {
        return Err(ManifestValidationError::InvalidSha256Field { field_name });
    }
    Ok(())
}

fn is_lower_hex_digit(value: u8) -> bool {
    LOWER_HEX_DIGITS.contains(&value)
}

fn update_length_prefixed_text(hasher: &mut Sha256, value: &str) {
    hasher.update(value.len().to_string().as_bytes());
    hasher.update(b":");
    hasher.update(value.as_bytes());
}

fn encode_lower_hex(bytes: &[u8]) -> String {
    let mut output = String::with_capacity(bytes.len() * 2);
    for byte in bytes {
        output.push(char::from(LOWER_HEX_DIGITS[usize::from(*byte >> 4)]));
        output.push(char::from(LOWER_HEX_DIGITS[usize::from(*byte & 0x0f)]));
    }
    output
}
