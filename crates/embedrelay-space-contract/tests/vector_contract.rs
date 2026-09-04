//! Regression contracts for fail-closed embedding-vector validation.

use embedrelay_space_contract::{
    EmbeddingSpaceManifest, ValidatedEmbeddingVector, VectorCompatibilityError,
    VectorValidationError,
};

fn manifest_json(
    revision: &str,
    dimension: u32,
    numeric_precision: &str,
    distance_metric: &str,
) -> String {
    format!(
        r#"{{
  "provider_identifier":"example_provider",
  "model_identifier":"example_model",
  "model_revision":"{revision}",
  "modality_code":"text",
  "input_role_code":"document",
  "instruction_template_hash":"sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  "pooling_strategy_code":"mean_pooling",
  "normalization_strategy_code":"l2",
  "vector_dimension":{dimension},
  "numeric_precision_code":"{numeric_precision}",
  "distance_metric_code":"{distance_metric}",
  "preprocessing_policy_hash":"sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
}}"#
    )
}

fn manifest(revision: &str, dimension: u32) -> EmbeddingSpaceManifest {
    EmbeddingSpaceManifest::from_json(&manifest_json(revision, dimension, "float32", "cosine"))
        .expect("test manifest must be valid")
}

#[test]
fn validated_vector_binds_values_to_exact_space_and_metric() {
    let space = manifest("revision_1", 4);
    let vector = ValidatedEmbeddingVector::new(&space, vec![0.5, -0.5, 0.5, -0.5])
        .expect("finite non-zero vector must validate");

    assert_eq!(vector.space_fingerprint(), space.fingerprint());
    assert_eq!(vector.distance_metric_code(), "cosine");
    assert_eq!(vector.values(), &[0.5, -0.5, 0.5, -0.5]);
    assert!((vector.squared_l2_norm() - 1.0).abs() < f64::EPSILON);
}

#[test]
fn vector_validation_rejects_dimension_mismatch() {
    let space = manifest("revision_1", 4);

    assert_eq!(
        ValidatedEmbeddingVector::new(&space, vec![1.0, 0.0, 0.0]).unwrap_err(),
        VectorValidationError::DimensionMismatch {
            expected: 4,
            actual: 3,
        }
    );
}

#[test]
fn vector_validation_rejects_non_finite_components() {
    let space = manifest("revision_1", 2);

    assert_eq!(
        ValidatedEmbeddingVector::new(&space, vec![1.0, f32::NAN]).unwrap_err(),
        VectorValidationError::NonFiniteComponent { index: 1 }
    );
    assert_eq!(
        ValidatedEmbeddingVector::new(&space, vec![f32::INFINITY, 1.0]).unwrap_err(),
        VectorValidationError::NonFiniteComponent { index: 0 }
    );
    assert_eq!(
        ValidatedEmbeddingVector::new(&space, vec![1.0, f32::NEG_INFINITY]).unwrap_err(),
        VectorValidationError::NonFiniteComponent { index: 1 }
    );
}

#[test]
fn vector_validation_rejects_subnormal_components() {
    let space = manifest("revision_1", 2);
    let subnormal = f32::from_bits(1);
    assert!(subnormal.is_subnormal());

    assert_eq!(
        ValidatedEmbeddingVector::new(&space, vec![1.0, subnormal]).unwrap_err(),
        VectorValidationError::SubnormalComponent { index: 1 }
    );
}

#[test]
fn vector_validation_rejects_zero_norm() {
    let space = manifest("revision_1", 4);

    assert_eq!(
        ValidatedEmbeddingVector::new(&space, vec![0.0, -0.0, 0.0, -0.0]).unwrap_err(),
        VectorValidationError::ZeroNorm
    );
}

#[test]
fn float32_vector_api_rejects_other_manifest_precision() {
    let space = EmbeddingSpaceManifest::from_json(&manifest_json(
        "revision_1",
        2,
        "float16",
        "cosine",
    ))
    .expect("manifest identity may describe a precision this API does not support");

    assert_eq!(
        ValidatedEmbeddingVector::new(&space, vec![1.0, 0.0]).unwrap_err(),
        VectorValidationError::NumericPrecisionMismatch {
            manifest_precision: "float16".to_owned(),
            vector_precision: "float32",
        }
    );
}

#[test]
fn metric_gate_accepts_only_the_same_embedding_space() {
    let space = manifest("revision_1", 2);
    let left = ValidatedEmbeddingVector::new(&space, vec![1.0, 0.0]).expect("left vector");
    let right = ValidatedEmbeddingVector::new(&space, vec![0.0, 1.0]).expect("right vector");

    assert_eq!(left.same_space_metric_code(&right), Ok("cosine"));
}

#[test]
fn metric_gate_rejects_equal_dimension_vectors_from_different_spaces() {
    let old_space = manifest("revision_1", 2);
    let new_space = manifest("revision_2", 2);
    let left = ValidatedEmbeddingVector::new(&old_space, vec![1.0, 0.0]).expect("left vector");
    let right =
        ValidatedEmbeddingVector::new(&new_space, vec![0.0, 1.0]).expect("right vector");

    assert_eq!(
        left.same_space_metric_code(&right),
        Err(VectorCompatibilityError::DifferentEmbeddingSpace)
    );
}
