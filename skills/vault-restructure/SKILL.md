---
name: vault-restructure
description: Pre-vault-sync intake skill that normalizes a messy file dump into a proper Karpathy-pattern vault. Reads every file in the target folder, classifies each (knowledge-page, raw-intake, code, asset, archive, etc.), routes to the correct vault location, injects YAML frontmatter on markdown files, creates the 6 required vault file stubs, repairs broken links, and writes a restructure-manifest + vault-index that vault-sync consumes for instant state awareness. Use this skill when starting a new vault from a folder of unorganized notes, when 3+ new files have been dropped without routing, or when files are in wrong folders / missing frontmatter. Triggers on "vault-restructure", "restructure the vault", "organize this folder", "route these files", "build the vault structure", "ingest this dump", "set up the vault", "normalize the folder". Always runs BEFORE vault-sync on first-time setup. Operates on one target folder at a time, never recurses into child folders that have their own CLAUDE.md (separate vault roots).
---

# vault-restructure

Normalize a folder dump into a proper vault. Route files, inject frontmatter, create the 6-file structure, write a manifest + vault-index for vault-sync to consume.

vault-restructure does NOT complete CLAUDE.md identity (that requires conversation context, owned by vault-sync Bootstrap MCQ). It produces stubs and a clean structure. vault-sync finishes the job.

Lazy-load reference files at the points indicated below. Do not front-load.

---

## Step 0: Intake and Safety Check

**Flag detection (first):**
- `--language_bootstrap` → run ONLY the Language Bootstrap phase (below). Skip Steps 1-9. Refuses without a target project folder.
- `--force` → meaningful only with `--language_bootstrap`; allows regenerating a `wiki/language.md` that already exists.
- `--no_language_bootstrap` → opt-out. Suppresses the auto-trigger in Step 5.6. Use this if the user does not want a language.md for this vault.

**Flag precedence:** if both `--language_bootstrap` and `--no_language_bootstrap` are passed, refuse with: `conflicting flags; pass one or neither.` Do not silently prefer either.

**Auto-trigger default:** Step 5.6 fires on every vault-restructure run UNLESS `--no_language_bootstrap` is passed OR `--language_bootstrap` itself is passed (which routes through the standalone phase and bypasses Step 5.6's wrapper). Other flags do not suppress the auto-trigger. The user does not need to remember the flag.

```bash
find [target-folder] -maxdepth 4 -type f | sort
```

- If the folder contains more than 200 files: warn the user and ask them to scope to a subfolder. Do not proceed.
- Read CLAUDE.md if it exists (existing routing context).
- Check for `wiki/restructure-manifest.md`. If it exists: this is a re-run. Read it. Only process new or changed files. Read its top-level `conversion_decision` field if present (skips Step 0.5 doc-conversion offer if user previously `declined`, with a "previously declined; convert now?" reminder option).
- Check which of the 6 required files already exist (CLAUDE.md, wiki/hot.md, wiki/index.md, wiki/log.md, wiki/session-handoff.md, wiki/reasoning.md).
- Check for `.vault-config.yaml` to learn `reasoning_log` preference. If absent: defer reasoning.md stub creation until vault-sync Bootstrap MCQ asks.

**Stop-at-vault-boundary rule:** if any subfolder under the target contains its own `CLAUDE.md`, treat it as a separate vault root. Do NOT recurse into it. Skip it entirely.

**Subfolder semantic detection (for Step 2 mirroring):** record the subfolder structure under the target. Any subfolder containing 3+ files of one category will be mirrored into the matching destination folder (`./assets/<name>/`, `./raw/<name>/`, or `./wiki/<name>/`) so the user's organizational intent is preserved.

**Report to user before doc-conversion offer:**
- Total files found
- Extension breakdown (e.g., 18 .md, 3 .py, 2 .png)
- Subfolder structure (e.g., `./meeting-notes/` (5 files), `./research/` (12 files))
- Present vs. missing vault files
- Run type: first-run or re-run
- Subfolders flagged as separate vault roots (skipped)
- Existing manifest's `conversion_decision` (if re-run)

---

## Step 0.5: Inventory-First Doc-Conversion Offer

If the file inventory contains 5+ binary documents (extensions: `.pdf`, `.docx`, `.pptx`, `.xlsx`, `.odt`, `.rtf`, `.epub`, `.csv`, `.json`, `.yaml`), present an inventory-first offer to convert them to markdown via `obsidian-import` (deterministic Python tool, zero LLM tokens for extraction).

**SKIP this step if:** existing manifest has `conversion_decision: declined` AND the user did NOT use a "convert previously declined files" reminder option.

**Inventory format (no LLM cost — pure metadata):**

```
DOC CONVERSION OFFER — vault-restructure
Detected N binary documents that can be converted to markdown via obsidian-import (deterministic, no LLM cost):

  [✓] research/paper-1.pdf         (12 pages, 240 KB)
  [✓] research/paper-2.pdf         (8 pages, 180 KB)
  [✓] meeting-notes/notes-Q1.docx  (4 pages, 32 KB)
  ...

Extracted markdown lands in `./raw/<basename>.md` (or `./raw/<mirrored-subfolder>/<basename>.md` if subfolder mirroring applies, e.g. files from `./meeting-notes/` → `./raw/meeting-notes/`) with frontmatter recording provenance back to the original.
Original binaries are PRESERVED in `./assets/`.

Token preflight:
  - Extraction itself: 0 LLM tokens (deterministic CLI)
  - Post-conversion frontmatter merge: ~50 tokens per file
  - Hard cap: 50 files per session (split larger batches)

Choose:
  [A] Convert all (default)
  [B] Convert all EXCEPT (uncheck files in the inventory above)
  [C] Convert NONE (binaries stay in assets/)
  [D] Cancel restructure
```

Wait for the user's choice. Record the decision in the manifest at top level: `conversion_decision: accepted | partial | declined`.

If user picks **[A] or [B]**: enumerate the selected files. For each: invoke `obsidian-import convert <path> --output <temp-output>.md`. Capture exit code per file. Record per-file `conversion_state`:
- `converted` — exit 0, output exists, output >50 words
- `needs-review` — exit 0, output exists, output <50 words AND original >5 pages (likely scanned/image-heavy; H-18)
- `failed` — non-zero exit OR output missing
- `skipped` — user unchecked in [B]

If `obsidian-import` is missing: warn user once, fall back to `pandoc` if available, else fall back to LLM-driven `/doc-to-markdown` skill (with explicit token-cost approval — much higher).

After all selected conversions complete, post-process each generated markdown: merge our frontmatter (`type: raw-intake, status: converted-unreviewed, derivative_of: <original-path>, authoritative: false, ingested: <today>`) into the existing obsidian-import frontmatter (which already has `title`, `source: obsidian-import`, `original_path`, `file_type`, `extracted_at`).

If user picks **[C]**: record `conversion_decision: declined`. All binaries flow through Step 1 as `asset` only.

If user picks **[D]**: stop the restructure. Manifest is not modified.

**Filename-stem dedup (H-19, heuristic only):** scan the selected file list for filename-stem collisions across extensions (e.g., `notes-Q1.docx` and `notes-Q1.pdf` share stem `notes-Q1`). Surface as a single line: `Possible duplicate: notes-Q1.docx + notes-Q1.pdf — convert which one? [first / second / both]`. No LLM-similarity scoring at this layer; semantic dedup stays in `vault-lint --semantic`.

**Wait for user acknowledgment of Step 0 + 0.5 before continuing to Step 1.**

---

## Step 1: Read and Classify Every File

Lazy-load `references/routing-taxonomy.md` here.

For each file:
- Binary, image, or >500KB: skip content read. Classify as `asset` by extension alone. Flag for review.
- Markdown / text files:
  - Check `wiki/vault-index.md` if it exists. If the file's current mtime matches the indexed `last_processed` mtime AND the routing-taxonomy version is unchanged: use the index entry (skip full read).
  - Otherwise: read frontmatter + headings first. If classification is unambiguous from heading + frontmatter alone, use that.
  - Full content read only when classification is ambiguous after the heading + frontmatter pass.

**Categories:**
- `core-vault` — already-existing CLAUDE.md, hot.md, index.md, log.md, session-handoff.md, reasoning.md
- `knowledge-page` — durable wiki content (decisions, frameworks, procedures, references, scenarios)
- `reference-material` — external docs, specs, cheatsheets that belong in wiki/ but as reference
- `raw-intake` — unprocessed dumps, transcripts, raw notes
- `code-artifact` — .py, .js, .ts, .sh, .css, .html source files
- `asset` — images, PDFs, binaries, anything not text-based
- `archive` — explicitly old / deprecated / superseded versions
- `unknown` — cannot classify confidently

**Re-run rule:** if manifest exists, only classify files NOT in the previous manifest, OR files whose current mtime is newer than the manifest's recorded mtime. Skip already-catalogued unchanged files.

For each file note: current location, recommended vault location, whether valid frontmatter exists (`type:` AND `title:` both present).

---

## Step 2: Build the Routing Plan

For each file, record:
- Current path
- Destination path
- Action: `keep` / `move` / `create-frontmatter` / `stub-only` / `flag`
- Confidence: `high` / `medium` / `low`

`unknown` category files are always flagged. Low-confidence classifications are always flagged.

Present the routing plan as a table to the user. Wait for explicit confirmation before proceeding to Step 3. Allow the user to override individual rows.

---

## Step 3: Move Files + Run Conversions

Build a complete old-path → new-path map BEFORE any move executes. This is the link-repair input for Step 6.

**Collision rule:** if a destination already exists, rename the incoming file with `_conflict` suffix (e.g., `design_conflict.md`), flag for user review. Never silently overwrite.

**Folder creation rules:**
- `wiki/` is always created if missing
- Subdirectories under `wiki/` (`wiki/research/`, `wiki/archive/`, `wiki/decisions/`) only created when 3+ files would land there. Below threshold, files go to `wiki/` root.
- `raw/` and `assets/` created only on demand

**Subfolder mirroring rule (H-4):** if Step 0 detected a source subfolder containing 3+ files of one category, MIRROR that subfolder under the destination folder.
- e.g., `./meeting-notes/` with 5 .docx files → all binaries land in `./assets/meeting-notes/`, all converted markdown lands in `./raw/meeting-notes/`
- e.g., `./research/` with 12 .pdf files → `./assets/research/` for binaries, `./raw/research/` for converted markdown
- Asymmetry guard (S-4): if both binary and converted-markdown go to mirrored paths, the SAME source subfolder name is used at BOTH destinations. Never split (`./assets/meeting-notes/` + `./raw/meetings/`) — semantic identity must be preserved.

**Conversion execution (per Step 0.5 selection):** for each file marked `pending` in the conversion plan:

```bash
obsidian-import convert <source-path> --output <dest-raw-path>.md
```

Capture exit code. Update per-file `conversion_state` in the manifest:
- exit 0 + output >50 words → `converted`
- exit 0 + output <50 words AND original file >5 pages → `needs-review` (likely scanned/image-heavy, H-18)
- non-zero exit OR no output → `failed` (record the error message)

If `obsidian-import` is not available: fall back to `pandoc` if installed; else fall back to LLM `/doc-to-markdown` skill (with explicit token-cost approval since cost jumps significantly).

After each conversion succeeds, the original binary is COPIED (not moved) to `./assets/<mirrored-path>/`. The original is preserved as the source of truth (`authoritative: true` per H-17). The converted markdown lands in `./wiki/<mirrored-path>/<basename>.md` as a draft page — NOT in `raw/`.

**Write-lock enforcement (Section 9.1.1):** `raw/` is a human-curated inbox. No AI agent or conversion pipeline may write to it. Converted markdown is AI-generated output and must go directly to `wiki/` with `status: draft` and `authoritative: false`. The user reviews and promotes or deletes from there. Routing converted output to `raw/` violated this rule in earlier versions of this skill.

Record every move + conversion. For moved markdown files, note all relative-path links found in the body (for Step 6 link repair).

---

## Step 4: Apply Frontmatter Injection

Lazy-load `references/intake-protocol.md` here.

**Applies ONLY to markdown files at their final post-move locations. Never to:**
- Code files (.py, .js, .ts, .sh, .html, .css)
- Binary files (.png, .pdf, .jpg, .zip)
- CLAUDE.md (managed separately)

Files needing frontmatter (missing `---` block, OR missing `type:`/`title:`, OR placeholder values like `[FILL IN]`):

Inject YAML fields inferred from content:
- `type` — map category to `decision` / `framework` / `research` / `procedure` / `reference` / `scenario` / `archive`
- `title` — from first `#` heading or filename + content inference
- `description` — 1-sentence routing trigger ("load this page when you need to know X")
- `status` — `draft` (default for all newly routed pages; they are unreviewed until the user promotes them). Exception: `status: archived` for the `archive` category. Do NOT default to `active` — an AI-routed page has not been reviewed and should not be treated as authoritative (Section 9.2.3 status lifecycle: draft → active → evergreen → archived).
- `maturity` — `hypothesis` (default)
- `created` — file stat date or today
- `updated` — today
- `tags` — 2-4 inferred from content
- `confidence` — optional, set when content includes uncertainty markers
- `supersedes` — optional, set when filename or content suggests replacement

**Special cases:**
- `code-artifact` and `asset` categories: no frontmatter injection (stay as-is)
- `archive` category: inject `type: archive`
- Files moving to `raw/` (NOT from conversion): minimal intake stamp:
  ```yaml
  ---
  type: raw-intake
  source: [original-filename]
  ingested: YYYY-MM-DD
  status: unprocessed
  ---
  ```
- **Files in `raw/` from obsidian-import conversion (H-1, H-17):** obsidian-import already emits frontmatter with `title`, `source: "obsidian-import"`, `original_path`, `file_type`, `extracted_at`. **Merge order (atomicity rule):** (1) parse the existing YAML block produced by obsidian-import, (2) preserve every key it emitted as-is (do not overwrite `title`, `source`, `original_path`, `file_type`, `extracted_at`), (3) add or overwrite ONLY our workflow keys (`conversion_tool`, `conversion_version`, `derivative_of`, `authoritative`, `type`, `status`, `ingested`), (4) emit ONE canonical frontmatter block (no duplicate `---` delimiters, no duplicate keys). Final shape:
  ```yaml
  ---
  title: "<from-obsidian-import>"
  source: "obsidian-import"
  original_path: "<from-obsidian-import>"
  file_type: "<from-obsidian-import>"
  extracted_at: "<from-obsidian-import>"
  conversion_tool: "obsidian-import"
  conversion_version: "1.1.0"   # capture from `pip show obsidian-import`
  derivative_of: "<assets/path/to/original>"
  authoritative: false
  type: raw-intake
  status: converted-unreviewed
  ingested: YYYY-MM-DD
  ---
  ```
- Non-markdown files NOT going into `wiki/` (i.e., binaries staying in `./assets/`): NO companion wrapper page (per S-5 / H-7 simplification — drop per-asset wrappers). Their metadata lives in `wiki/restructure-manifest.md` (the canonical LLM-readable surface). For human consumption, rely on Obsidian's native file tree + search (per Step 5.5). No `wiki/assets-index.md` aggregation file is written.

---

## Step 5: Ensure All 6 Required Files Exist

Lazy-load `references/intake-protocol.md` if not already loaded.

Check each. For missing files, create stubs per the template:

| File | Stub rule |
|------|-----------|
| `CLAUDE.md` | Line 1 must be `[RESTRUCTURE STUB: run /vault-toolkit:vault-sync to complete]`. Then minimal structure with `[FILL IN]` placeholders. |
| `wiki/hot.md` | `[RESTRUCTURE STUB]` line 1, today's date, `[FILL IN]` placeholders. |
| `wiki/index.md` | ALWAYS rebuild from scratch (even if it exists). Populate from every file now in `wiki/`. This is the one stub that is always fully populated, not stub-only. Stale index.md is vault-sync's single-point coordination failure. **If `wiki/` has 0 knowledge pages (only meta files): under `## Knowledge`, write a single placeholder line `(no knowledge pages yet — populate via /vault-toolkit:vault-sync conversation crystallization or by promoting raw/ converted files to wiki/)`. This makes the empty-state intentional rather than dangling — H-10.** |
| `wiki/log.md` | If missing, create with single entry: `[YYYY-MM-DD HH:MM] RESTRUCTURE-BOOTSTRAP — vault-restructure first run.` If present, append the Step 9 RESTRUCTURE entry. |
| `wiki/session-handoff.md` | `[RESTRUCTURE STUB]` line 1, all 7 sections present with "none" values. |
| `wiki/reasoning.md` | Only create if `.vault-config.yaml` has `reasoning_log: enabled`, OR if the file already exists. Otherwise: defer. The vault-sync Bootstrap MCQ will ask the user and create if needed. |

**Pre-existing meaningful content rule:** if a required file exists with substantive content (not a stub, not empty, not `[RESTRUCTURE STUB]`), do NOT overwrite. Append a reconciliation note: `[RESTRUCTURE NOTE: file existed before this run — review and reconcile]`.

Exception: `wiki/index.md` is always rebuilt regardless of prior state.

---

## Step 5.5: Obsidian-Aware Asset Surfacing (no aggregation file written)

**Asset metadata is intentionally NOT aggregated into a wiki/assets-index.md file.** Per the Obsidian-as-front-end decision, binaries in `./assets/` (and any mirrored subfolders) are surfaced via Obsidian's native:
- File tree (full hierarchy visible in left sidebar)
- Global search (type any filename)
- PDF embedding (`![[paper.pdf]]` from any wiki page renders inline)
- Graph view (links between markdown pages including those that reference assets)

The vault-restructure manifest (Step 7) already records every asset's path, original-source, and conversion state. That manifest is the LLM-readable surface. Obsidian is the human-readable surface. No third surface is created.

If the user does NOT use Obsidian and operates primarily through Claude Code, the LLM can still find any asset by:
1. Reading the manifest's File Inventory table (lists every asset path)
2. Running `find ./assets -type f` from a tool

No additional aggregation file is required. Continue to Step 5.6.

---

## Step 5.6: Auto-Trigger Language Bootstrap

**Fires on every vault-restructure run UNLESS `--no_language_bootstrap` is passed OR `--language_bootstrap` itself was passed (standalone mode bypasses this wrapper).** The user is not expected to remember the flag. The skill detects missing language.md and acts.

Conditions (ALL must be true to auto-fire):
- `<target-folder>/wiki/language.md` does NOT exist
- `<target-folder>/CLAUDE.md` exists AND its line 1 does NOT contain `[RESTRUCTURE STUB`. (On first-run with a fresh stub, defer; the deferral is recorded so Step 8 surfaces it.)
- `--no_language_bootstrap` was NOT passed
- `--language_bootstrap` was NOT passed (when passed, the standalone phase runs directly per Step 0 and skips this wrapper)

If conditions hold: run the Language Bootstrap phase below (Steps 1-6 of that phase) inline, right here.

If the CLAUDE.md is still a `[RESTRUCTURE STUB`: do NOT fire. Surface in Step 8 report as: `LANGUAGE BOOTSTRAP DEFERRED — CLAUDE.md is still a restructure stub. Run /vault-toolkit:vault-sync to complete CLAUDE.md, then re-run /vault-toolkit:vault-restructure to auto-generate language.md.`

---

## Step 6: Link Repair

Only runs if Step 3 moved any files. Uses the old-path → new-path map from Step 3.

Scan all markdown files in the vault for:
- Markdown links: `[text](old/path.md)` → `[text](new/path.md)`
- Obsidian wikilinks: `[[old-name]]` → `[[new-name]]` (match by basename, since wikilinks are path-agnostic)

Update to new relative paths. Skip links inside fenced code blocks.

Report: number of links updated, files touched.

---

## Step 7: Write the Restructure Manifest + Vault Index

These are the two coordination artifacts vault-sync consumes.

### restructure-manifest.md

Write `wiki/restructure-manifest.md`:

```yaml
---
type: restructure-manifest
schema_version: "1.1"
updated: YYYY-MM-DD HH:MM
files_total: N
files_processed: N
files_moved: N
files_frontmatter_injected: N
files_flagged: N
files_converted: N
files_failed_conversion: N
files_needs_review: N
conversion_decision: [accepted | partial | declined | not-prompted]
---

# Restructure Manifest

## Last Run
Date: YYYY-MM-DD HH:MM
Run type: [first-run | re-run]
conversion_decision: [accepted | partial | declined | not-prompted]
conversion_tool: obsidian-import@1.1.0  (only present if conversion_decision != not-prompted)

## File Inventory
| Path | Original Path | Category | mtime | Action | Frontmatter | Conversion State | Derivative Of |
|------|---------------|----------|-------|--------|-------------|------------------|---------------|
| wiki/design.md | notes/design.md | knowledge-page | 2026-04-29 | moved+frontmatter | injected | not-applicable | — |
| raw/research/paper-1.md | research/paper-1.pdf | raw-intake (converted) | 2026-05-01 | converted+frontmatter-merged | merged | converted | assets/research/paper-1.pdf |
| raw/research/paper-2.md | research/paper-2.pdf | raw-intake (converted) | 2026-05-01 | conversion-failed | none | failed | assets/research/paper-2.pdf |
| raw/research/scanned.md | research/scanned.pdf | raw-intake (converted) | 2026-05-01 | converted+needs-review | merged | needs-review | assets/research/scanned.pdf |
| assets/research/paper-1.pdf | research/paper-1.pdf | asset | 2026-05-01 | moved-to-mirror | n/a | not-applicable | — |
| CLAUDE.md | (same) | core-vault | 2026-04-28 | kept | existing | not-applicable | — |

`Conversion State` values: `converted` / `failed` / `needs-review` / `pending` / `skipped` / `not-applicable` / `declined`. `Derivative Of` is set only when `Conversion State == converted` or `needs-review`; points to the source binary path under `./assets/`.

## Removed Since Last Run (deletion detection)
- (entries listed if any manifest-tracked files no longer exist on disk)

## Flagged Files
- mystery-doc.md — content unclear, manual review needed
- research/paper-2.pdf — conversion FAILED (per S-3, vault-sync should reject this entry until user resolves)
- research/scanned.pdf — output <50 words from a 7-page document; likely scanned/image-heavy. Needs OCR or manual handling.

## Ready for vault-sync
Run /vault-toolkit:vault-sync to complete CLAUDE.md and hot.md stubs. Review converted-unreviewed files in raw/ and promote to wiki/ via conversation if they carry substantive knowledge.
```

**Re-run merge rule:**
- Add new entries for files newly classified
- Update entries where current mtime > manifest mtime
- REMOVE entries for files no longer on disk (deletions)
- Preserve all other entries unchanged

### vault-index.md

Write `wiki/vault-index.md` with one compact block per markdown file in the vault:

```
path: wiki/design.md
hash: abc123def
frontmatter_type: decision
title: System Design Choices
headings: [Overview, Options Considered, Decision, Consequences]
summary: Documents the architectural choices made for X and why.
links: [wiki/arch.md, wiki/constraints.md]
last_processed: 2026-04-30
taxonomy_version: 1
```

**mtime + hash hybrid rule:** for re-runs, only re-hash files whose mtime is newer than the indexed `last_processed`. mtime is the prefilter; hash is the authority. If `taxonomy_version` in routing-taxonomy.md changes, force a full re-classification on the next run regardless of file mtimes.

---

## Step 8: Output Report

```
vault-restructure complete — [target-folder]
Date: YYYY-MM-DD HH:MM

Files processed: N | Moved: N | Frontmatter added: N | Stubs created: N | Flagged: N

[MOVED]       notes/design.md         -> wiki/design.md
[FRONTMATTER] wiki/design.md          -> type: decision injected
[STUB]        wiki/session-handoff.md -> created (stub only)
[KEPT]        CLAUDE.md               -> no change
[FLAGGED]     mystery-doc.md          -> content unclear, review manually
[CONFLICT]    notes/v2.md             -> renamed wiki/v2_conflict.md (destination existed)

Manifest: wiki/restructure-manifest.md
Vault index: wiki/vault-index.md

Ready for vault-sync. Run /vault-toolkit:vault-sync to complete CLAUDE.md and hot.md.
Files still needing manual review: [list or "none"]
```

---

## Step 9: Append to log.md

```
[YYYY-MM-DD HH:MM] RESTRUCTURE — Files: N processed, N moved, N frontmatter injected, N stubs, N flagged.
```

---

## Phase: Language Bootstrap (`--language_bootstrap`)

Standalone phase. Generates `projects/<name>/wiki/language.md` for a project via MCQ co-authoring. Pattern proven on PEV (16 terms, 4 disambiguation rules, 3 grill smoke tests with zero schema drift).

**Preconditions (refuses if violated):**
- No target project folder passed → refuse. Phase requires `--language_bootstrap <project-path>`.
- `<project-path>/wiki/language.md` already exists AND `--force` not passed → refuse. Redirect: "language.md exists; pass `--force` to regenerate or edit by hand."
- `<project-path>/CLAUDE.md` missing → refuse. Phase requires project context; run base vault-restructure first.
- `<project-path>/CLAUDE.md` line 1 contains `[RESTRUCTURE STUB` → refuse. Redirect: "CLAUDE.md is still a restructure stub; run /vault-toolkit:vault-sync to complete it first." (Parity with the Step 5.6 auto-trigger guard; standalone invocation must not bypass the weak-context check.)

**Phase steps:**

1. **Read context.** Project's CLAUDE.md, wiki/hot.md, wiki/index.md (if present), 3-5 most-recent wiki pages, raw/ filenames (not bodies), the identity index `~/Anmols Files/CLAUDE/identity/index.md` AND any wiki pages it links to (1-hop only, do not recurse).
   - **Recency definition:** rank wiki pages by file mtime descending. If `wiki/vault-index.md` exists, use its `last_processed` field as the authority instead of raw mtime.
2. **Draft 8-12 candidate terms.** Pull from: proper nouns (people, products, frameworks), repeated jargon, terms with multiple aliases in flight, ambiguity flagged in any source doc. Write `wiki/language.md` with `status: draft-pending-mcq`.
3. **Run MCQs in 4 batches of up to 4 questions each.** Per design contract Rule 1: every question is 3-4 options; exactly one option ends with literal ` (Recommended)`. No brackets, no lowercase, no embedding inside the option letter. No open-ended prompts.
   - Batch 1 (canonical-name picks): `"Term X is referred to as 'A', 'B', 'C', or 'D' (Recommended). Which is canonical?"`
   - Batch 2 (alias allow/forbid): `"Should alias '<alias>' be 'allowed', 'forbidden', 'scoped-disambiguation', or '<skill's read>' (Recommended)?"`
   - Batch 3 (disambiguation rules): `"When term X collides with Y, the rule is 'A', 'B', 'C' (Recommended), or 'D'?"`
   - Batch 4 (ambiguity gating): per candidate where canonical decision is uncertain, `"Is this term 'lock now with my Recommended canonical', 'flag AMBIGUOUS and decide later' (Recommended), or 'drop from the language file entirely'?"` Default to the AMBIGUOUS option when source docs disagree. Terms answered AMBIGUOUS are written under a `## Decision-Pending Section` with `**Status**: AMBIGUOUS — decision pending`, per `patterns/language-template.md` rules.
4. **Rewrite with decisions locked.** `status: active`. Append today's date to `created:` and `updated:`. Each term carries: Definition (one line) + Aliases allowed + Aliases forbidden + Disambiguation rule + Example correct + Example incorrect (per `patterns/language-template.md`).
5. **Register in index (dedupe on re-runs).** Open `~/Anmols Files/CLAUDE/patterns/language-index.md`. Match existing rows by the path column.
   - If the project's path is NOT present: append a new row: `| <Project Name> | <relative-path-to-language.md> | <today> | <today> | Built via --language_bootstrap |`.
   - If the project's path IS present (re-run via `--force`): UPDATE the `Last Updated` cell to today, and append `; regenerated via --force <today>` to the Notes cell. Do not append a duplicate row.
6. **Smoke-test hook.** Print one suggested grep per forbidden alias so the user can validate the rules against the existing wiki: `grep -rn --include="*.md" "<forbidden_alias>" "<project_root>"`. Do not run the grep here; that is the user's verify step.

**Refusals (Rule 3):**
- Refuses hand-writing language.md from scratch. The MCQ co-authoring flow is mandatory; that is what makes this "5 min calibration, not documentation labor."
- Refuses running on a project that already has `language.md` unless `--force` is passed.
- Refuses running without an explicit target project folder.
- Refuses authoring `patterns/language-glossary-master.md`. That file is DERIVED by vault-lint, never authored here.

---

## Hard Rules

1. **Never inject frontmatter on non-markdown files.** Code, binaries, images, PDFs, and CLAUDE.md are excluded.
2. **Never silently overwrite a destination.** Always rename with `_conflict` suffix and flag.
3. **Never recurse into a subfolder with its own CLAUDE.md.** That is a separate vault root.
4. **Never run the durability filter on existing files.** That filter gates session-derived candidates in vault-sync. Files in the dump were placed there deliberately.
5. **CLAUDE.md is always a stub from this skill.** Identity belongs to vault-sync Bootstrap MCQ.
6. **wiki/index.md is always rebuilt every run.** Stale index = coordination failure.
7. **Frontmatter is injected after moves, not before.** Path-sensitive fields and relative links stabilize only at final location.
8. **Flagged files do not block completion.** They stay in place and surface in the report.
9. **No em dashes in any output.** Use commas, periods, or colons.
10. **Operates on one target folder at a time.** Never traverses up to a parent vault. Never recurses into child vault roots.

---

## Reference Files (lazy-load at indicated steps)

- `references/routing-taxonomy.md` — categories, heuristics, folder mapping, 3+ subdirectory threshold. Load before Step 1.
- `references/intake-protocol.md` — frontmatter injection rules, stub templates, confidence guide, companion-page template, wikilink format. Load before Step 4.

Borrows from vault-sync (read-only, do not modify): `~/.claude/skills/vault-sync/references/vault-structure.md` for the 6-file templates.
