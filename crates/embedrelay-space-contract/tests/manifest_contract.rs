use embedrelay_space_contract::{EmbeddingSpaceManifest, ManifestValidationError};

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

#[test]
fn strict_manifest_accepts_valid_material_identity() {
    let manifest = EmbeddingSpaceManifest::from_json(VALID_MANIFEST).expect("valid manifest");

    assert!(manifest.fingerprint().starts_with("sha256:"));
    assert_eq!(manifest.fingerprint().len(), 71);
    assert!(manifest
        .canonical_json()
        .contains("\"provider_identifier\":\"example_provider\""));
    assert!(!manifest.canonical_json().contains('\n'));
}

#[test]
fn strict_manifest_rejects_an_unknown_material_field() {
    let manifest = VALID_MANIFEST.replace(
        "\n}",
        ",\n  \"unexpected_material_field\":true\n}",
    );

    assert!(matches!(
        EmbeddingSpaceManifest::from_json(&manifest),
        Err(ManifestValidationError::InvalidJson { .. })
    ));
}

#[test]
fn strict_manifest_rejects_invalid_json() {
    assert!(matches!(
        EmbeddingSpaceManifest::from_json("not-json"),
        Err(ManifestValidationError::InvalidJson { .. })
    ));
}

#[test]
fn strict_manifest_rejects_zero_vector_dimension() {
    let manifest = VALID_MANIFEST.replace("\"vector_dimension\":16", "\"vector_dimension\":0");

    assert_eq!(
        EmbeddingSpaceManifest::from_json(&manifest).unwrap_err(),
        ManifestValidationError::ZeroVectorDimension
    );
}

#[test]
fn strict_manifest_rejects_blank_identity_field() {
    let manifest = VALID_MANIFEST.replace(
        "\"model_revision\":\"revision_1\"",
        "\"model_revision\":\"   \"",
    );

    assert_eq!(
        EmbeddingSpaceManifest::from_json(&manifest).unwrap_err(),
        ManifestValidationError::InvalidTextField {
            field_name: "model_revision"
        }
    );
}

#[test]
fn strict_manifest_rejects_identity_field_with_outer_whitespace() {
    let manifest = VALID_MANIFEST.replace(
        "\"model_identifier\":\"example_model\"",
        "\"model_identifier\":\" example_model\"",
    );

    assert_eq!(
        EmbeddingSpaceManifest::from_json(&manifest).unwrap_err(),
        ManifestValidationError::InvalidTextField {
            field_name: "model_identifier"
        }
    );
}

#[test]
fn strict_manifest_rejects_malformed_material_hash() {
    let manifest = VALID_MANIFEST.replace(
        "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        "sha256:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    );

    assert_eq!(
        EmbeddingSpaceManifest::from_json(&manifest).unwrap_err(),
        ManifestValidationError::InvalidSha256Field {
            field_name: "instruction_template_hash"
        }
    );
}

#[test]
fn strict_manifest_rejects_short_material_hash() {
    let manifest = VALID_MANIFEST.replace(
        "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
        "sha256:bbbb",
    );

    assert_eq!(
        EmbeddingSpaceManifest::from_json(&manifest).unwrap_err(),
        ManifestValidationError::InvalidSha256Field {
            field_name: "preprocessing_policy_hash"
        }
    );
}

#[test]
fn canonical_fingerprint_is_independent_of_json_key_order() {
    let reordered = r#"{
      "vector_dimension":16,
      "distance_metric_code":"cosine",
      "normalization_strategy_code":"l2",
      "pooling_strategy_code":"mean_pooling",
      "numeric_precision_code":"float32",
      "input_role_code":"document",
      "modality_code":"text",
      "model_revision":"revision_1",
      "model_identifier":"example_model",
      "provider_identifier":"example_provider",
      "preprocessing_policy_hash":"sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
      "instruction_template_hash":"sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    }"#;

    let first = EmbeddingSpaceManifest::from_json(VALID_MANIFEST).expect("valid manifest");
    let second = EmbeddingSpaceManifest::from_json(reordered).expect("same valid manifest");

    assert_eq!(first.canonical_json(), second.canonical_json());
    assert_eq!(first.fingerprint(), second.fingerprint());
}

#[test]
fn canonical_fingerprint_changes_when_material_identity_changes() {
    let changed = VALID_MANIFEST.replace("revision_1", "revision_2");
    let first = EmbeddingSpaceManifest::from_json(VALID_MANIFEST).expect("valid manifest");
    let second = EmbeddingSpaceManifest::from_json(&changed).expect("changed valid manifest");

    assert_ne!(first.fingerprint(), second.fingerprint());
}
