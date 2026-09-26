#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readme_path="$repository_root/README.md"
overview_path="$repository_root/docs/index.md"
baseline_path="$repository_root/docs/product-technical-gap-baseline.md"
failures=0

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    printf 'missing required file: %s\n' "$path" >&2
    failures=$((failures + 1))
  fi
}

require_text() {
  local path="$1"
  local text="$2"
  if [[ ! -f "$path" ]] || ! grep -Fq -- "$text" "$path"; then
    printf 'missing required text in %s: %s\n' "$path" "$text" >&2
    failures=$((failures + 1))
  fi
}

forbid_text() {
  local path="$1"
  local text="$2"
  if [[ -f "$path" ]] && grep -Fq -- "$text" "$path"; then
    printf 'forbidden customer-facing text in %s: %s\n' "$path" "$text" >&2
    failures=$((failures + 1))
  fi
}

require_file "$readme_path"
require_file "$overview_path"
require_file "$baseline_path"

require_text "$readme_path" "## Current status"
require_text "$readme_path" "No executable package or release is currently published."
require_text "$readme_path" "## Integration"
require_text "$readme_path" "## License"
require_text "$readme_path" 'No repository-level `LICENSE` is present.'
require_text "$readme_path" "## Support"
forbid_text "$readme_path" "## Repository governance"
forbid_text "$readme_path" ".github#"

require_text "$overview_path" "No executable package or release is currently published."
require_text "$overview_path" 'No repository-level `LICENSE` is present.'

for token in "PRD" "TRD" "UML" "ERD" "Context Map" "Gap" "Action" "Status" "License" "Release" "Pages"; do
  require_text "$baseline_path" "$token"
done

if (( failures > 0 )); then
  printf 'public documentation contract: %d failure(s)\n' "$failures" >&2
  exit 1
fi

printf 'public documentation contract: OK\n'
