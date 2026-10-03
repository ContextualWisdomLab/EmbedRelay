BEGIN;

DO $destructive_rollback_gate$
BEGIN
    IF current_setting('embedrelay.allow_destructive_rollback', true) IS DISTINCT FROM 'on' THEN
        RAISE EXCEPTION 'destructive EmbedRelay registry rollback requires embedrelay.allow_destructive_rollback=on'
            USING ERRCODE = '55000';
    END IF;
END
$destructive_rollback_gate$;

DROP SCHEMA embedrelay_registry CASCADE;

COMMIT;
