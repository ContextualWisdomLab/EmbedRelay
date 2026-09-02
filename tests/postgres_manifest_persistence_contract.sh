#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL must point at the PostgreSQL 18.6 test database}"

manifest_table="embedrelay_registry.embedding_space_manifest"
manifest_function="embedrelay_registry.register_tenant_space_manifest(uuid,text,jsonb)"

if [[ "$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -tAc "SELECT to_regclass('${manifest_table}') IS NOT NULL;")" != "t" ]]; then
  echo "full canonical manifest persistence table is required" >&2
  exit 1
fi
if [[ "$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -tAc "SELECT to_regprocedure('${manifest_function}') IS NOT NULL;")" != "t" ]]; then
  echo "manifest-bearing registration function is required" >&2
  exit 1
fi

psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<'SQL'
GRANT SELECT, UPDATE, DELETE, TRUNCATE
  ON embedrelay_registry.embedding_space_manifest
  TO embedrelay_test_client;
GRANT EXECUTE
  ON FUNCTION embedrelay_registry.register_tenant_space_manifest(uuid, text, jsonb)
  TO embedrelay_test_client;

BEGIN;
SET ROLE embedrelay_test_client;

SELECT set_config('embedrelay.tenant_id', '017f22e2-79b0-7cc3-98c4-dc0c0c0c0760', true);

DO $$
DECLARE
  canonical_manifest jsonb := '{
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
  }'::jsonb;
  canonical_fingerprint text := 'sha256:d105d04ca1cbdf6d8ba00dec0be676045e76059d16e4de404bd71a27d22bccb1';
  registration_event uuid;
BEGIN
  registration_event := embedrelay_registry.register_tenant_space_manifest(
    '017f22e2-79b0-7cc3-98c4-dc0c0c0c0761'::uuid,
    canonical_fingerprint,
    canonical_manifest
  );

  IF uuid_extract_version(registration_event) IS DISTINCT FROM 7 THEN
    RAISE EXCEPTION 'manifest registration audit event must be UUIDv7';
  END IF;
  IF (SELECT count(*) FROM embedrelay_registry.tenant_space_registry) <> 1 THEN
    RAISE EXCEPTION 'manifest registration must create exactly one tenant registry row';
  END IF;
  IF (SELECT count(*) FROM embedrelay_registry.space_registration_audit) <> 1 THEN
    RAISE EXCEPTION 'manifest registration must create exactly one durable audit event';
  END IF;
  IF (
    SELECT count(*)
      FROM embedrelay_registry.embedding_space_manifest
     WHERE space_fingerprint = canonical_fingerprint
       AND manifest_version_code = 'embedding-space-manifest-v1'
       AND provider_identifier = 'example_provider'
       AND model_identifier = 'example_model'
       AND model_revision = 'revision_1'
       AND modality_code = 'text'
       AND input_role_code = 'document'
       AND instruction_template_hash = 'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
       AND pooling_strategy_code = 'mean_pooling'
       AND normalization_strategy_code = 'l2'
       AND vector_dimension = 16
       AND numeric_precision_code = 'float32'
       AND distance_metric_code = 'cosine'
       AND preprocessing_policy_hash = 'sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
  ) <> 1 THEN
    RAISE EXCEPTION 'canonical manifest material did not round-trip exactly';
  END IF;

  BEGIN
    PERFORM embedrelay_registry.register_tenant_space_manifest(
      '017f22e2-79b0-7cc3-98c4-dc0c0c0c0762'::uuid,
      'sha256:' || repeat('c', 64),
      canonical_manifest
    );
    RAISE EXCEPTION 'fingerprint/material mismatch unexpectedly succeeded';
  EXCEPTION
    WHEN invalid_parameter_value THEN NULL;
  END;

  BEGIN
    PERFORM embedrelay_registry.register_tenant_space_manifest(
      '017f22e2-79b0-7cc3-98c4-dc0c0c0c0762'::uuid,
      canonical_fingerprint,
      canonical_manifest || '{"unexpected_material_field":true}'::jsonb
    );
    RAISE EXCEPTION 'unknown manifest material unexpectedly succeeded';
  EXCEPTION
    WHEN invalid_parameter_value THEN NULL;
  END;

  IF (SELECT count(*) FROM embedrelay_registry.space_registration_audit) <> 1 THEN
    RAISE EXCEPTION 'rejected manifests must not leave audit intents behind';
  END IF;

  BEGIN
    UPDATE embedrelay_registry.embedding_space_manifest
       SET model_revision = model_revision;
    RAISE EXCEPTION 'canonical manifest update unexpectedly succeeded';
  EXCEPTION
    WHEN SQLSTATE '55000' THEN NULL;
  END;

  BEGIN
    DELETE FROM embedrelay_registry.embedding_space_manifest;
    RAISE EXCEPTION 'canonical manifest delete unexpectedly succeeded';
  EXCEPTION
    WHEN SQLSTATE '55000' THEN NULL;
  END;

  BEGIN
    TRUNCATE TABLE embedrelay_registry.embedding_space_manifest;
    RAISE EXCEPTION 'canonical manifest truncate unexpectedly succeeded';
  EXCEPTION
    WHEN SQLSTATE '55000' THEN NULL;
  END;
END
$$;

SELECT set_config('embedrelay.tenant_id', '017f22e2-79b0-7cc3-98c4-dc0c0c0c0763', true);
DO $$
DECLARE
  canonical_manifest jsonb := '{
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
  }'::jsonb;
  canonical_fingerprint text := 'sha256:d105d04ca1cbdf6d8ba00dec0be676045e76059d16e4de404bd71a27d22bccb1';
BEGIN
  IF (SELECT count(*) FROM embedrelay_registry.embedding_space_manifest) <> 0 THEN
    RAISE EXCEPTION 'manifest catalog leaked before this tenant registered the space';
  END IF;

  PERFORM embedrelay_registry.register_tenant_space_manifest(
    '017f22e2-79b0-7cc3-98c4-dc0c0c0c0764'::uuid,
    canonical_fingerprint,
    canonical_manifest
  );

  IF (SELECT count(*) FROM embedrelay_registry.embedding_space_manifest) <> 1 THEN
    RAISE EXCEPTION 'second tenant must see the shared canonical manifest only after registration';
  END IF;
  IF (SELECT count(*) FROM embedrelay_registry.tenant_space_registry) <> 1 THEN
    RAISE EXCEPTION 'second tenant must see only its own registry row';
  END IF;
END
$$;

SELECT set_config('embedrelay.tenant_id', '017f22e2-79b0-7cc3-98c4-dc0c0c0c0765', true);
DO $$
BEGIN
  IF (SELECT count(*) FROM embedrelay_registry.embedding_space_manifest) <> 0 THEN
    RAISE EXCEPTION 'unregistered tenant can see canonical manifest material';
  END IF;
END
$$;

RESET ROLE;
DO $$
BEGIN
  IF (SELECT count(*) FROM embedrelay_registry.embedding_space_manifest) <> 1 THEN
    RAISE EXCEPTION 'identical cross-tenant manifests must deduplicate to one canonical row';
  END IF;
  IF (SELECT count(*) FROM embedrelay_registry.tenant_space_registry) <> 2 THEN
    RAISE EXCEPTION 'two tenants must retain two independent registration rows';
  END IF;
  IF (SELECT count(*) FROM embedrelay_registry.space_registration_audit) <> 2 THEN
    RAISE EXCEPTION 'two accepted tenant registrations must retain two audit intents';
  END IF;
END
$$;
ROLLBACK;
SQL
