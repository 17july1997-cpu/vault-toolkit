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
UNSPECIFIED_SKILLS=$(jq -r '.skills[] | select(.manifest_schema_version == "unspecified") | .skill' "$LOCKFILE")
DECLARED_SCHEMAS=$(jq -r '.skills[].manifest_schema_version' "$LOCKFILE" | grep -v unspecified | sort -u)
DECLARED_COUNT=$(echo "$DECLARED_SCHEMAS" | grep -c . || echo 0)

echo "Schema versions referenced per skill:"
echo "$SCHEMAS"
echo

# Codex R2 P0-1: fail on any unspecified skill. Every bundled skill must self-declare
# the manifest schema_version it produces OR consumes. Without this, a silent schema
# mismatch can ship through the gate.
if [[ -n "$UNSPECIFIED_SKILLS" ]]; then
  echo "FAIL: the following skill(s) did not self-declare a manifest schema_version:" >&2
  echo "$UNSPECIFIED_SKILLS" | sed 's/^/  - /' >&2
  echo >&2
  echo "Fix: add a line like 'Consumes manifest schema_version: \"X.Y\".' or" >&2
  echo "'Writes manifest schema_version: \"X.Y\".' to the SKILL.md or a references/ file" >&2
  echo "of each unspecified skill, then re-run gen-lockfile.sh." >&2
  exit 1
fi

if [[ "$DECLARED_COUNT" -eq 0 ]]; then
  echo "FAIL: no schema_version references detected anywhere. Contract check cannot verify alignment." >&2
  exit 1
fi

if [[ "$DECLARED_COUNT" -gt 1 ]]; then
  echo "FAIL: inter-skill contract broken. Skills reference different schema versions:" >&2
  echo "$DECLARED_SCHEMAS" >&2
  echo >&2
  echo "Fix in the individual repos before re-syncing this plugin." >&2
  exit 1
fi

echo "PASS: all skills aligned on schema_version $DECLARED_SCHEMAS"
