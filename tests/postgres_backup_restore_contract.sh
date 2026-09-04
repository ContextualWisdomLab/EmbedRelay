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

# The registry and manifest contracts run first and leave both migrations
# reapplied. Seed two tenant-isolated canonical manifests so the backup must
# preserve full identity material, registration/audit state, ACLs, and RLS.
first_tenant="017f22e2-79b0-7cc3-98c4-dc0c0c0c0750"
first_actor="017f22e2-79b0-7cc3-98c4-dc0c0c0c0751"
first_fingerprint="sha256:d105d04ca1cbdf6d8ba00dec0be676045e76059d16e4de404bd71a27d22bccb1"
second_tenant="017f22e2-79b0-7cc3-98c4-dc0c0c0c0752"
second_actor="017f22e2-79b0-7cc3-98c4-dc0c0c0c0753"
second_fingerprint="sha256:dc1c20712bd1862757d15f67a08bb99472a2a15de6f74cda2462e641a892b1ec"
outsider_tenant="017f22e2-79b0-7cc3-98c4-dc0c0c0c0754"

psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<SQL
SELECT set_config('embedrelay.tenant_id', '${first_tenant}', false);
SELECT embedrelay_registry.register_tenant_space_manifest(
  '${first_actor}'::uuid,
  '${first_fingerprint}',
  '{
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
  }'::jsonb
);
SELECT set_config('embedrelay.tenant_id', '${second_tenant}', false);
SELECT embedrelay_registry.register_tenant_space_manifest(
  '${second_actor}'::uuid,
  '${second_fingerprint}',
  '{
    "provider_identifier":"example_provider",
    "model_identifier":"example_model",
    "model_revision":"revision_2",
    "modality_code":"text",
    "input_role_code":"document",
    "instruction_template_hash":"sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    "pooling_strategy_code":"mean_pooling",
    "normalization_strategy_code":"l2",
    "vector_dimension":16,
    "numeric_precision_code":"float32",
    "distance_metric_code":"cosine",
    "preprocessing_policy_hash":"sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
  }'::jsonb
);
SQL

first_registry_id="$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -tAc \
  "SELECT tenant_space_record_id FROM embedrelay_registry.tenant_space_registry WHERE tenant_id='${first_tenant}'::uuid AND space_fingerprint='${first_fingerprint}';")"
first_audit_id="$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -tAc \
  "SELECT audit_event_id FROM embedrelay_registry.space_registration_audit WHERE tenant_id='${first_tenant}'::uuid AND space_fingerprint='${first_fingerprint}';")"
second_registry_id="$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -tAc \
  "SELECT tenant_space_record_id FROM embedrelay_registry.tenant_space_registry WHERE tenant_id='${second_tenant}'::uuid AND space_fingerprint='${second_fingerprint}';")"
second_audit_id="$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -tAc \
  "SELECT audit_event_id FROM embedrelay_registry.space_registration_audit WHERE tenant_id='${second_tenant}'::uuid AND space_fingerprint='${second_fingerprint}';")"

for identity in "$first_registry_id" "$first_audit_id" "$second_registry_id" "$second_audit_id"; do
  if [[ -z "$identity" ]]; then
    echo "backup acceptance fixture did not create all durable registry/audit identities" >&2
    exit 1
  fi
done

source_counts="$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -tAc \
  "SELECT (SELECT count(*) FROM embedrelay_registry.tenant_space_registry)::text || ':' || (SELECT count(*) FROM embedrelay_registry.space_registration_audit)::text || ':' || (SELECT count(*) FROM embedrelay_registry.embedding_space_manifest)::text;")"
if [[ "$source_counts" != "2:2:2" ]]; then
  echo "backup source must contain exactly two registry, two audit, and two manifest rows; got $source_counts" >&2
  exit 1
fi

first_manifest_revision="$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -tAc \
  "SELECT model_revision FROM embedrelay_registry.embedding_space_manifest WHERE space_fingerprint='${first_fingerprint}';")"
second_manifest_revision="$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -tAc \
  "SELECT model_revision FROM embedrelay_registry.embedding_space_manifest WHERE space_fingerprint='${second_fingerprint}';")"
if [[ "$first_manifest_revision" != "revision_1" || "$second_manifest_revision" != "revision_2" ]]; then
  echo "backup source canonical manifest material is incomplete" >&2
  exit 1
fi

# Keep ACLs in the dump. The prior contracts deliberately provision the
# cluster-level embedrelay_test_client role and grant only the privileges under
# test so the restored database must retain the same contract surface.
backup_started_ns="$(date +%s%N)"
pg_dump "$DATABASE_URL" \
  --format=custom \
  --no-owner \
  --file="$backup_path"
backup_finished_ns="$(date +%s%N)"
backup_elapsed_ms="$(( (backup_finished_ns - backup_started_ns) / 1000000 ))"

psql "$DATABASE_URL" -v ON_ERROR_STOP=1 \
  -c "DROP DATABASE IF EXISTS \"$restore_database\" WITH (FORCE);"
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 \
  -c "CREATE DATABASE \"$restore_database\" TEMPLATE template0;"

restore_started_ns="$(date +%s%N)"
pg_restore \
  --exit-on-error \
  --no-owner \
  --dbname="$restore_url" \
  "$backup_path"
restore_finished_ns="$(date +%s%N)"
restore_elapsed_ms="$(( (restore_finished_ns - restore_started_ns) / 1000000 ))"

restored_first_registry_id="$(psql "$restore_url" -v ON_ERROR_STOP=1 -tAc \
  "SELECT tenant_space_record_id FROM embedrelay_registry.tenant_space_registry WHERE tenant_id='${first_tenant}'::uuid AND space_fingerprint='${first_fingerprint}';")"
restored_first_audit_id="$(psql "$restore_url" -v ON_ERROR_STOP=1 -tAc \
  "SELECT audit_event_id FROM embedrelay_registry.space_registration_audit WHERE tenant_id='${first_tenant}'::uuid AND space_fingerprint='${first_fingerprint}';")"
restored_second_registry_id="$(psql "$restore_url" -v ON_ERROR_STOP=1 -tAc \
  "SELECT tenant_space_record_id FROM embedrelay_registry.tenant_space_registry WHERE tenant_id='${second_tenant}'::uuid AND space_fingerprint='${second_fingerprint}';")"
restored_second_audit_id="$(psql "$restore_url" -v ON_ERROR_STOP=1 -tAc \
  "SELECT audit_event_id FROM embedrelay_registry.space_registration_audit WHERE tenant_id='${second_tenant}'::uuid AND space_fingerprint='${second_fingerprint}';")"
restored_first_manifest_revision="$(psql "$restore_url" -v ON_ERROR_STOP=1 -tAc \
  "SELECT model_revision FROM embedrelay_registry.embedding_space_manifest WHERE space_fingerprint='${first_fingerprint}';")"
restored_second_manifest_revision="$(psql "$restore_url" -v ON_ERROR_STOP=1 -tAc \
  "SELECT model_revision FROM embedrelay_registry.embedding_space_manifest WHERE space_fingerprint='${second_fingerprint}';")"

if [[ "$restored_first_registry_id" != "$first_registry_id" || "$restored_first_audit_id" != "$first_audit_id" ]]; then
  echo "first tenant restored identities differ from backed-up identities" >&2
  exit 1
fi
if [[ "$restored_second_registry_id" != "$second_registry_id" || "$restored_second_audit_id" != "$second_audit_id" ]]; then
  echo "second tenant restored identities differ from backed-up identities" >&2
  exit 1
fi
if [[ "$restored_first_manifest_revision" != "$first_manifest_revision" || "$restored_second_manifest_revision" != "$second_manifest_revision" ]]; then
  echo "restored canonical manifest material differs from backup source" >&2
  exit 1
fi

restored_counts="$(psql "$restore_url" -v ON_ERROR_STOP=1 -tAc \
  "SELECT (SELECT count(*) FROM embedrelay_registry.tenant_space_registry)::text || ':' || (SELECT count(*) FROM embedrelay_registry.space_registration_audit)::text || ':' || (SELECT count(*) FROM embedrelay_registry.embedding_space_manifest)::text;")"
if [[ "$restored_counts" != "$source_counts" ]]; then
  echo "restored registry/audit/manifest counts differ from backup source: source=$source_counts restored=$restored_counts" >&2
  exit 1
fi

psql "$restore_url" -v ON_ERROR_STOP=1 <<SQL
DO \$\$
DECLARE
  registry_rls boolean;
  registry_forced boolean;
  audit_rls boolean;
  audit_forced boolean;
  manifest_rls boolean;
  manifest_forced boolean;
BEGIN
  SELECT relrowsecurity, relforcerowsecurity
    INTO registry_rls, registry_forced
    FROM pg_class
   WHERE oid = 'embedrelay_registry.tenant_space_registry'::regclass;
  SELECT relrowsecurity, relforcerowsecurity
    INTO audit_rls, audit_forced
    FROM pg_class
   WHERE oid = 'embedrelay_registry.space_registration_audit'::regclass;
  SELECT relrowsecurity, relforcerowsecurity
    INTO manifest_rls, manifest_forced
    FROM pg_class
   WHERE oid = 'embedrelay_registry.embedding_space_manifest'::regclass;

  IF NOT registry_rls OR NOT registry_forced
     OR NOT audit_rls OR NOT audit_forced
     OR NOT manifest_rls OR NOT manifest_forced THEN
    RAISE EXCEPTION 'restored registry/audit/manifest tables must retain enabled and forced RLS';
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
  IF NOT EXISTS (
    SELECT 1
      FROM pg_trigger
     WHERE tgrelid = 'embedrelay_registry.embedding_space_manifest'::regclass
       AND tgname = 'embedding_space_manifest_append_only_rows'
       AND tgenabled <> 'D'
  ) THEN
    RAISE EXCEPTION 'restored manifest append-only trigger is missing or disabled';
  END IF;

  IF obj_description('embedrelay_registry.tenant_space_registry'::regclass, 'pg_class') IS NULL
     OR obj_description('embedrelay_registry.space_registration_audit'::regclass, 'pg_class') IS NULL
     OR obj_description('embedrelay_registry.embedding_space_manifest'::regclass, 'pg_class') IS NULL THEN
    RAISE EXCEPTION 'restored registry/audit/manifest table comments must survive backup restore';
  END IF;

  IF NOT has_schema_privilege('embedrelay_test_client', 'embedrelay_registry', 'USAGE')
     OR NOT has_table_privilege('embedrelay_test_client', 'embedrelay_registry.tenant_space_registry', 'SELECT')
     OR NOT has_table_privilege('embedrelay_test_client', 'embedrelay_registry.space_registration_audit', 'SELECT')
     OR NOT has_table_privilege('embedrelay_test_client', 'embedrelay_registry.embedding_space_manifest', 'SELECT')
     OR NOT has_function_privilege('embedrelay_test_client', 'embedrelay_registry.register_tenant_space_manifest(uuid,text,jsonb)', 'EXECUTE') THEN
    RAISE EXCEPTION 'restored application-role privileges differ from the backed-up contract database';
  END IF;
END
\$\$;

SET ROLE embedrelay_test_client;
SELECT set_config('embedrelay.tenant_id', '${first_tenant}', false);
DO \$\$
BEGIN
  IF (SELECT count(*) FROM embedrelay_registry.tenant_space_registry) <> 1 THEN
    RAISE EXCEPTION 'first restored tenant must see exactly one registry row';
  END IF;
  IF (SELECT count(*) FROM embedrelay_registry.space_registration_audit) <> 1 THEN
    RAISE EXCEPTION 'first restored tenant must see exactly one audit row';
  END IF;
  IF (SELECT count(*) FROM embedrelay_registry.embedding_space_manifest) <> 1 THEN
    RAISE EXCEPTION 'first restored tenant must see exactly one registered canonical manifest';
  END IF;

  BEGIN
    UPDATE embedrelay_registry.tenant_space_registry
       SET space_fingerprint = space_fingerprint;
    RAISE EXCEPTION 'restored append-only registry unexpectedly allowed update';
  EXCEPTION
    WHEN SQLSTATE '55000' THEN NULL;
  END;

  BEGIN
    UPDATE embedrelay_registry.space_registration_audit
       SET action_code = action_code;
    RAISE EXCEPTION 'restored append-only audit unexpectedly allowed update';
  EXCEPTION
    WHEN SQLSTATE '55000' THEN NULL;
  END;

  BEGIN
    UPDATE embedrelay_registry.embedding_space_manifest
       SET model_revision = model_revision;
    RAISE EXCEPTION 'restored append-only manifest unexpectedly allowed update';
  EXCEPTION
    WHEN SQLSTATE '55000' THEN NULL;
  END;
END
\$\$;

SELECT set_config('embedrelay.tenant_id', '${second_tenant}', false);
DO \$\$
BEGIN
  IF (SELECT count(*) FROM embedrelay_registry.tenant_space_registry) <> 1 THEN
    RAISE EXCEPTION 'second restored tenant must see exactly one registry row';
  END IF;
  IF (SELECT count(*) FROM embedrelay_registry.space_registration_audit) <> 1 THEN
    RAISE EXCEPTION 'second restored tenant must see exactly one audit row';
  END IF;
  IF (SELECT count(*) FROM embedrelay_registry.embedding_space_manifest) <> 1 THEN
    RAISE EXCEPTION 'second restored tenant must see exactly one registered canonical manifest';
  END IF;
END
\$\$;

SELECT set_config('embedrelay.tenant_id', '${outsider_tenant}', false);
DO \$\$
BEGIN
  IF (SELECT count(*) FROM embedrelay_registry.tenant_space_registry) <> 0 THEN
    RAISE EXCEPTION 'restored RLS leaked another tenant registry row';
  END IF;
  IF (SELECT count(*) FROM embedrelay_registry.space_registration_audit) <> 0 THEN
    RAISE EXCEPTION 'restored RLS leaked another tenant audit row';
  END IF;
  IF (SELECT count(*) FROM embedrelay_registry.embedding_space_manifest) <> 0 THEN
    RAISE EXCEPTION 'restored RLS leaked canonical manifest material to an unregistered tenant';
  END IF;
END
\$\$;
RESET ROLE;
SQL

backup_bytes="$(wc -c < "$backup_path" | tr -d ' ')"
if [[ "$backup_bytes" -le 0 ]]; then
  echo "backup artifact is empty" >&2
  exit 1
fi

printf 'PostgreSQL backup/restore acceptance passed: rows=%s backup_bytes=%s backup_ms=%s restore_ms=%s first_registry=%s second_registry=%s\n' \
  "$restored_counts" "$backup_bytes" "$backup_elapsed_ms" "$restore_elapsed_ms" \
  "$restored_first_registry_id" "$restored_second_registry_id"
