---
type: reference
title: "vault-restructure Routing Taxonomy"
description: "Category definitions, classification heuristics, folder mapping, and threshold rules. Loaded by vault-restructure at Step 1."
taxonomy_version: 1
---

# Routing Taxonomy

This file is the classification authority for vault-restructure Step 1. The `taxonomy_version` field at top is incremented when classification rules change, which forces a full re-classification on the next run.

---

## Categories and Folder Mapping

| Category | Destination folder | Frontmatter `type:` | Notes |
|----------|-------------------|---------------------|-------|
| `core-vault` | (already in place) | none — managed separately | CLAUDE.md, hot.md, index.md, log.md, session-handoff.md, reasoning.md |
| `knowledge-page` | `wiki/` | `decision` / `framework` / `procedure` / `reference` / `scenario` | Subdivide via heuristics below |
| `reference-material` | `wiki/` | `reference` | External specs, cheatsheets, copy-pasted docs |
| `raw-intake` | `raw/` | `raw-intake` | Transcripts, dumps, unprocessed |
| `code-artifact` | `assets/scripts/` | none (no injection) | .py, .js, .ts, .sh, .html, .css |
| `asset` | `assets/` | none (companion .md if going into wiki/) | images, binaries, PDFs |
| `archive` | `wiki/archive/` | `archive` | Only if 3+ archive files; else `wiki/` |
| `unknown` | (stay in place) | none — flag | Always flagged |

---

## Knowledge-Page Sub-Type Heuristics

When category is `knowledge-page`, choose `type:` value via these signals (ordered: first match wins):

| Signal | `type:` value |
|--------|---------------|
| Phrases: "we decided", "ADR", "chosen approach", "alternatives considered", "decision rationale" | `decision` |
| Phrases: "how to", "steps to", "runbook", "procedure", "workflow", numbered step lists | `procedure` |
| Phrases: "framework", "model", "principles", "philosophy", "approach to" | `framework` |
| Phrases: "research", "findings", "analysis", "competitive landscape", "literature", "study" | `research` (route to `wiki/research/` if 3+ research files) |
| Phrases: "reference", "cheatsheet", "spec", "API", "schema", "glossary" | `reference` |
| Phrases: "scenario", "case study", "example flow", "user journey", "walkthrough" | `scenario` |
| Default if knowledge-page but no signal | `reference` |

---

## Category Classification Heuristics

Read in order. First match wins.

1. **Path-and-filename signals override content signals for these:**
   - Path is exactly `./CLAUDE.md` → `core-vault`
   - Path is exactly `./wiki/hot.md`, `./wiki/index.md`, `./wiki/log.md`, `./wiki/session-handoff.md`, or `./wiki/reasoning.md` → `core-vault`
   - Path is `./wiki/restructure-manifest.md` or `./wiki/vault-index.md` → `core-vault` (vault coordination files, never re-routed)
   - Path is under `./wiki/reasoning_archive/` or `./wiki/log_archive/` → `core-vault` (archived meta, leave in place)
   - **Filename match without correct path** (e.g., `./index.md` at root, `./notes/log.md` in a subfolder, `./hot.md` at root): do NOT classify as `core-vault`. Fall through to content-based classification. Flag in Step 2 with a note: "filename matches reserved vault file but path is non-canonical; will collide if moved into `wiki/` — rename suggested."
   - Named with prefix/suffix `v1-`, `old-`, `deprecated-`, `archive-`, `_old`, `_deprecated` → `archive`
   - Extension `.py`, `.js`, `.ts`, `.sh`, `.rb`, `.go`, `.rs`, `.java`, `.html`, `.css`, `.json` (when not data), `.yaml` (when not config) → `code-artifact`
   - Extension `.png`, `.jpg`, `.jpeg`, `.gif`, `.svg`, `.pdf`, `.zip`, `.mp4`, `.mp3`, `.wav` → `asset`
   - Extension `.docx`, `.pptx`, `.xlsx`, `.odt`, `.rtf`, `.epub`, `.csv`, `.json` (when binary/data), `.yaml` (when not config) → `asset` (Office/data formats; convertible to markdown via obsidian-import in Step 0.5)

2. **Size and structure signals:**
   - File >500KB and not markdown → `asset`, skip content read
   - Markdown <100 words with no headings AND no frontmatter → `raw-intake`
   - Markdown with raw transcript markers ("Speaker 1:", timestamps `[00:01:23]`, chat-log style) → `raw-intake`

3. **Content signals (require reading frontmatter + headings, possibly body):**
   - Has frontmatter with `type:` already present and valid → use that type, category `knowledge-page` (or `archive` if `type: archive`)
   - First heading or first paragraph contains decision/procedure/research signals (see Knowledge-Page Sub-Type Heuristics) → `knowledge-page`
   - First heading or first paragraph contains reference signals → `knowledge-page` (sub-type `reference`)
   - Contents primarily list-of-links or list-of-resources without analysis → `reference-material`

4. **Fallback:**
   - Cannot classify confidently → `unknown` (always flagged)

---

## Subdirectory Creation Threshold

Subdirectories under `wiki/` are created only when 3+ files would land there. Below threshold, files go to `wiki/` root.

| Subdirectory | Trigger |
|--------------|---------|
| `wiki/research/` | 3+ files classified as `knowledge-page` with sub-type `research` |
| `wiki/archive/` | 3+ files classified as `archive` |
| `wiki/decisions/` | 3+ files classified as `knowledge-page` with sub-type `decision` AND user explicitly grouped them previously (default: keep in `wiki/` root) |
| `wiki/procedures/` | 3+ files classified as `knowledge-page` with sub-type `procedure` AND user explicitly grouped them previously (default: keep in `wiki/` root) |

Default behavior: do not create subdirectories for `decisions/` and `procedures/`. The wiki/ root is sufficient. Subdirectories add navigation cost without compensating value below ~10 files of one type.

`raw/`, `assets/`, `assets/scripts/` are created on demand at any count (1+ file).

### Subfolder Mirroring (H-4 / S-4)

If the source folder being restructured contains a subfolder with 3+ files of one category (e.g., `./meeting-notes/` has 5 .docx files, `./research/` has 12 .pdf files), MIRROR that subfolder name under the destination root.

| Source pattern | Mirror to |
|---|---|
| `./meeting-notes/` (5 .docx, all binaries) | `./assets/meeting-notes/` (binaries) AND `./raw/meeting-notes/` (any converted markdown) |
| `./research/` (12 .pdf, all binaries) | `./assets/research/` AND `./raw/research/` |
| `./images/` (8 .png) | `./assets/images/` |
| `./scripts/` (4 .sh) | `./assets/scripts/` (matches existing rule) |

Asymmetry guard: if conversions of files from `./meeting-notes/` happen, the resulting markdown lands in `./raw/meeting-notes/` — the SAME subfolder name on both surfaces. Never split into different names. The user's organizational intent must be preserved across both binary and converted-markdown destinations.

If the source subfolder has fewer than 3 files of one category, files flatten into the destination root without mirroring.

---

## Reference Material vs. Knowledge Page

A file is `reference-material` (not `knowledge-page`) when:
- It is primarily a list of links, citations, or resources
- It is a copy-pasted external spec / API doc / cheatsheet
- It contains minimal first-party analysis or synthesis

A file is `knowledge-page` (not `reference-material`) when:
- It contains the user's own thinking, decisions, or analysis
- It synthesizes or interprets material rather than just collecting it
- It would be load-on-demand to answer a specific question

Both go to `wiki/` but `knowledge-page` gets a richer `description:` field for routing.

---

## Confidence Scoring (for Step 2 routing plan)

| Confidence | Signal |
|------------|--------|
| `high` | Filename matches a strong pattern AT THE CANONICAL PATH (e.g., `./CLAUDE.md` at root, `./wiki/index.md` in wiki/), OR extension match (*.py, *.png, *_old.md), OR frontmatter already declares valid `type:` |
| `medium` | Content has clear signal (decision language, procedure language, transcript markers) but no filename or frontmatter confirmation |
| `low` | Mixed signals across heuristics, OR no clear signal but content is structured enough to keep, OR a reserved vault filename appears at a non-canonical path (e.g., root-level `index.md`, `notes/log.md`) — content classification overrides the filename match, but confidence stays low because the filename collision still warrants user review |

Low-confidence files are always flagged in the routing plan, even when an action is suggested. The user reviews flagged rows before Step 3 executes.

---

## Special Cases

**File with frontmatter but no body content:** classify by frontmatter `type:`, but flag as low-signal (likely a stub never completed).

**File that looks like a `wiki/index.md` from another vault:** classify as `unknown`, flag — manual review needed. May be a residue from a previous restructure or a copied vault.

**File with multiple sections that span categories:** classify by the dominant section. Flag if dominance is unclear (>30% of content in a different category).

**Markdown file in a subfolder that looks like a separate vault root** (subfolder contains its own CLAUDE.md): SKIP. Do not classify, do not move. Note in the Step 0 report.

**File with valid frontmatter at wrong location** (e.g., `type: decision` in `raw/`): the existing frontmatter is authoritative for category. Move to correct folder per the type.
