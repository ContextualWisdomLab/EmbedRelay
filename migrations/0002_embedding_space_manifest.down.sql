BEGIN;

DO $rollback_guard$
BEGIN
    IF current_setting('embedrelay.allow_destructive_rollback', true) IS DISTINCT FROM 'on' THEN
        RAISE EXCEPTION 'set embedrelay.allow_destructive_rollback=on before removing canonical manifest persistence'
            USING ERRCODE = '55000';
    END IF;
END
$rollback_guard$;

ALTER TABLE embedrelay_registry.tenant_space_registry
    DROP CONSTRAINT tenant_space_registry_manifest_reference;

DROP FUNCTION embedrelay_registry.register_tenant_space_manifest(uuid, text, jsonb);
DROP TABLE embedrelay_registry.embedding_space_manifest;

COMMIT;
