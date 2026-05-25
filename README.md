# vault-toolkit

Three-skill Claude Code plugin for building, syncing, and linting a Karpathy-pattern wiki vault.

Bundles:
- **vault-restructure** — pre-vault-sync intake. Reads a folder of unorganized files, classifies each, routes to the correct vault location, injects YAML frontmatter, creates the 6 required vault file stubs, and writes a restructure-manifest + vault-index that the other two skills consume.
- **vault-sync** — bootstraps a vault from scratch if `CLAUDE.md` is missing, or syncs the current session's knowledge into the right wiki pages if the vault exists. Crystallizes durable knowledge per a 5-criteria filter.
- **vault-lint** — three-tier health check (structural, quality, semantic). Catches broken links, ghost index entries, orphan pages, oversized pages, stale frontmatter, duplicate titles, contradictions, and CLAUDE.md bloat. Report-only with one scoped write exception (regenerates the derived `patterns/language-glossary-master.md`).

## Why a plugin (not three separate installs)

The three skills share a hard interface contract: vault-restructure writes a manifest at `schema_version: "1.1"`, vault-sync consumes that manifest for stale-file detection, vault-lint reads the same manifest plus a vault-index hash chain for change-scope detection. **Installing any one standalone produces errors** — lint expects a manifest written by restructure; sync expects either to bootstrap or to find a restructure-scaffolded vault.

This plugin installs all three with verified compatibility (see `vault-toolkit.lock.json`).

Individual repos are retained for code inspection, cherry-picking, and forking:
- https://github.com/17july1997-cpu/vault-restructure
- https://github.com/17july1997-cpu/vault-sync
- https://github.com/17july1997-cpu/vault-lint

## Install

### Via local plugin directory (testing or single-machine use)

```bash
git clone https://github.com/17july1997-cpu/vault-toolkit.git
claude --plugin-dir ./vault-toolkit
```

### Via a Claude Code marketplace (recommended for sharing)

Once published to a marketplace, install via:
```
/plugin install vault-toolkit
```

The skills will appear in your skill list as:
- `/vault-toolkit:vault-restructure`
- `/vault-toolkit:vault-sync`
- `/vault-toolkit:vault-lint`

Plugin skills are namespaced (`/vault-toolkit:vault-sync` not `/vault-sync`) to prevent conflicts when multiple plugins ship skills with overlapping names.

## Usage

Typical sequence for a new vault:

```
1. Drop files into a folder
2. /vault-toolkit:vault-restructure        # routes files, creates manifest + vault-index
3. /vault-toolkit:vault-sync               # bootstraps CLAUDE.md + wiki + governance
4. ... work in the vault ...
5. /vault-toolkit:vault-sync               # at end of session, crystallizes knowledge
6. /vault-toolkit:vault-lint               # weekly health check
```

For a session sync without restructure (vault already exists):
```
/vault-toolkit:vault-sync
```

For a quick structural-only health check:
```
/vault-toolkit:vault-lint --fast
```

For LLM-judgment semantic checks (contradictions, near-duplicates):
```
/vault-toolkit:vault-lint --semantic
```

## Bundled versions

Version compatibility is captured in `vault-toolkit.lock.json` at the plugin root. The table below is generated from that lockfile and reflects exactly what ships in this plugin release.

| Skill | Commit | Manifest schema |
|-------|--------|------------------|
| vault-restructure | [39f6047](https://github.com/17july1997-cpu/vault-restructure/commit/39f6047) | 1.1 |
| vault-sync | [e3989a9](https://github.com/17july1997-cpu/vault-sync/commit/e3989a9) | 1.1 |
| vault-lint | [42e9f34](https://github.com/17july1997-cpu/vault-lint/commit/42e9f34) | consumes 1.1 (not pinned) |

To upgrade the plugin to newer SHAs:
1. Pull the latest commit from each individual repo
2. Run `scripts/sync-from-individuals.sh` (re-bundles SKILL.md + references)
3. Run `scripts/gen-lockfile.sh` (refreshes `vault-toolkit.lock.json`)
4. Run `scripts/contract-check.sh` (verifies inter-skill schema alignment)
5. Bump `version` in `.claude-plugin/plugin.json`
6. Commit + push

## Inter-skill contract

The plugin is only as safe as the contract between the three skills. The contract is:

- vault-restructure writes `wiki/restructure-manifest.md` with `schema_version: "1.1"` and a per-file inventory including `Conversion State` and `Derivative Of` columns
- vault-restructure writes `wiki/vault-index.md` with per-page metadata (path, hash, frontmatter, headings, summary, links, last_processed)
- vault-sync reads the manifest at session start (S0.5) for stale-file detection. Falls back to `wiki/index.md` if manifest is corrupted.
- vault-lint reads vault-index for change-scope detection (Tier 2 default scope = changed-files + link-neighborhood)
- vault-lint Check 26 regenerates `~/Anmols Files/CLAUDE/patterns/language-glossary-master.md` from per-project `wiki/language.md` files (the ONE scoped write exception)

If you upgrade individual repos out of band and the schema drifts, run `scripts/contract-check.sh` before publishing a new plugin version. The check is currently grep-based (looks for `schema_version` references and confirms all skills align). A full pipeline integration test (restructure → sync → lint against a fixture vault) is planned for plugin v1.1.

## License

MIT. See LICENSE.

## Acknowledgements

Pattern inspiration: Andrej Karpathy's LLM Wiki pattern (single-responsibility wiki files + index + LLM-as-driver).
