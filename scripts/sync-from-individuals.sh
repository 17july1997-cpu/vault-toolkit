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
  # Rewrite ALL prose references to the namespaced form so the skill's own user-facing
  # instructions match what the plugin user must actually type.
  # NOTE: this transforms only the bundled copy. The individual-repo SKILL.md stays untouched
  # (it's the standalone-install version where `/vault-sync` is correct).
  # Uses perl for portable word-boundary support (macOS BSD sed lacks \b).
  for s in "${SKILLS[@]}"; do
    find "$DEST" -type f -name "*.md" -exec perl -i -pe "s|/\Q${s}\E\b|/${PLUGIN_NAME}:${s}|g" {} \;
  done

  # Capture the source commit SHA (used by gen-lockfile.sh)
  SHA="$(git -C "$SRC" rev-parse HEAD)"
  echo "    locked to $SHA"
done

echo
echo "Sync complete. Next: run scripts/gen-lockfile.sh to refresh vault-toolkit.lock.json"
