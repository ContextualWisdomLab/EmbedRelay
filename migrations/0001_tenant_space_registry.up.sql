BEGIN;

CREATE SCHEMA embedrelay_registry;
REVOKE ALL ON SCHEMA embedrelay_registry FROM PUBLIC;

CREATE TABLE embedrelay_registry.tenant_space_registry (
    tenant_space_record_id uuid PRIMARY KEY DEFAULT uuidv7(),
    tenant_id uuid NOT NULL,
    space_fingerprint text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT tenant_space_registry_fingerprint_format
        CHECK (space_fingerprint ~ '^sha256:[0-9a-f]{64}$'),
    CONSTRAINT tenant_space_registry_identity_key
        UNIQUE (tenant_id, space_fingerprint)
);

CREATE TABLE embedrelay_registry.space_registration_audit (
    audit_event_id uuid PRIMARY KEY DEFAULT uuidv7(),
    tenant_id uuid NOT NULL,
    space_fingerprint text NOT NULL,
    actor_id uuid NOT NULL,
    action_code text NOT NULL,
    occurred_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT space_registration_audit_fingerprint_format
        CHECK (space_fingerprint ~ '^sha256:[0-9a-f]{64}$'),
    CONSTRAINT space_registration_audit_action_code
        CHECK (action_code = 'space_registration_intent'),
    CONSTRAINT space_registration_audit_registry_reference
        FOREIGN KEY (tenant_id, space_fingerprint)
        REFERENCES embedrelay_registry.tenant_space_registry (tenant_id, space_fingerprint)
        DEFERRABLE INITIALLY DEFERRED
);

ALTER TABLE embedrelay_registry.tenant_space_registry ENABLE ROW LEVEL SECURITY;
ALTER TABLE embedrelay_registry.tenant_space_registry FORCE ROW LEVEL SECURITY;
ALTER TABLE embedrelay_registry.space_registration_audit ENABLE ROW LEVEL SECURITY;
ALTER TABLE embedrelay_registry.space_registration_audit FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_space_registry_tenant_isolation
    ON embedrelay_registry.tenant_space_registry
    FOR ALL
    TO PUBLIC
    USING (
        tenant_id = nullif(current_setting('embedrelay.tenant_id', true), '')::uuid
    )
    WITH CHECK (
        tenant_id = nullif(current_setting('embedrelay.tenant_id', true), '')::uuid
    );

CREATE POLICY space_registration_audit_tenant_isolation
    ON embedrelay_registry.space_registration_audit
    FOR ALL
    TO PUBLIC
    USING (
        tenant_id = nullif(current_setting('embedrelay.tenant_id', true), '')::uuid
    )
    WITH CHECK (
        tenant_id = nullif(current_setting('embedrelay.tenant_id', true), '')::uuid
    );

CREATE FUNCTION embedrelay_registry.reject_registry_mutation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog
AS $function$
BEGIN
    RAISE EXCEPTION 'EmbedRelay registry and audit records are append-only'
        USING ERRCODE = '55000';
END
$function$;

CREATE TRIGGER tenant_space_registry_append_only_rows
BEFORE UPDATE OR DELETE
ON embedrelay_registry.tenant_space_registry
FOR EACH ROW
EXECUTE FUNCTION embedrelay_registry.reject_registry_mutation();

CREATE TRIGGER tenant_space_registry_append_only_truncate
BEFORE TRUNCATE
ON embedrelay_registry.tenant_space_registry
FOR EACH STATEMENT
EXECUTE FUNCTION embedrelay_registry.reject_registry_mutation();

CREATE TRIGGER space_registration_audit_append_only_rows
BEFORE UPDATE OR DELETE
ON embedrelay_registry.space_registration_audit
FOR EACH ROW
EXECUTE FUNCTION embedrelay_registry.reject_registry_mutation();

CREATE TRIGGER space_registration_audit_append_only_truncate
BEFORE TRUNCATE
ON embedrelay_registry.space_registration_audit
FOR EACH STATEMENT
EXECUTE FUNCTION embedrelay_registry.reject_registry_mutation();

CREATE FUNCTION embedrelay_registry.register_tenant_space(
    registration_actor_id uuid,
    requested_space_fingerprint text
)
RETURNS uuid
LANGUAGE plpgsql
SET search_path = pg_catalog
AS $function$
DECLARE
    effective_tenant_setting text;
    effective_tenant_id uuid;
    registration_audit_event_id uuid;
BEGIN
    effective_tenant_setting := current_setting('embedrelay.tenant_id', true);
    IF effective_tenant_setting IS NULL OR effective_tenant_setting = '' THEN
        RAISE EXCEPTION 'embedrelay.tenant_id must be set for tenant registration'
            USING ERRCODE = '42501';
    END IF;

    effective_tenant_id := effective_tenant_setting::uuid;

    IF registration_actor_id IS NULL THEN
        RAISE EXCEPTION 'registration_actor_id must be present'
            USING ERRCODE = '22004';
    END IF;

    IF requested_space_fingerprint IS NULL
       OR requested_space_fingerprint !~ '^sha256:[0-9a-f]{64}$' THEN
        RAISE EXCEPTION 'requested_space_fingerprint must be sha256:<64 lowercase hexadecimal characters>'
            USING ERRCODE = '22023';
    END IF;

    INSERT INTO embedrelay_registry.space_registration_audit (
        tenant_id,
        space_fingerprint,
        actor_id,
        action_code
    ) VALUES (
        effective_tenant_id,
        requested_space_fingerprint,
        registration_actor_id,
        'space_registration_intent'
    )
    RETURNING audit_event_id INTO registration_audit_event_id;

    INSERT INTO embedrelay_registry.tenant_space_registry (
        tenant_id,
        space_fingerprint
    ) VALUES (
        effective_tenant_id,
        requested_space_fingerprint
    );

    RETURN registration_audit_event_id;
END
$function$;

REVOKE ALL ON ALL TABLES IN SCHEMA embedrelay_registry FROM PUBLIC;
REVOKE ALL ON FUNCTION embedrelay_registry.reject_registry_mutation() FROM PUBLIC;
REVOKE ALL ON FUNCTION embedrelay_registry.register_tenant_space(uuid, text) FROM PUBLIC;

COMMENT ON SCHEMA embedrelay_registry IS
    'EmbedRelay tenant-scoped immutable embedding-space registry and durable audit boundary.';
COMMENT ON TABLE embedrelay_registry.tenant_space_registry IS
    'Immutable tenant-to-space registrations keyed by the exact canonical sha256:<digest> space fingerprint. Duplicate registration is rejected; this is intentionally not an UPSERT contract.';
COMMENT ON TABLE embedrelay_registry.space_registration_audit IS
    'Append-only durable audit intents keyed by the exact canonical sha256:<digest> space fingerprint. The deferred registry reference lets audit insertion precede registry visibility in one transaction.';
COMMENT ON FUNCTION embedrelay_registry.register_tenant_space(uuid, text) IS
    'Registers one tenant-space item transactionally without stripping or reconstructing the canonical sha256:<digest> fingerprint. The audit intent is inserted first; a duplicate/concurrent unique violation rolls the audit row back with the statement.';

COMMIT;
