#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL must point at the PostgreSQL 18.6 test database}"

restore_database="embedrelay_restore_${RANDOM}_$$"
backup_dir="$(mktemp -d)"
backup_path="$backup_dir/embedrelay-registry.dump"

restore_url="$(python3 - "$DATABASE_URL" "$restore_database" <<'PY'
import sys
from urllib.parse import urlsplit, urlunsplit

source_url, restore_database = sys.argv[1:]
parts = urlsplit(source_url)
if parts.scheme not in {"postgres", "postgresql"}:
    raise SystemExit("DATABASE_URL must use the postgres/postgresql URL scheme")
print(urlunsplit((parts.scheme, parts.netloc, f"/{restore_database}", parts.query, parts.fragment)))
PY
)"

cleanup() {
  set +e
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 \
    -c "DROP DATABASE IF EXISTS \"$restore_database\" WITH (FORCE);" >/dev/null 2>&1
  rm -rf "$backup_dir"
}
trap cleanup EXIT

# The registry contract runs first and leaves the up migration reapplied. Seed one
# immutable tenant-space registration whose exact identities must survive restore.
source_tenant="017f22e2-79b0-7cc3-98c4-dc0c0c0c0750"
source_actor="017f22e2-79b0-7cc3-98c4-dc0c0c0c0751"
source_fingerprint="$(printf 'd%.0s' {1..64})"

psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<SQL
SELECT set_config('embedrelay.tenant_id', '${source_tenant}', false);
SELECT embedrelay_registry.register_tenant_space(
  '${source_actor}'::uuid,
  '${source_fingerprint}'
);
SQL

original_registry_id="$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -tAc \
  "SELECT tenant_space_record_id FROM embedrelay_registry.tenant_space_registry WHERE tenant_id='${source_tenant}'::uuid AND space_fingerprint='${source_fingerprint}';")"
original_audit_id="$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -tAc \
  "SELECT audit_event_id FROM embedrelay_registry.space_registration_audit WHERE tenant_id='${source_tenant}'::uuid AND space_fingerprint='${source_fingerprint}';")"

if [[ -z "$original_registry_id" || -z "$original_audit_id" ]]; then
  echo "backup acceptance fixture did not create durable registry and audit identities" >&2
  exit 1
fi

pg_dump "$DATABASE_URL" \
  --format=custom \
  --no-owner \
  --no-privileges \
  --file="$backup_path"

psql "$DATABASE_URL" -v ON_ERROR_STOP=1 \
  -c "DROP DATABASE IF EXISTS \"$restore_database\" WITH (FORCE);"
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 \
  -c "CREATE DATABASE \"$restore_database\" TEMPLATE template0;"

pg_restore \
  --exit-on-error \
  --no-owner \
  --no-privileges \
  --dbname="$restore_url" \
  "$backup_path"

restored_registry_id="$(psql "$restore_url" -v ON_ERROR_STOP=1 -tAc \
  "SELECT tenant_space_record_id FROM embedrelay_registry.tenant_space_registry WHERE tenant_id='${source_tenant}'::uuid AND space_fingerprint='${source_fingerprint}';")"
restored_audit_id="$(psql "$restore_url" -v ON_ERROR_STOP=1 -tAc \
  "SELECT audit_event_id FROM embedrelay_registry.space_registration_audit WHERE tenant_id='${source_tenant}'::uuid AND space_fingerprint='${source_fingerprint}';")"

if [[ "$restored_registry_id" != "$original_registry_id" ]]; then
  echo "restored tenant registry identity differs from the backed-up identity" >&2
  exit 1
fi
if [[ "$restored_audit_id" != "$original_audit_id" ]]; then
  echo "restored audit identity differs from the backed-up identity" >&2
  exit 1
fi

psql "$restore_url" -v ON_ERROR_STOP=1 <<'SQL'
DO $$
DECLARE
  registry_rls boolean;
  registry_forced boolean;
  audit_rls boolean;
  audit_forced boolean;
BEGIN
  SELECT relrowsecurity, relforcerowsecurity
    INTO registry_rls, registry_forced
    FROM pg_class
   WHERE oid = 'embedrelay_registry.tenant_space_registry'::regclass;
  SELECT relrowsecurity, relforcerowsecurity
    INTO audit_rls, audit_forced
    FROM pg_class
   WHERE oid = 'embedrelay_registry.space_registration_audit'::regclass;

  IF NOT registry_rls OR NOT registry_forced OR NOT audit_rls OR NOT audit_forced THEN
    RAISE EXCEPTION 'restored registry/audit tables must retain enabled and forced RLS';
  END IF;

  IF NOT EXISTS (
    SELECT 1
      FROM pg_trigger
     WHERE tgrelid = 'embedrelay_registry.tenant_space_registry'::regclass
       AND tgname = 'tenant_space_registry_append_only_rows'
       AND tgenabled <> 'D'
  ) THEN
    RAISE EXCEPTION 'restored registry append-only trigger is missing or disabled';
  END IF;
  IF NOT EXISTS (
    SELECT 1
      FROM pg_trigger
     WHERE tgrelid = 'embedrelay_registry.space_registration_audit'::regclass
       AND tgname = 'space_registration_audit_append_only_rows'
       AND tgenabled <> 'D'
  ) THEN
    RAISE EXCEPTION 'restored audit append-only trigger is missing or disabled';
  END IF;
END
$$;

DO $create_role$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'embedrelay_restore_client') THEN
    CREATE ROLE embedrelay_restore_client NOLOGIN;
  END IF;
END
$create_role$;
ALTER ROLE embedrelay_restore_client
  NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOREPLICATION NOBYPASSRLS;
REVOKE ALL PRIVILEGES ON SCHEMA embedrelay_registry FROM embedrelay_restore_client;
REVOKE ALL PRIVILEGES
  ON embedrelay_registry.tenant_space_registry,
     embedrelay_registry.space_registration_audit
  FROM embedrelay_restore_client;
GRANT USAGE ON SCHEMA embedrelay_registry TO embedrelay_restore_client;
GRANT SELECT, UPDATE, DELETE
  ON embedrelay_registry.tenant_space_registry,
     embedrelay_registry.space_registration_audit
  TO embedrelay_restore_client;

SET ROLE embedrelay_restore_client;
SELECT set_config('embedrelay.tenant_id', '017f22e2-79b0-7cc3-98c4-dc0c0c0c0750', false);
DO $$
BEGIN
  IF (SELECT count(*) FROM embedrelay_registry.tenant_space_registry) <> 1 THEN
    RAISE EXCEPTION 'restored tenant must see exactly its durable registry row';
  END IF;
  IF (SELECT count(*) FROM embedrelay_registry.space_registration_audit) <> 1 THEN
    RAISE EXCEPTION 'restored tenant must see exactly its durable audit row';
  END IF;

  BEGIN
    UPDATE embedrelay_registry.tenant_space_registry
       SET space_fingerprint = space_fingerprint;
    RAISE EXCEPTION 'restored append-only registry unexpectedly allowed update';
  EXCEPTION
    WHEN SQLSTATE '55000' THEN NULL;
  END;
END
$$;

SELECT set_config('embedrelay.tenant_id', '017f22e2-79b0-7cc3-98c4-dc0c0c0c0752', false);
DO $$
BEGIN
  IF (SELECT count(*) FROM embedrelay_registry.tenant_space_registry) <> 0 THEN
    RAISE EXCEPTION 'restored RLS leaked another tenant registry row';
  END IF;
  IF (SELECT count(*) FROM embedrelay_registry.space_registration_audit) <> 0 THEN
    RAISE EXCEPTION 'restored RLS leaked another tenant audit row';
  END IF;
END
$$;
RESET ROLE;
SQL

printf 'PostgreSQL backup/restore acceptance passed: registry=%s audit=%s\n' \
  "$restored_registry_id" "$restored_audit_id"
