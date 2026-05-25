#!/usr/bin/env bash
# sync-from-individuals.sh
# Reproducibly bundles the three individual vault-* skill repos into this plugin's skills/ directory.
# Applies the slash-command namespacing transform so plugin users see the correct invocation form.
#
# Source-of-truth: the individual repos at ~/Anmols Files/CLAUDE/SKILLS/{skill}/
# Destination: this plugin's skills/{skill}/
#
# Re-run any time the individual repos get a new release. Then regenerate the lockfile and bump
# the version in .claude-plugin/plugin.json.

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_ROOT="$HOME/Anmols Files/CLAUDE/SKILLS"
SKILLS=(vault-restructure vault-sync vault-lint)
PLUGIN_NAME="$(jq -r .name "$PLUGIN_ROOT/.claude-plugin/plugin.json")"

if [[ -z "$PLUGIN_NAME" || "$PLUGIN_NAME" == "null" ]]; then
  echo "ERROR: could not read plugin name from .claude-plugin/plugin.json" >&2
  exit 1
fi

echo "Syncing into plugin '$PLUGIN_NAME'..."
echo

for skill in "${SKILLS[@]}"; do
  SRC="$SOURCE_ROOT/$skill"
  DEST="$PLUGIN_ROOT/skills/$skill"

  if [[ ! -d "$SRC" ]]; then
    echo "ERROR: source repo not found: $SRC" >&2
    exit 1
  fi

  echo "  $skill"
  rm -rf "$DEST"
  mkdir -p "$DEST"

  # Copy SKILL.md and references/ (the only files the plugin needs)
  cp "$SRC/SKILL.md" "$DEST/SKILL.md"
  if [[ -d "$SRC/references" ]]; then
    cp -R "$SRC/references" "$DEST/references"
  fi

  # Slash-command namespacing transform.
  # Under plugin install, the user types `/vault-toolkit:vault-sync` not `/vault-sync`.
  # Rewrite ONLY slash-command prose references (e.g. "run /vault-sync") to the namespaced form.
  # MUST NOT rewrite filesystem paths (e.g. ~/.claude/skills/vault-sync/references/...) or
  # sibling-prefixed names (e.g. /vault-sync-experimental).
  # Codex R2 P0-2 caught the prior version corrupting a filesystem path.
  # NOTE: transforms only the bundled copy. Individual-repo SKILL.md stays untouched.
  for s in "${SKILLS[@]}"; do
    # (?<![\w./]) — slash NOT preceded by word char, dot, or another slash (excludes path contexts)
    # (?![-\w])  — name NOT followed by hyphen or word char (excludes sibling `vault-sync-experimental`)
    find "$DEST" -type f -name "*.md" -exec perl -i -pe "s|(?<![\\w./])/\Q${s}\E(?![-\\w])|/${PLUGIN_NAME}:${s}|g" {} \;
  done

  # Capture the source commit SHA (used by gen-lockfile.sh)
  SHA="$(git -C "$SRC" rev-parse HEAD)"
  echo "    locked to $SHA"
done

echo
echo "Sync complete. Next: run scripts/gen-lockfile.sh to refresh vault-toolkit.lock.json"
