#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL must point at the PostgreSQL 18.6 test database}"

UP_MIGRATION="migrations/0001_tenant_space_registry.up.sql"
DOWN_MIGRATION="migrations/0001_tenant_space_registry.down.sql"

if [[ ! -f "$UP_MIGRATION" || ! -f "$DOWN_MIGRATION" ]]; then
  echo "PostgreSQL registry migrations are required before this contract can pass" >&2
  exit 1
fi

log_dir="$(mktemp -d)"
trap 'rm -rf "$log_dir"' EXIT

psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$UP_MIGRATION"

psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<'SQL'
DO $create_role$
BEGIN
  IF NOT EXISTS (
    SELECT 1
      FROM pg_roles
     WHERE rolname = 'embedrelay_test_client'
  ) THEN
    CREATE ROLE embedrelay_test_client NOLOGIN;
  END IF;
END
$create_role$;
ALTER ROLE embedrelay_test_client
  NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOREPLICATION NOBYPASSRLS;
REVOKE ALL PRIVILEGES ON SCHEMA embedrelay_registry FROM embedrelay_test_client;
REVOKE ALL PRIVILEGES
  ON embedrelay_registry.tenant_space_registry,
     embedrelay_registry.space_registration_audit
  FROM embedrelay_test_client;
REVOKE ALL PRIVILEGES
  ON FUNCTION embedrelay_registry.register_tenant_space(uuid, text)
  FROM embedrelay_test_client;
GRANT USAGE ON SCHEMA embedrelay_registry TO embedrelay_test_client;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE
  ON embedrelay_registry.tenant_space_registry,
     embedrelay_registry.space_registration_audit
  TO embedrelay_test_client;
GRANT EXECUTE ON FUNCTION embedrelay_registry.register_tenant_space(uuid, text)
  TO embedrelay_test_client;

SET ROLE embedrelay_test_client;
DO $$
BEGIN
  BEGIN
    PERFORM embedrelay_registry.register_tenant_space(
      '017f22e2-79b0-7cc3-98c4-dc0c0c0c073b'::uuid,
      'sha256:' || repeat('a', 64)
    );
    RAISE EXCEPTION 'registration unexpectedly succeeded without tenant context';
  EXCEPTION
    WHEN insufficient_privilege THEN NULL;
  END;
END
$$;

SELECT set_config('embedrelay.tenant_id', '017f22e2-79b0-7cc3-98c4-dc0c0c0c0739', false);

DO $$
DECLARE
  first_event uuid;
  first_record uuid;
  first_fingerprint text := 'sha256:' || repeat('a', 64);
BEGIN
  BEGIN
    PERFORM embedrelay_registry.register_tenant_space(
      '017f22e2-79b0-7cc3-98c4-dc0c0c0c073b'::uuid,
      repeat('a', 64)
    );
    RAISE EXCEPTION 'bare fingerprint digest unexpectedly succeeded';
  EXCEPTION
    WHEN invalid_parameter_value THEN NULL;
  END;

  BEGIN
    PERFORM embedrelay_registry.register_tenant_space(
      '017f22e2-79b0-7cc3-98c4-dc0c0c0c073b'::uuid,
      upper(first_fingerprint)
    );
    RAISE EXCEPTION 'non-canonical fingerprint unexpectedly succeeded';
  EXCEPTION
    WHEN invalid_parameter_value THEN NULL;
  END;

  first_event := embedrelay_registry.register_tenant_space(
    '017f22e2-79b0-7cc3-98c4-dc0c0c0c073b'::uuid,
    first_fingerprint
  );

  SELECT tenant_space_record_id
    INTO first_record
    FROM embedrelay_registry.tenant_space_registry
   WHERE space_fingerprint = first_fingerprint;

  IF uuid_extract_version(first_event) IS DISTINCT FROM 7 THEN
    RAISE EXCEPTION 'audit event must be UUIDv7';
  END IF;
  IF uuid_extract_version(first_record) IS DISTINCT FROM 7 THEN
    RAISE EXCEPTION 'registry record must be UUIDv7';
  END IF;
  IF (SELECT count(*) FROM embedrelay_registry.tenant_space_registry) <> 1 THEN
    RAISE EXCEPTION 'tenant registry must expose exactly one accepted registration';
  END IF;
  IF (SELECT count(*) FROM embedrelay_registry.space_registration_audit) <> 1 THEN
    RAISE EXCEPTION 'accepted registration must have exactly one durable audit event';
  END IF;

  BEGIN
    PERFORM embedrelay_registry.register_tenant_space(
      '017f22e2-79b0-7cc3-98c4-dc0c0c0c073b'::uuid,
      first_fingerprint
    );
    RAISE EXCEPTION 'duplicate registration unexpectedly succeeded';
  EXCEPTION
    WHEN unique_violation THEN NULL;
  END;

  IF (SELECT count(*) FROM embedrelay_registry.space_registration_audit) <> 1 THEN
    RAISE EXCEPTION 'duplicate registration must not leave a duplicate audit event';
  END IF;

  BEGIN
    INSERT INTO embedrelay_registry.tenant_space_registry
      (tenant_id, space_fingerprint)
    VALUES
      ('017f22e2-79b0-7cc3-98c4-dc0c0c0c073a'::uuid, 'sha256:' || repeat('b', 64));
    RAISE EXCEPTION 'cross-tenant insert unexpectedly succeeded';
  EXCEPTION
    WHEN insufficient_privilege THEN NULL;
  END;

  BEGIN
    UPDATE embedrelay_registry.tenant_space_registry
       SET space_fingerprint = space_fingerprint;
    RAISE EXCEPTION 'registry update unexpectedly succeeded';
  EXCEPTION
    WHEN SQLSTATE '55000' THEN NULL;
  END;

  BEGIN
    DELETE FROM embedrelay_registry.tenant_space_registry;
    RAISE EXCEPTION 'registry delete unexpectedly succeeded';
  EXCEPTION
    WHEN SQLSTATE '55000' THEN NULL;
  END;

  BEGIN
    TRUNCATE TABLE embedrelay_registry.tenant_space_registry;
    RAISE EXCEPTION 'registry truncate unexpectedly succeeded';
  EXCEPTION
    WHEN SQLSTATE '55000' THEN NULL;
  END;

  BEGIN
    UPDATE embedrelay_registry.space_registration_audit
       SET action_code = action_code;
    RAISE EXCEPTION 'audit update unexpectedly succeeded';
  EXCEPTION
    WHEN SQLSTATE '55000' THEN NULL;
  END;

  BEGIN
    DELETE FROM embedrelay_registry.space_registration_audit;
    RAISE EXCEPTION 'audit delete unexpectedly succeeded';
  EXCEPTION
    WHEN SQLSTATE '55000' THEN NULL;
  END;

  BEGIN
    TRUNCATE TABLE embedrelay_registry.space_registration_audit;
    RAISE EXCEPTION 'audit truncate unexpectedly succeeded';
  EXCEPTION
    WHEN SQLSTATE '55000' THEN NULL;
  END;
END
$$;

SELECT set_config('embedrelay.tenant_id', '017f22e2-79b0-7cc3-98c4-dc0c0c0c073a', false);
DO $$
BEGIN
  IF (SELECT count(*) FROM embedrelay_registry.tenant_space_registry) <> 0 THEN
    RAISE EXCEPTION 'row-level security leaked another tenant registry row';
  END IF;
  IF (SELECT count(*) FROM embedrelay_registry.space_registration_audit) <> 0 THEN
    RAISE EXCEPTION 'row-level security leaked another tenant audit row';
  END IF;
END
$$;
RESET ROLE;
SQL

race_tenant="017f22e2-79b0-7cc3-98c4-dc0c0c0c0740"
race_actor="017f22e2-79b0-7cc3-98c4-dc0c0c0c0741"
race_fingerprint="sha256:$(printf 'c%.0s' {1..64})"
race_sql="SET ROLE embedrelay_test_client; SELECT set_config('embedrelay.tenant_id', '${race_tenant}', false); SELECT embedrelay_registry.register_tenant_space('${race_actor}'::uuid, '${race_fingerprint}');"

set +e
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -c "$race_sql" >"$log_dir/race-one.log" 2>&1 &
pid_one=$!
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -c "$race_sql" >"$log_dir/race-two.log" 2>&1 &
pid_two=$!
wait "$pid_one"; status_one=$?
wait "$pid_two"; status_two=$?
set -e

if [[ $((status_one == 0 ? 1 : 0)) -eq $((status_two == 0 ? 1 : 0)) ]]; then
  cat "$log_dir/race-one.log" "$log_dir/race-two.log" >&2
  echo "concurrent identical registration must produce exactly one winner" >&2
  exit 1
fi

psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<SQL
SET ROLE embedrelay_test_client;
SELECT set_config('embedrelay.tenant_id', '${race_tenant}', false);
DO \$\$
BEGIN
  IF (SELECT count(*) FROM embedrelay_registry.tenant_space_registry WHERE space_fingerprint = '${race_fingerprint}') <> 1 THEN
    RAISE EXCEPTION 'concurrent registration must persist one registry row';
  END IF;
  IF (SELECT count(*) FROM embedrelay_registry.space_registration_audit WHERE space_fingerprint = '${race_fingerprint}') <> 1 THEN
    RAISE EXCEPTION 'losing concurrent registration must roll its audit intent back';
  END IF;
END
\$\$;
RESET ROLE;
SQL

if psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$DOWN_MIGRATION" >"$log_dir/rollback-denied.log" 2>&1; then
  echo "destructive rollback unexpectedly succeeded without explicit opt-in" >&2
  exit 1
fi

psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<SQL
SELECT set_config('embedrelay.allow_destructive_rollback', 'on', false);
\i ${DOWN_MIGRATION}
DO \$\$
BEGIN
  IF to_regnamespace('embedrelay_registry') IS NOT NULL THEN
    RAISE EXCEPTION 'rollback must remove the EmbedRelay registry schema';
  END IF;
END
\$\$;
SQL

psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$UP_MIGRATION"
reapplied="$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -tAc "SELECT to_regclass('embedrelay_registry.tenant_space_registry') IS NOT NULL;")"
if [[ "$reapplied" != "t" ]]; then
  echo "re-applied up migration did not recreate the tenant registry table" >&2
  exit 1
fi
