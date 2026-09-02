BEGIN;

CREATE TABLE embedrelay_registry.embedding_space_manifest (
    space_fingerprint text PRIMARY KEY,
    manifest_version_code text NOT NULL DEFAULT 'embedding-space-manifest-v1',
    provider_identifier text NOT NULL,
    model_identifier text NOT NULL,
    model_revision text NOT NULL,
    modality_code text NOT NULL,
    input_role_code text NOT NULL,
    instruction_template_hash text NOT NULL,
    pooling_strategy_code text NOT NULL,
    normalization_strategy_code text NOT NULL,
    vector_dimension bigint NOT NULL,
    numeric_precision_code text NOT NULL,
    distance_metric_code text NOT NULL,
    preprocessing_policy_hash text NOT NULL,
    manifest_created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT embedding_space_manifest_fingerprint_format
        CHECK (space_fingerprint ~ '^sha256:[0-9a-f]{64}$'),
    CONSTRAINT embedding_space_manifest_version_code
        CHECK (manifest_version_code = 'embedding-space-manifest-v1'),
    CONSTRAINT embedding_space_manifest_provider_identifier
        CHECK (provider_identifier <> '' AND btrim(provider_identifier) = provider_identifier AND provider_identifier !~ '[[:cntrl:]]'),
    CONSTRAINT embedding_space_manifest_model_identifier
        CHECK (model_identifier <> '' AND btrim(model_identifier) = model_identifier AND model_identifier !~ '[[:cntrl:]]'),
    CONSTRAINT embedding_space_manifest_model_revision
        CHECK (model_revision <> '' AND btrim(model_revision) = model_revision AND model_revision !~ '[[:cntrl:]]'),
    CONSTRAINT embedding_space_manifest_modality_code
        CHECK (modality_code <> '' AND btrim(modality_code) = modality_code AND modality_code !~ '[[:cntrl:]]'),
    CONSTRAINT embedding_space_manifest_input_role_code
        CHECK (input_role_code <> '' AND btrim(input_role_code) = input_role_code AND input_role_code !~ '[[:cntrl:]]'),
    CONSTRAINT embedding_space_manifest_instruction_hash
        CHECK (instruction_template_hash ~ '^sha256:[0-9a-f]{64}$'),
    CONSTRAINT embedding_space_manifest_pooling_code
        CHECK (pooling_strategy_code <> '' AND btrim(pooling_strategy_code) = pooling_strategy_code AND pooling_strategy_code !~ '[[:cntrl:]]'),
    CONSTRAINT embedding_space_manifest_normalization_code
        CHECK (normalization_strategy_code <> '' AND btrim(normalization_strategy_code) = normalization_strategy_code AND normalization_strategy_code !~ '[[:cntrl:]]'),
    CONSTRAINT embedding_space_manifest_vector_dimension
        CHECK (vector_dimension > 0 AND vector_dimension <= 4294967295),
    CONSTRAINT embedding_space_manifest_precision_code
        CHECK (numeric_precision_code <> '' AND btrim(numeric_precision_code) = numeric_precision_code AND numeric_precision_code !~ '[[:cntrl:]]'),
    CONSTRAINT embedding_space_manifest_metric_code
        CHECK (distance_metric_code <> '' AND btrim(distance_metric_code) = distance_metric_code AND distance_metric_code !~ '[[:cntrl:]]'),
    CONSTRAINT embedding_space_manifest_preprocessing_hash
        CHECK (preprocessing_policy_hash ~ '^sha256:[0-9a-f]{64}$')
);

ALTER TABLE embedrelay_registry.tenant_space_registry
    ADD CONSTRAINT tenant_space_registry_manifest_reference
    FOREIGN KEY (space_fingerprint)
    REFERENCES embedrelay_registry.embedding_space_manifest (space_fingerprint)
    DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE embedrelay_registry.embedding_space_manifest ENABLE ROW LEVEL SECURITY;
ALTER TABLE embedrelay_registry.embedding_space_manifest FORCE ROW LEVEL SECURITY;

CREATE POLICY embedding_space_manifest_tenant_visibility
    ON embedrelay_registry.embedding_space_manifest
    FOR ALL
    TO PUBLIC
    USING (
        EXISTS (
            SELECT 1
              FROM embedrelay_registry.tenant_space_registry AS registered_space
             WHERE registered_space.space_fingerprint = embedding_space_manifest.space_fingerprint
               AND registered_space.tenant_id = nullif(current_setting('embedrelay.tenant_id', true), '')::uuid
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1
              FROM embedrelay_registry.tenant_space_registry AS registered_space
             WHERE registered_space.space_fingerprint = embedding_space_manifest.space_fingerprint
               AND registered_space.tenant_id = nullif(current_setting('embedrelay.tenant_id', true), '')::uuid
        )
    );

CREATE TRIGGER embedding_space_manifest_append_only_rows
BEFORE UPDATE OR DELETE
ON embedrelay_registry.embedding_space_manifest
FOR EACH ROW
EXECUTE FUNCTION embedrelay_registry.reject_registry_mutation();

CREATE TRIGGER embedding_space_manifest_append_only_truncate
BEFORE TRUNCATE
ON embedrelay_registry.embedding_space_manifest
FOR EACH STATEMENT
EXECUTE FUNCTION embedrelay_registry.reject_registry_mutation();

CREATE FUNCTION embedrelay_registry.register_tenant_space_manifest(
    registration_actor_id uuid,
    requested_space_fingerprint text,
    requested_space_manifest jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SET search_path = pg_catalog
AS $function$
DECLARE
    registration_audit_event_id uuid;
    manifest_text_key text;
    manifest_vector_dimension numeric;
    manifest_provider_identifier text;
    manifest_model_identifier text;
    manifest_model_revision text;
    manifest_modality_code text;
    manifest_input_role_code text;
    manifest_instruction_template_hash text;
    manifest_pooling_strategy_code text;
    manifest_normalization_strategy_code text;
    manifest_numeric_precision_code text;
    manifest_distance_metric_code text;
    manifest_preprocessing_policy_hash text;
    fingerprint_payload bytea;
    computed_space_fingerprint text;
BEGIN
    IF requested_space_manifest IS NULL
       OR jsonb_typeof(requested_space_manifest) IS DISTINCT FROM 'object' THEN
        RAISE EXCEPTION 'requested_space_manifest must be a JSON object'
            USING ERRCODE = '22023';
    END IF;

    IF NOT requested_space_manifest ?& ARRAY[
        'provider_identifier',
        'model_identifier',
        'model_revision',
        'modality_code',
        'input_role_code',
        'instruction_template_hash',
        'pooling_strategy_code',
        'normalization_strategy_code',
        'vector_dimension',
        'numeric_precision_code',
        'distance_metric_code',
        'preprocessing_policy_hash'
    ]
       OR EXISTS (
           SELECT 1
             FROM jsonb_object_keys(requested_space_manifest) AS manifest_keys(manifest_key)
            WHERE manifest_key <> ALL (ARRAY[
                'provider_identifier',
                'model_identifier',
                'model_revision',
                'modality_code',
                'input_role_code',
                'instruction_template_hash',
                'pooling_strategy_code',
                'normalization_strategy_code',
                'vector_dimension',
                'numeric_precision_code',
                'distance_metric_code',
                'preprocessing_policy_hash'
            ])
       ) THEN
        RAISE EXCEPTION 'requested_space_manifest must contain exactly the v1 material keys'
            USING ERRCODE = '22023';
    END IF;

    FOREACH manifest_text_key IN ARRAY ARRAY[
        'provider_identifier',
        'model_identifier',
        'model_revision',
        'modality_code',
        'input_role_code',
        'instruction_template_hash',
        'pooling_strategy_code',
        'normalization_strategy_code',
        'numeric_precision_code',
        'distance_metric_code',
        'preprocessing_policy_hash'
    ] LOOP
        IF jsonb_typeof(requested_space_manifest -> manifest_text_key) IS DISTINCT FROM 'string' THEN
            RAISE EXCEPTION 'manifest field % must be a JSON string', manifest_text_key
                USING ERRCODE = '22023';
        END IF;
        IF requested_space_manifest ->> manifest_text_key = ''
           OR btrim(requested_space_manifest ->> manifest_text_key) <> requested_space_manifest ->> manifest_text_key
           OR requested_space_manifest ->> manifest_text_key ~ '[[:cntrl:]]' THEN
            RAISE EXCEPTION 'manifest field % must be printable, non-empty, and have no outer whitespace', manifest_text_key
                USING ERRCODE = '22023';
        END IF;
    END LOOP;

    IF jsonb_typeof(requested_space_manifest -> 'vector_dimension') IS DISTINCT FROM 'number' THEN
        RAISE EXCEPTION 'manifest field vector_dimension must be a JSON number'
            USING ERRCODE = '22023';
    END IF;

    manifest_vector_dimension := (requested_space_manifest ->> 'vector_dimension')::numeric;
    IF manifest_vector_dimension <> trunc(manifest_vector_dimension)
       OR manifest_vector_dimension <= 0
       OR manifest_vector_dimension > 4294967295 THEN
        RAISE EXCEPTION 'manifest field vector_dimension must be an integer in the Rust u32 range'
            USING ERRCODE = '22023';
    END IF;

    manifest_provider_identifier := requested_space_manifest ->> 'provider_identifier';
    manifest_model_identifier := requested_space_manifest ->> 'model_identifier';
    manifest_model_revision := requested_space_manifest ->> 'model_revision';
    manifest_modality_code := requested_space_manifest ->> 'modality_code';
    manifest_input_role_code := requested_space_manifest ->> 'input_role_code';
    manifest_instruction_template_hash := requested_space_manifest ->> 'instruction_template_hash';
    manifest_pooling_strategy_code := requested_space_manifest ->> 'pooling_strategy_code';
    manifest_normalization_strategy_code := requested_space_manifest ->> 'normalization_strategy_code';
    manifest_numeric_precision_code := requested_space_manifest ->> 'numeric_precision_code';
    manifest_distance_metric_code := requested_space_manifest ->> 'distance_metric_code';
    manifest_preprocessing_policy_hash := requested_space_manifest ->> 'preprocessing_policy_hash';

    IF manifest_instruction_template_hash !~ '^sha256:[0-9a-f]{64}$'
       OR manifest_preprocessing_policy_hash !~ '^sha256:[0-9a-f]{64}$' THEN
        RAISE EXCEPTION 'manifest hash fields must be sha256:<64 lowercase hexadecimal characters>'
            USING ERRCODE = '22023';
    END IF;

    fingerprint_payload :=
        convert_to('embedrelay-space-manifest-v1', 'UTF8') || decode('00', 'hex');
    fingerprint_payload := fingerprint_payload
        || convert_to(octet_length(convert_to(manifest_provider_identifier, 'UTF8'))::text || ':' || manifest_provider_identifier, 'UTF8')
        || convert_to(octet_length(convert_to(manifest_model_identifier, 'UTF8'))::text || ':' || manifest_model_identifier, 'UTF8')
        || convert_to(octet_length(convert_to(manifest_model_revision, 'UTF8'))::text || ':' || manifest_model_revision, 'UTF8')
        || convert_to(octet_length(convert_to(manifest_modality_code, 'UTF8'))::text || ':' || manifest_modality_code, 'UTF8')
        || convert_to(octet_length(convert_to(manifest_input_role_code, 'UTF8'))::text || ':' || manifest_input_role_code, 'UTF8')
        || convert_to(octet_length(convert_to(manifest_instruction_template_hash, 'UTF8'))::text || ':' || manifest_instruction_template_hash, 'UTF8')
        || convert_to(octet_length(convert_to(manifest_pooling_strategy_code, 'UTF8'))::text || ':' || manifest_pooling_strategy_code, 'UTF8')
        || convert_to(octet_length(convert_to(manifest_normalization_strategy_code, 'UTF8'))::text || ':' || manifest_normalization_strategy_code, 'UTF8')
        || convert_to(octet_length(convert_to(manifest_vector_dimension::bigint::text, 'UTF8'))::text || ':' || manifest_vector_dimension::bigint::text, 'UTF8')
        || convert_to(octet_length(convert_to(manifest_numeric_precision_code, 'UTF8'))::text || ':' || manifest_numeric_precision_code, 'UTF8')
        || convert_to(octet_length(convert_to(manifest_distance_metric_code, 'UTF8'))::text || ':' || manifest_distance_metric_code, 'UTF8')
        || convert_to(octet_length(convert_to(manifest_preprocessing_policy_hash, 'UTF8'))::text || ':' || manifest_preprocessing_policy_hash, 'UTF8');

    computed_space_fingerprint := 'sha256:' || encode(sha256(fingerprint_payload), 'hex');
    IF requested_space_fingerprint IS DISTINCT FROM computed_space_fingerprint THEN
        RAISE EXCEPTION 'requested_space_fingerprint does not match canonical manifest material'
            USING ERRCODE = '22023';
    END IF;

    registration_audit_event_id := embedrelay_registry.register_tenant_space(
        registration_actor_id,
        requested_space_fingerprint
    );

    INSERT INTO embedrelay_registry.embedding_space_manifest (
        space_fingerprint,
        manifest_version_code,
        provider_identifier,
        model_identifier,
        model_revision,
        modality_code,
        input_role_code,
        instruction_template_hash,
        pooling_strategy_code,
        normalization_strategy_code,
        vector_dimension,
        numeric_precision_code,
        distance_metric_code,
        preprocessing_policy_hash
    ) VALUES (
        requested_space_fingerprint,
        'embedding-space-manifest-v1',
        manifest_provider_identifier,
        manifest_model_identifier,
        manifest_model_revision,
        manifest_modality_code,
        manifest_input_role_code,
        manifest_instruction_template_hash,
        manifest_pooling_strategy_code,
        manifest_normalization_strategy_code,
        manifest_vector_dimension::bigint,
        manifest_numeric_precision_code,
        manifest_distance_metric_code,
        manifest_preprocessing_policy_hash
    )
    ON CONFLICT (space_fingerprint) DO NOTHING;

    IF NOT EXISTS (
        SELECT 1
          FROM embedrelay_registry.embedding_space_manifest AS stored_manifest
         WHERE stored_manifest.space_fingerprint = requested_space_fingerprint
           AND stored_manifest.manifest_version_code = 'embedding-space-manifest-v1'
           AND stored_manifest.provider_identifier = manifest_provider_identifier
           AND stored_manifest.model_identifier = manifest_model_identifier
           AND stored_manifest.model_revision = manifest_model_revision
           AND stored_manifest.modality_code = manifest_modality_code
           AND stored_manifest.input_role_code = manifest_input_role_code
           AND stored_manifest.instruction_template_hash = manifest_instruction_template_hash
           AND stored_manifest.pooling_strategy_code = manifest_pooling_strategy_code
           AND stored_manifest.normalization_strategy_code = manifest_normalization_strategy_code
           AND stored_manifest.vector_dimension = manifest_vector_dimension::bigint
           AND stored_manifest.numeric_precision_code = manifest_numeric_precision_code
           AND stored_manifest.distance_metric_code = manifest_distance_metric_code
           AND stored_manifest.preprocessing_policy_hash = manifest_preprocessing_policy_hash
    ) THEN
        RAISE EXCEPTION 'canonical manifest catalog conflict for requested fingerprint'
            USING ERRCODE = '23514';
    END IF;

    RETURN registration_audit_event_id;
END
$function$;

REVOKE ALL ON TABLE embedrelay_registry.embedding_space_manifest FROM PUBLIC;
REVOKE ALL ON FUNCTION embedrelay_registry.register_tenant_space_manifest(uuid, text, jsonb) FROM PUBLIC;

COMMENT ON TABLE embedrelay_registry.embedding_space_manifest IS
    'Immutable v1 canonical embedding-space material keyed once by the exact sha256:<digest> fingerprint; tenant visibility is derived through tenant_space_registry RLS.';
COMMENT ON CONSTRAINT tenant_space_registry_manifest_reference ON embedrelay_registry.tenant_space_registry IS
    'Every committed tenant registration must reference a persisted canonical manifest; the deferred check allows audit-first registration and manifest materialization in one transaction.';
COMMENT ON FUNCTION embedrelay_registry.register_tenant_space_manifest(uuid, text, jsonb) IS
    'Validates the exact v1 manifest schema, recomputes the Rust-compatible SHA-256 fingerprint with byte-length framing, creates audit plus tenant registration, and insert-or-matches the immutable canonical manifest in one transaction.';

COMMIT;
