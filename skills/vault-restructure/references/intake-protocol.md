---
type: reference
title: "vault-restructure Intake Protocol"
description: "Frontmatter injection rules, stub templates, raw-intake stamp format, companion-page template, and wikilink repair format. Loaded by vault-restructure at Step 4 (frontmatter) and Step 5 (stubs)."
---

# Intake Protocol

This file governs Step 4 (frontmatter injection) and Step 5 (stub creation) of vault-restructure.

---

## Frontmatter Injection Decision Tree

For each file at its FINAL post-move location:

```
Is the file markdown (.md)?
├── No → STOP. Do not inject. (code, binary, image, PDF excluded)
└── Yes
    Is the file CLAUDE.md?
    ├── Yes → STOP. CLAUDE.md frontmatter managed by vault-sync, not here.
    └── No
        Does the file already have a valid frontmatter block (--- ... ---) at the top?
        ├── No → INJECT full frontmatter (see field rules below)
        └── Yes
            Does the existing frontmatter have BOTH `type:` and `title:` populated (non-placeholder)?
            ├── Yes → KEEP existing frontmatter. Do not modify.
            └── No → MERGE: preserve existing valid fields, inject missing required fields.
```

---

## Field-by-Field Inference Rules

### `type:` (required)

Map from category (Step 1) to type:

| Category | `type:` value |
|----------|--------------|
| knowledge-page (decision sub-type) | `decision` |
| knowledge-page (procedure sub-type) | `procedure` |
| knowledge-page (framework sub-type) | `framework` |
| knowledge-page (research sub-type) | `research` |
| knowledge-page (reference sub-type) | `reference` |
| knowledge-page (scenario sub-type) | `scenario` |
| reference-material | `reference` |
| archive | `archive` |
| raw-intake | `raw-intake` (use raw stamp instead, see below) |

### `title:` (required)

Inference order:
1. First H1 heading in the file (`# Title Text`) → use that
2. If no H1: use filename, convert kebab-case or snake_case to Title Case (e.g., `system-design.md` → "System Design")
3. If filename is generic (`notes.md`, `untitled.md`): inspect first paragraph and infer a title from the topic

### `description:` (required, 1-sentence routing trigger)

Format: "Load this page when you need to know X" or "Documents Y for Z."

Inference rules:
- Read the first paragraph (skip frontmatter, skip headings)
- Identify the primary subject (usually a noun phrase) and the primary use case
- Write a single sentence. No more than 25 words.
- Tense: present tense, declarative
- The description is the routing signal for vault-sync's crystallization protocol. Make it specific enough that an LLM can decide whether to load this page for a given query.

Examples:
- "Documents the architectural choices made for the auth system and their tradeoffs."
- "Routing rules and category heuristics for vault-restructure file classification."
- "Decision log for the three-skill vault management system, including alternatives rejected."

### `status:` (required)

| Category | `status:` value |
|----------|----------------|
| archive | `archived` |
| all others | `active` |

### `maturity:` (optional, default `hypothesis`)

Default to `hypothesis` for new injections. Other values (`tested`, `validated`) are user-set and not inferred.

### `created:` (required)

Use the file's `stat` modification date if available. Otherwise: today's date in `YYYY-MM-DD` format.

### `updated:` (required)

Always today's date in `YYYY-MM-DD` format.

### `tags:` (required, 2-4 inferred)

Extract 2-4 tags from:
- Frequently appearing topical nouns in headings
- Project name if mentioned in content
- Concept names that appear 3+ times

Lowercase, hyphenated multi-word (e.g., `vault-management`, `frontmatter-injection`). No generic tags like `notes` or `documentation`.

### `confidence:` (optional)

Set when content includes uncertainty markers ("I think", "probably", "might be", "tentative", "draft"). Values: `high`, `medium`, `low`. Omit if no signal.

### `supersedes:` (optional)

Set when filename or content suggests this page replaces an older one:
- Filename pattern `*-v2.md`, `*-revised.md` → look for the predecessor and set `supersedes: predecessor.md`
- Content explicitly says "replaces X" → set `supersedes: X.md`

---

## raw-intake Stamp Format

For files going to `raw/`, do NOT inject the full frontmatter. Use this minimal stamp:

```yaml
---
type: raw-intake
source: [original-filename-or-source-description]
ingested: YYYY-MM-DD
status: unprocessed
---
```

`source:` field:
- If the file came from a known source (transcript, email, webpage): use that
- Otherwise: use the original filename before any rename

`status:` always starts as `unprocessed`. The user (or a future processing pass) updates to `processed` when the content has been distilled into wiki/ pages.

---

## Companion Page Template (non-markdown assets in wiki/)

When a non-markdown file (image, PDF, etc.) belongs in `wiki/` (e.g., a diagram referenced by a knowledge page), create a companion `.md` wrapper:

```yaml
---
type: reference
title: "[Asset Name]"
description: "Wrapper page for [asset-filename] — load when referencing this asset from other pages."
status: active
maturity: hypothesis
created: YYYY-MM-DD
updated: YYYY-MM-DD
asset: [asset-filename]
tags: [asset, ...]
---

# [Asset Name]

![[asset-filename]]

## Context
[1-2 sentences describing what the asset shows and when to reference it. Inferred from the asset's filename or surrounding files.]
```

The asset file itself is not modified.

---

## Stub Templates for the 6 Required Files

Use these only when the corresponding file is missing AND vault-restructure must create a stub. If the file already exists with meaningful content, append a `[RESTRUCTURE NOTE]` reconciliation marker instead.

### CLAUDE.md (stub)

```markdown
[RESTRUCTURE STUB: run /vault-toolkit:vault-sync to complete]

# [FILL IN: Project Name]

## Identity
[FILL IN: 1-2 sentences about what this vault is for]

## Navigation Protocol
1. Read `wiki/hot.md` first (current state)
2. Read `wiki/index.md` (page directory)
3. Load specific wiki pages on demand

## Vault Structure
```
[FILL IN: vault structure map]
```

## Active Focus
See wiki/hot.md
```

### wiki/hot.md (stub)

```markdown
[RESTRUCTURE STUB]

# Hot Cache — [FILL IN: Vault Name]

**Updated:** YYYY-MM-DD

## Current State
[FILL IN]

## Active Decisions
[FILL IN]

## Outstanding
[FILL IN]

## Next Session Entry Point
[FILL IN]
```

### wiki/index.md (always rebuilt, never a stub-only)

Generate from scratch by listing every file currently in `wiki/`. Format:

```markdown
# Wiki Index — [Vault Name]

One-line summary per page. Load specific pages by name — never load the whole folder.

## Core
- [wiki/hot.md](hot.md) — current active decisions and session state (always read first)
- [wiki/session-handoff.md](session-handoff.md) — last session summary (load on demand only)
- [wiki/log.md](log.md) — operation audit trail (not decisions)

## Knowledge
- [wiki/[page].md]([page].md) — [description from frontmatter]
- ...

## Archives
[only if archive subfolder or archived files exist]
```

### wiki/log.md (stub)

```markdown
# Operation Log — [Vault Name]

[YYYY-MM-DD HH:MM] RESTRUCTURE-BOOTSTRAP — vault-restructure first run.
```

If log.md already exists: do not stub. Append the Step 9 RESTRUCTURE entry.

### wiki/session-handoff.md (stub)

```markdown
[RESTRUCTURE STUB]
---
type: session-handoff
title: Last Session Handoff
updated: YYYY-MM-DD HH:MM
---

# Last Session Handoff

## Where It Started
none

## Decisions Locked + Shipped
none

## Key Files
none

## Running State
Clean

## Verification
none

## Deferred + Open Questions
none

## Pick-Up Entry Point
1. Run /vault-toolkit:vault-sync to complete CLAUDE.md and hot.md
```

### wiki/reasoning.md (stub — conditional)

Only created if `.vault-config.yaml` has `reasoning_log: enabled`, OR if reasoning.md already exists. Otherwise: defer to vault-sync Bootstrap MCQ.

```markdown
[RESTRUCTURE STUB]

# Reasoning Journal — [Vault Name]

---

[YYYY-MM-DD HH:MM] — Vault restructured

**Goal:** Normalize a file dump into vault structure.
**Starting assumption:** none — automated restructure.
**Decisions made:** Files routed per routing-taxonomy.md classification.
**Alternatives rejected:** none — automated.
**How thinking changed:** none.
**Next assumption to test:** vault-sync Bootstrap will complete CLAUDE.md identity via MCQ.

---
```

---

## Confidence Scoring Guide (for Step 1)

| Signal | Confidence |
|--------|-----------|
| Filename matches strong pattern (CLAUDE.md, *.py, *_old.md), OR frontmatter declares valid `type:` | `high` |
| Content has clear category signal (decision language, procedure language, transcript markers) | `medium` |
| Mixed signals across heuristics, OR no clear signal but content is structured | `low` |
| No clear signal AND content is unstructured | `unknown` (always flagged, never auto-routed) |

---

## Binary / Large File Handling

Files matching ANY of these:
- Extension in: `.png`, `.jpg`, `.jpeg`, `.gif`, `.svg`, `.pdf`, `.zip`, `.tar`, `.gz`, `.mp4`, `.mp3`, `.wav`, `.mov`, `.exe`, `.dmg`, `.iso`
- File size >500KB

Are classified as `asset` by extension/size alone. Skip content read. Always flagged in Step 2 for user awareness (but action is auto-determined: move to `assets/`).

For markdown files >500KB: still read frontmatter + headings, but flag for review. Likely needs splitting.

---

## Wikilink Format (for Step 6 link repair)

Markdown links: `[text](relative/path.md)` — repair by updating the path portion.

Obsidian wikilinks: `[[page-name]]` — repair by matching basename. Wikilinks are path-agnostic, so a basename match in the new-path map is sufficient.

Wikilinks with display text: `[[page-name|Display Text]]` — preserve the display text, update only the page-name portion.

Skip links inside fenced code blocks (```...```) and inline code (`...`).

---

## Reconciliation Marker Format

When a required file already exists with meaningful content, append this at the bottom (do not overwrite):

```markdown

---

[RESTRUCTURE NOTE: this file existed before vault-restructure was run on YYYY-MM-DD. Review against current vault structure and reconcile manually if needed.]
```

The marker is plain text (no frontmatter changes). vault-sync Bootstrap will surface it during the MCQ phase if relevant.
