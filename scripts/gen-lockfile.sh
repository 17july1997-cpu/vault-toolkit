#!/usr/bin/env bash
# gen-lockfile.sh
# Generates vault-toolkit.lock.json from the current state of the three individual repos.
# Run AFTER sync-from-individuals.sh so the lock and the bundle are consistent.

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_ROOT="$HOME/Anmols Files/CLAUDE/SKILLS"
SKILLS=(vault-restructure vault-sync vault-lint)
PLUGIN_VERSION="$(jq -r .version "$PLUGIN_ROOT/.claude-plugin/plugin.json")"
GENERATED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Build the locks array
LOCKS_JSON=""
for skill in "${SKILLS[@]}"; do
  SRC="$SOURCE_ROOT/$skill"
  SHA="$(git -C "$SRC" rev-parse HEAD)"
  REPO_URL="$(git -C "$SRC" remote get-url origin)"

  # Detect schema_version mentioned in the skill (best-effort; falls back to "unspecified").
  # Looks for `schema_version: "1.1"` or `schema_version 1.1` patterns.
  SCHEMA=$(grep -hEo 'schema_version[^0-9]+[0-9]+\.[0-9]+' "$SRC/SKILL.md" "$SRC"/references/*.md 2>/dev/null \
    | head -1 \
    | grep -oE '[0-9]+\.[0-9]+' || true)
  SCHEMA=${SCHEMA:-unspecified}

  ENTRY=$(jq -n \
    --arg skill "$skill" \
    --arg sha "$SHA" \
    --arg repo "$REPO_URL" \
    --arg schema "$SCHEMA" \
    '{skill: $skill, repository: $repo, commit: $sha, manifest_schema_version: $schema}')

  if [[ -n "$LOCKS_JSON" ]]; then
    LOCKS_JSON="$LOCKS_JSON,$ENTRY"
  else
    LOCKS_JSON="$ENTRY"
  fi
done

jq -n \
  --arg plugin "vault-toolkit" \
  --arg version "$PLUGIN_VERSION" \
  --arg ts "$GENERATED_AT" \
  --argjson locks "[$LOCKS_JSON]" \
  '{plugin: $plugin, plugin_version: $version, generated_at: $ts, skills: $locks}' \
  > "$PLUGIN_ROOT/vault-toolkit.lock.json"

echo "Lockfile written: $PLUGIN_ROOT/vault-toolkit.lock.json"
cat "$PLUGIN_ROOT/vault-toolkit.lock.json"
