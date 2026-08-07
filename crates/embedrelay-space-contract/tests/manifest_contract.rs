use embedrelay_space_contract::EmbeddingSpaceManifest;

#[test]
fn strict_manifest_rejects_an_unknown_material_field() {
    let manifest = r#"{
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
      "preprocessing_policy_hash":"sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
      "unexpected_material_field":true
    }"#;

    assert!(EmbeddingSpaceManifest::from_json(manifest).is_err());
}
