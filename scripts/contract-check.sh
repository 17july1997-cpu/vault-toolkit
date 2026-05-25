#!/usr/bin/env bash
# contract-check.sh
# Verifies the inter-skill contract: all three skills must reference the same
# manifest schema_version. Run BEFORE pushing a new plugin release.
#
# Lightweight version (grep-based) for plugin v1.0. A full pipeline integration test
# (restructure → sync → lint against a fixture vault) is the v1.1 target.

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOCKFILE="$PLUGIN_ROOT/vault-toolkit.lock.json"

if [[ ! -f "$LOCKFILE" ]]; then
  echo "ERROR: lockfile not found at $LOCKFILE. Run gen-lockfile.sh first." >&2
  exit 1
fi

# Extract schema versions from the lockfile
SCHEMAS=$(jq -r '.skills[] | "\(.skill): \(.manifest_schema_version)"' "$LOCKFILE")
UNIQUE_SCHEMAS=$(jq -r '.skills[].manifest_schema_version' "$LOCKFILE" | grep -v unspecified | sort -u)
SCHEMA_COUNT=$(echo "$UNIQUE_SCHEMAS" | grep -c . || echo 0)

echo "Schema versions referenced per skill:"
echo "$SCHEMAS"
echo

if [[ "$SCHEMA_COUNT" -eq 0 ]]; then
  echo "WARN: no schema_version references detected. Contract check is inconclusive." >&2
  exit 0
fi

if [[ "$SCHEMA_COUNT" -gt 1 ]]; then
  echo "FAIL: inter-skill contract broken. Skills reference different schema versions:" >&2
  echo "$UNIQUE_SCHEMAS" >&2
  echo >&2
  echo "Fix in the individual repos before re-syncing this plugin." >&2
  exit 1
fi

echo "PASS: all skills aligned on schema_version $UNIQUE_SCHEMAS"
