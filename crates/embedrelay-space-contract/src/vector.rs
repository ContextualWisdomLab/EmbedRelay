use thiserror::Error;

use crate::EmbeddingSpaceManifest;

const FLOAT32_PRECISION_CODE: &str = "float32";

/// A finite, non-degenerate `float32` embedding bound to one exact vector space.
///
/// Construction validates precision, dimension, IEEE-754 category, and norm
/// before retaining any values. The stored fingerprint and metric code are
/// copied from the validated manifest so later callers cannot accidentally
/// compare vectors whose model revision, role, preprocessing, normalization,
/// or other identity material differs while dimensions happen to match.
///
/// This type performs validation and compatibility gating only. It deliberately
/// does not introduce a distance-computation kernel; computationally material
/// batch metrics therefore remain outside this slice until they can satisfy the
/// repository's CPU-parallel and GPU-parity requirements.
#[derive(Debug, Clone, PartialEq)]
pub struct ValidatedEmbeddingVector {
    space_fingerprint: String,
    distance_metric_code: String,
    values: Vec<f32>,
    squared_l2_norm: f64,
}

impl ValidatedEmbeddingVector {
    /// Validate `float32` embedding values against one exact space manifest.
    ///
    /// Validation fails closed for a manifest that describes another numeric
    /// precision, a dimension mismatch, NaN or infinity, subnormal values, or a
    /// zero L2 norm. Squared norm accumulation widens each component to `f64`
    /// so validation does not introduce avoidable `f32` overflow or precision
    /// loss.
    ///
    /// # Errors
    ///
    /// Returns [`VectorValidationError`] for the first violated vector contract.
    pub fn new(
        manifest: &EmbeddingSpaceManifest,
        values: Vec<f32>,
    ) -> Result<Self, VectorValidationError> {
        let manifest_precision = manifest.input().numeric_precision_code();
        if manifest_precision != FLOAT32_PRECISION_CODE {
            return Err(VectorValidationError::NumericPrecisionMismatch {
                manifest_precision: manifest_precision.to_owned(),
                vector_precision: FLOAT32_PRECISION_CODE,
            });
        }

        let expected_dimension = manifest.input().vector_dimension() as usize;
        if values.len() != expected_dimension {
            return Err(VectorValidationError::DimensionMismatch {
                expected: expected_dimension,
                actual: values.len(),
            });
        }

        let mut squared_l2_norm = 0.0_f64;
        for (index, component) in values.iter().copied().enumerate() {
            if !component.is_finite() {
                return Err(VectorValidationError::NonFiniteComponent { index });
            }
            if component.is_subnormal() {
                return Err(VectorValidationError::SubnormalComponent { index });
            }
            let widened = f64::from(component);
            squared_l2_norm += widened * widened;
        }

        if squared_l2_norm == 0.0 {
            return Err(VectorValidationError::ZeroNorm);
        }

        Ok(Self {
            space_fingerprint: manifest.fingerprint().to_owned(),
            distance_metric_code: manifest.input().distance_metric_code().to_owned(),
            values,
            squared_l2_norm,
        })
    }

    /// Return the canonical fingerprint of the exact space owning this vector.
    #[must_use]
    pub fn space_fingerprint(&self) -> &str {
        &self.space_fingerprint
    }

    /// Return the manifest-declared metric code for this exact vector space.
    #[must_use]
    pub fn distance_metric_code(&self) -> &str {
        &self.distance_metric_code
    }

    /// Return the validated immutable vector components.
    #[must_use]
    pub fn values(&self) -> &[f32] {
        &self.values
    }

    /// Return the `f64`-accumulated squared L2 norm captured at validation time.
    #[must_use]
    pub const fn squared_l2_norm(&self) -> f64 {
        self.squared_l2_norm
    }

    /// Return the permitted metric code only when `other` belongs to this space.
    ///
    /// Callers must pass through this gate before metric execution. Equal vector
    /// dimensions are intentionally insufficient: the complete canonical space
    /// fingerprint must match.
    ///
    /// # Errors
    ///
    /// Returns [`VectorCompatibilityError::DifferentEmbeddingSpace`] when the
    /// canonical fingerprints differ.
    pub fn same_space_metric_code(
        &self,
        other: &Self,
    ) -> Result<&str, VectorCompatibilityError> {
        if self.space_fingerprint != other.space_fingerprint {
            return Err(VectorCompatibilityError::DifferentEmbeddingSpace);
        }
        Ok(&self.distance_metric_code)
    }
}

/// Reasons `float32` embedding values cannot enter the validated vector domain.
#[derive(Debug, Clone, PartialEq, Eq, Error)]
pub enum VectorValidationError {
    /// The manifest describes a different scalar precision than this API accepts.
    #[error(
        "manifest numeric precision `{manifest_precision}` does not match vector precision `{vector_precision}`"
    )]
    NumericPrecisionMismatch {
        /// Precision declared by the embedding-space manifest.
        manifest_precision: String,
        /// Precision accepted by this vector constructor.
        vector_precision: &'static str,
    },
    /// The supplied component count differs from the manifest dimension.
    #[error("vector dimension mismatch: expected {expected}, received {actual}")]
    DimensionMismatch {
        /// Component count required by the manifest.
        expected: usize,
        /// Component count supplied by the caller.
        actual: usize,
    },
    /// A component is NaN or positive/negative infinity.
    #[error("vector component at index {index} is not finite")]
    NonFiniteComponent {
        /// Zero-based index of the rejected component.
        index: usize,
    },
    /// A component is an IEEE-754 subnormal value.
    #[error("vector component at index {index} is subnormal")]
    SubnormalComponent {
        /// Zero-based index of the rejected component.
        index: usize,
    },
    /// Every component is positive or negative zero, producing no usable direction.
    #[error("vector L2 norm must be greater than zero")]
    ZeroNorm,
}

/// Reasons two individually valid vectors cannot share a metric operation.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Error)]
pub enum VectorCompatibilityError {
    /// Canonical embedding-space fingerprints differ.
    #[error("vectors belong to different embedding spaces")]
    DifferentEmbeddingSpace,
}
