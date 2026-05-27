---
name: vault-sync
description: 'Ingestion agent that writes the current chat session into the right project files, and bootstraps the full vault structure (CLAUDE.md, wiki/hot.md, wiki/index.md, wiki/log.md) if none of it exists yet. Use this skill at the end of any working session to ensure nothing is lost. Triggers on vault-sync, sync the vault, update the files, ingest this conversation, save what we discussed, update hot.md, end of session sync, write to the wiki, crystallize this session, sync the wiki, or any time the user wants session knowledge persisted to disk before clearing context. Also trigger when user says before I clear or wrap up the files. Two modes, BOOTSTRAP (vault does not exist yet) and SYNC (vault exists, update it from this session).'
---

# vault-sync

Persist what was built, decided, or learned in this session into the right project files. Two modes — detect which applies before doing anything.

Before starting, read `references/vault-structure.md` for file templates and folder layout only at the point you actually need to create files (lazy-load).

---

## Step 0: Detect Mode

Check whether CLAUDE.md exists in the current working directory.

```bash
ls CLAUDE.md 2>/dev/null && echo "EXISTS" || echo "MISSING"
```

- **MISSING** → run BOOTSTRAP mode
- **EXISTS** → run SYNC mode

**Sub-check 1 (restructure stub guard):** If CLAUDE.md EXISTS, read line 1. If line 1 contains `[RESTRUCTURE STUB`: treat as BOOTSTRAP mode (the stub needs completing), not SYNC mode. The marker must be on line 1 for reliable detection.

**Sub-check 2 (manifest presence):** Check whether `wiki/restructure-manifest.md` exists.

```bash
ls wiki/restructure-manifest.md 2>/dev/null && echo "MANIFEST" || echo "NO-MANIFEST"
```

Store this result. It is consumed in Step S0.5 (Sync) and Step B0.5 (Bootstrap) for stale file detection.

Also check which wiki files exist (hot.md, index.md, log.md, session-handoff.md, reasoning.md). Some may exist without others. Create only what is missing.

---

## BOOTSTRAP Mode

**When to use:** CLAUDE.md does not exist, or CLAUDE.md line 1 carries a `[RESTRUCTURE STUB]` marker. The vault has no completed identity yet.

### Step B0: Mandatory Token Preview

Before any reads or writes, estimate scope and show the user:

```
vault-sync estimate — [folder-name]
Mode: Bootstrap
Files to scan: N (from a quick `find . -maxdepth 3 -type f` count)
Existing wiki files present: [hot.md / index.md / log.md / ...]
Manifest detected: [yes / no]
Estimated markdown pages to read in B0.8: N (cap 30)
Estimated files to write: 6 vault files (CLAUDE.md + 5 wiki/ files)
Approximate token range: LOW–HIGH

Proceed? [Enter to continue / type 'n' to cancel]
```

Wait for explicit user confirmation. If the user cancels, stop here. Do not proceed.

### Step B0.5: Folder Scan + Manifest Check

```bash
find . -maxdepth 3 -type f | sort
```

- Note each file's relative path and extension
- Note which of the 6 required vault files already exist
- Note any existing subfolders (wiki/, raw/, assets/, etc.)
- Do NOT read file contents here

If `wiki/restructure-manifest.md` exists: read it. The manifest contains a complete file inventory from the last vault-restructure run. Use this instead of a blind scan to understand what was already organized.

**Decision gate:**
- Apply the same vault meta-file exclusion as Step S0.5 BEFORE counting: never count `./CLAUDE.md`, `./.vault-config.yaml`, the 5 wiki/ core files (hot.md, index.md, log.md, session-handoff.md, reasoning.md), `./wiki/restructure-manifest.md`, `./wiki/vault-index.md`, or anything under `./wiki/reasoning_archive/` or `./wiki/log_archive/`. They are never "unstructured."
- If 5+ unstructured markdown files exist outside wiki/, raw/, assets/ AND are NOT in the manifest AND are NOT vault meta files: warn the user immediately: "I found N unorganized files. Running /vault-restructure first will produce a better CLAUDE.md. Proceed anyway? [Yes / No / Run restructure first]"
- If the user says "proceed anyway" or fewer than 5 unstructured files exist: continue to B0.8

### Step B0.8: Deep Read for CLAUDE.md Drafting

This is the smart analysis step.

**Branch on markdown availability:**

**Branch A: 1+ markdown files exist in B0.5 scan.**

Read frontmatter + headings ONLY (not full content). Cap at 30 files. If more than 30 markdown files exist, sample by structural richness — prefer files with headings, larger file size, or filenames suggesting project definitions. Note that sampling was used.

Full content read only when a file has neither frontmatter nor headings AND classification depends on its body.

From the heading + frontmatter scan, extract:
- Apparent project name (most common noun/phrase in headings and titles)
- Project type: code project / research / ops-workflow / writing / mixed
- Top 3-5 recurring topics or domains
- Existing folder structure and what each folder seems to contain
- Any explicit project description in existing files
- Any existing CLAUDE.md-like routing instructions

**Branch B: 0 markdown files exist (empty-content path, H-2 fix).**

The vault has only assets, no markdown to read. Drive identity from non-content signals:

1. **Folder name signals:** subfolder names in the source are strong topic hints. `./research/` → topic "research". `./meeting-notes/` → topic "meeting-notes". `./marketing/` → topic "marketing". List every distinct subfolder name as a candidate topic.
2. **Asset filename signals:** binary filenames carry topic hints. `auth-spec.pdf` → topic "auth". `Q1-budget.xlsx` → topic "budget". Extract distinct topical nouns from filenames; rank by frequency.
3. **Manifest categories:** the restructure-manifest's File Inventory shows `category` per file. If most assets fall into one category (e.g., all `asset` PDFs in `research/`), this is a strong project-type signal.
4. **Conversion decision (manifest top-level):** if `conversion_decision: declined`, note that the user wants assets to stay binary; CLAUDE.md should describe how to surface them in Obsidian/search rather than how to use them as wiki pages.

Draft a SKELETAL CLAUDE.md from these signals, with explicit "[CONFIRM IN MCQ]" markers on every uncertain field. Move to B1 with EVERY governance + identity field marked as a gap requiring MCQ answer.

**Precedence rule (both branches):** MCQ user answers > conversation context > file content evidence (Branch A) OR folder/asset/manifest signals (Branch B) > default templates.

Draft a complete CLAUDE.md using the template from `references/vault-structure.md`, populated with the above findings. Identify gaps (fields you could not infer with confidence) and prepare MCQ questions for them. Move to B1.

### Step B1: Smart MCQ Interaction

Present the draft CLAUDE.md from B0.8 to the user: "Here is the CLAUDE.md I drafted from analyzing your files."

Then ask targeted MCQ questions for every gap identified in B0.8. Generate only what is actually uncertain — do not ask obvious questions.

Standard MCQs (ask each that is genuinely uncertain):
- "What is the primary purpose of this vault? [A] Code project documentation [B] Research / knowledge base [C] Ops / workflow management [D] Mixed"
- "Who uses this vault? [A] Solo (just you) [B] Small team [C] Could be shared publicly"
- "What should the navigation protocol load first? [A] hot.md — current state [B] index.md — full map [C] A specific page (which one?)"

Governance MCQs (always ask — file analysis cannot infer these):
- "What topics or folders should this vault never include?" (exclusion boundary, free text)
- "If two sources conflict, which wins?" (canonical source priority, free text)
- "When should content move to archive?" (archive policy trigger, free text)

reasoning.md preference (always ask):
- "Should this vault maintain a reasoning.md decision journal? [A] Yes — log every session's decisions and reasoning [B] No — skip it (saves token cost on every sync)"

Topic + seed-page MCQ (H-5, H-6 — always ask):
- **Pre-populate inferred candidates from B0.8 signals.** Before asking, list the topics that B0.8 inferred from folder names, asset filenames, and manifest categories. Format: "I inferred these candidate topics from your folder/file structure: [research, meeting-notes, budget]. Confirm or edit (3-5 topics, comma-separated)." User can accept, edit, or replace.
- Use final answers as topic seeds AND feed back into the CLAUDE.md draft from B0.8 (overrides any prior inference per the precedence rule).
- "Should I create initial wiki/ pages for those topics? [Yes / No]". If Yes: B2 creates one stub per topic with frontmatter `type: reference, title: <topic>, description: "Load this page when you need to know about <topic>.", status: active, maturity: placeholder, created: <today>, updated: <today>` and a body containing only `# <topic>\n\n_(placeholder — populate via /vault-sync conversation crystallization)_`. The `maturity: placeholder` tag is critical: vault-lint Check 22 (empty-vault) excludes placeholder pages from its substantive-page count, so freshly seeded stubs do NOT falsely pass the empty-vault check.

**Precedence rule:** MCQ user answers ALWAYS take precedence over file evidence. If file content suggests "code project" but the user picks "research / knowledge base", write CLAUDE.md as research. The user knows their intent.

Incorporate the user's answers into the draft. If the user says "looks right" without changes, proceed. If they correct anything, update and show the revised version once before proceeding.

### Step B2: Create the Vault Structure

Create these files in the current working directory (only those missing):

```
./CLAUDE.md
./wiki/hot.md
./wiki/index.md
./wiki/log.md
./wiki/session-handoff.md
./wiki/reasoning.md         (only if reasoning_log: enabled — see B2.5)
./.vault-config.yaml
```

Lazy-load `references/vault-structure.md` here. Use the templates exactly. Populate from B1 context.

**Pre-existing file rule:**
- If a required file exists and has meaningful content: do NOT overwrite. Append a reconciliation note: `[BOOTSTRAP NOTE: file existed before vault was initialized — review and reconcile]`
- Exception: hot.md, session-handoff.md, and reasoning.md are always written correctly by vault-sync even if stubs exist (they are session-state files, not durable knowledge)
- If a file is an empty stub or `[RESTRUCTURE STUB]` marker: replace it with the full template
- The `[RESTRUCTURE STUB]` marker on CLAUDE.md must be removed when CLAUDE.md is finalized in B1

**CLAUDE.md rules (non-negotiable):**
- Under 80 lines
- Routing instructions only — no content
- Must include Navigation Protocol section with hot.md first, index.md second
- Must include vault structure map
- Never modified by SYNC mode after creation

### Step B2.5: Write .vault-config.yaml

Write `.vault-config.yaml` at vault root with the user's preferences from B1:

```yaml
reasoning_log: enabled    # or disabled
# future preferences land here
```

If `reasoning_log: disabled`: do NOT create `wiki/reasoning.md`. Skip Step B4.7. The Sync flow will also skip S6.7 and S8.5 reasoning archival.

### Step B3: Populate hot.md with Session Summary

Write the current session's context into hot.md following the template. Include:
- Current state (what was built/decided today)
- Active decisions (with status: DONE / IN PROGRESS / DEFERRED)
- Outstanding items
- Next session entry point (what to load first)

### Step B4: Populate index.md

Create the index with one entry per wiki page that exists. Format: `- [filename](filename) — one-line description`

### Step B4.5: Write wiki/session-handoff.md

Use the template. Populate from the current conversation:
- **Where It Started**: stated goal or problem at session open
- **Decisions Locked + Shipped**: any choices made and locked
- **Key Files**: files created, with absolute paths
- **Running State**: any servers or processes started (or "Clean")
- **Verification**: how to confirm the bootstrap is still valid
- **Deferred + Open Questions**: anything explicitly set aside
- **Pick-Up Entry Point**: ordered sequence to resume

If the conversation provides insufficient context for a section, write "none" — do not invent content.

### Step B4.7: Create wiki/reasoning.md (only if enabled)

Skip this step if `.vault-config.yaml` has `reasoning_log: disabled`.

Create `wiki/reasoning.md` and write the first entry for this bootstrap session:
- **Goal**, **Starting assumption**, **Decisions made**, **Alternatives rejected**, **How thinking changed**, **Next assumption to test**

This is the permanent decision journal.

### Step B5: Append to log.md

```
[YYYY-MM-DD HH:MM] BOOTSTRAP — Vault created. Source: chat session. Files created: CLAUDE.md, wiki/hot.md, wiki/session-handoff.md, [wiki/reasoning.md,] wiki/index.md, wiki/log.md, .vault-config.yaml.
```

### Step B6: Report to User

Show a summary:
- All files created with their paths
- CLAUDE.md content for user confirmation
- `.vault-config.yaml` contents (so the user sees their preferences locked in)
- Any fields needing the user to fill in (placeholder stubs)

### Step B7: Handoff Guidance (next-step instructions)

After Bootstrap completes, provide explicit next-step instructions tailored to the vault state:

- **If `raw/` has converted-unreviewed files** (from vault-restructure obsidian-import conversion): "Review the raw/ files. Promote substantive content to wiki/ via conversation + /vault-sync. Skip files that don't add value."
- **If wiki/ has only `maturity: placeholder` stubs**: "These are seed pages from your topic answers. Fill them via conversation + /vault-sync. Until then, they will not pass the empty-vault check."
- **If you have Obsidian installed**: "Open this folder as an Obsidian vault to get file tree, graph view, backlinks, search, and PDF embedding for free. The 3 skills handle structure; Obsidian handles consumption."
- **If you do NOT use Obsidian**: "Surface binaries via `wiki/restructure-manifest.md` (lists every asset path) or `find ./assets -type f`. PDF embedding is not available; reference assets via path links from wiki pages."
- **Always**: "Run /vault-lint after your first real work session to confirm vault health."

Show this guidance once at the end of Bootstrap. Do not repeat in subsequent Sync runs.

---

## SYNC Mode

**When to use:** CLAUDE.md exists and is not a restructure stub. Update the vault with knowledge from this session.

### Step S0: Mandatory Token Preview

Before any reads or writes, estimate scope and show the user:

```
vault-sync estimate — [vault-name]
Mode: Sync
wiki pages in index: N
Manifest detected: [yes / no]
Compacts since last clear: N (from .vault-session-state.yaml, see S0.3)
Estimated pages to read: N (based on candidate scope and index size)
Estimated pages to write: N (hot.md, session-handoff.md, [reasoning.md,] + routing targets)
Approximate token range: LOW–HIGH

Proceed? [Enter to continue / type 'n' to cancel]
```

Wait for explicit user confirmation. If the user cancels, stop here.

The `Compacts since last clear` field is populated by Step S0.3, which runs immediately after this preview is shown. On the very first run after the compact-awareness feature ships, the state file will not exist yet and this line will read `Compacts since last clear: 0 (state file initializing)`.

### Step S0.3: Compact Detection + State Update

Runs immediately after S0, before any other reads or writes. Purpose: track how many `/compact` operations have accumulated in this session so Step S9.5 can warn when quality is at risk.

**State file:** `.vault-session-state.yaml` at vault root (operational, never human-facing — see Hard Rule 12). Schema:

```yaml
compact_count: 0
last_seen_compact_fingerprints: []  # short hashes of compact-marker blocks already counted
last_updated: 2026-05-27T00:00:00Z
last_warning_fired: null  # ISO timestamp of most recent clear-not-compact warning, or null
marker_pattern_matched: "Previous conversation was compacted"  # records which marker text was detected, for forward-compat
```

**Logic:**

1. **Load state.** Read `.vault-session-state.yaml` if it exists. If missing or malformed, initialize defaults in memory (`compact_count: 0`, empty fingerprint list).

2. **Scan context for compact markers.** Look in the current conversation context for compact-summary markers. Primary literal: `Previous conversation was compacted`. Also accept close variants (e.g., `conversation was compacted`, `compacted conversation summary`) — Claude Code's exact wording may evolve. Record whichever variant matched in `marker_pattern_matched` so the brittleness is visible if it breaks.

3. **Fingerprint each marker.** For each marker block found, compute a short hash: first 12 characters of SHA-256 over the marker line plus ~200 characters of surrounding context (enough to make each compact event unique).

4. **Increment counter for new markers only.** For each fingerprint NOT present in `last_seen_compact_fingerprints`: increment `compact_count` by 1 and append the fingerprint to the list. This makes the step idempotent — running vault-sync twice in one session does not double-count.

5. **Detect /clear.** If the current conversation appears fresh (no prior assistant turns visible in context, no compact markers detected, only the current user prompt and system messages) AND `compact_count > 0`: assume the user ran `/clear`. Reset `compact_count` to 0, clear `last_seen_compact_fingerprints`. Leave `last_warning_fired` as historical record. Note "/clear detected — counter reset" in the S9 report.

6. **Write state back.** Save updated `.vault-session-state.yaml` with `last_updated` set to now (ISO 8601).

7. **Backfill token preview.** Update the `Compacts since last clear: N` line in the S0 preview output with the current count.

### Step S0.5: Stale File Detection

Runs at the start of every Sync session. Catches drift since the last vault-restructure run.

```bash
find . -maxdepth 3 -name "*.md" | sort
```

**Vault meta-file exclusion (apply BEFORE comparison, no exceptions):**
The manifest only inventories user content. The following vault meta files are NEVER expected in the manifest's File Inventory and must be excluded from the "unrecognized" set:
- `./CLAUDE.md`
- `./.vault-config.yaml`
- `./wiki/hot.md`, `./wiki/index.md`, `./wiki/log.md`, `./wiki/session-handoff.md`, `./wiki/reasoning.md`
- `./wiki/restructure-manifest.md`, `./wiki/vault-index.md`
- Anything under `./wiki/reasoning_archive/` or `./wiki/log_archive/`

Without this exclusion, every freshly Bootstrapped or Sync-updated vault produces 8+ false-positive "unrecognized" files, masking real drift.

**If `wiki/restructure-manifest.md` exists:**
- Read it. Validate: must contain `type: restructure-manifest`, `schema_version: "1.1"` or higher (older versions are tolerated but warn that re-running vault-restructure would upgrade schema), `conversion_decision` top-level field, and File Inventory rows with `Conversion State` and `Derivative Of` columns. If any required field is missing for schema 1.1 vaults, treat as corrupted and fall back to comparing against `wiki/index.md`.
- If validation fails (corrupted manifest): fall back to comparing against `wiki/index.md`. Warn user: "Manifest appears corrupted, falling back to index.md for stale file detection."
- Otherwise:
  - **Additions**: files on disk not listed in manifest → unrecognized
  - **Deletions**: manifest-listed files no longer on disk → remove those entries from manifest, note in S9 report
  - **External moves**: file content matches a manifest entry but path differs → flag for user review, update manifest entry

**If no manifest exists:**
- Compare `find` output against `wiki/index.md`
- Identify any markdown files not listed in the index → unrecognized

**Double-missing fallback:** if BOTH manifest and `wiki/index.md` are missing or malformed: skip stale detection entirely, proceed to S1, note in S9 report that vault state could not be verified.

**Handle unrecognized files:**
- **0 unrecognized**: proceed directly to S1
- **1-2 unrecognized**: handle inline. Classify each by reading content, determine destination, inject frontmatter if needed, add to wiki/index.md, update manifest if it exists. Log each action. Then proceed to S1.
- **3+ unrecognized**: pause. Tell the user: "I found N unrecognized files added since the last vault-restructure run. [list them]. Recommend running /vault-restructure first to route and catalog them properly. Continue with Sync only? [Yes / No]"
  - If user says continue: process only conversation-derived candidates (S1-S9) and leave unrecognized files untouched. Note them in the S9 report as "files outside vault catalog."

### Step S1: Scan the Conversation for Knowledge Candidates

Lazy-load `references/durability-filter.md` and `references/crystallization-protocol.md` here.

Read the entire conversation. Extract every statement, decision, discovery, or insight. List as raw candidates — do not filter yet.

Categories to look for:
- Decisions made (architecture choices, naming decisions, approach selections)
- Things built or created (files, systems, documents, diagrams)
- Principles established or confirmed
- Procedures learned or documented
- Context that will matter next session
- Anything the user explicitly flagged ("remember this", "save this", "important")

### Step S2: Apply the Durability Filter

Test each candidate against the 5 criteria. Pass = at least 1 criterion met.

Show the user a brief tally: "X candidates found. Y passed the filter. Z discarded."

Do not proceed with discarded candidates. Do not explain each rejection unless the user asks.

### Step S3: Apply the Four-Layer Taxonomy

For each candidate that passed, extract all four layers where the conversation provides them:

| Layer | Question to ask |
|---|---|
| Declarative | What is the rule/fact/decision? |
| Procedural | How is it done? |
| Contextual | Why does it exist this way? |
| Conditional | When does the rule change? |

A candidate with all four is a knowledge object. If the conversation doesn't provide a layer, leave it blank rather than inventing it.

### Step S4: Map Candidates to Existing Wiki Pages

Read `wiki/index.md` to see what pages exist.

For each knowledge candidate, identify which existing wiki pages it touches. One candidate may touch multiple pages. One page may be touched by multiple candidates. This is the crystallization pattern — route each piece to everywhere it belongs.

If a candidate doesn't belong in any existing page, create a new page. Update index.md accordingly.

### Step S5: Update Wiki Pages

Lazy-load `references/contradiction-handling.md` here.

For each page that needs updating:

1. Read the existing page (full content, not headings only — full reads are required for coherent integration)
2. **Write-time contradiction check:** before integrating, scan the full page (not just the target section) for semantic conflicts with the new candidate. If a conflict exists: stop integration for this page, flag it via the contradiction-handling protocol, surface to the user. Never overwrite a contradicting claim silently.
3. Integrate the new knowledge — do not append blindly. Weave into the existing structure.
4. Update the `updated:` date in YAML frontmatter if present
5. If the page warrants `confidence:` (research with uncertain claims) or `supersedes:` (this page replaces an older one): set those fields

**New page creation — born-linked rule (Section 9.1.2):**

When S4 determines a candidate requires a new wiki page (no existing page covers it), apply this gate before writing:

1. **Overlap check first:** scan `wiki/index.md` one more time for semantic overlap with the new page topic. Headings-only scan is sufficient. If an existing page covers the same domain: route there instead. Do not create a new page.

2. **Link scan:** if a new page is genuinely warranted, run `grep -rh "^#" wiki/*.md` to collect all headings from existing wiki pages. Identify any existing pages whose headings semantically relate to the new page's topic.
   - **If 1+ existing pages relate:** add a `related:` frontmatter field listing those page filenames. Insert at least one `[[page-name]]` wikilink in the new page body. Set frontmatter `status: active`.
   - **If no existing pages relate:** set frontmatter `status: draft`. Flag in the S9 report: `"New page [name] is unlinked — add at least one inbound wikilink before promoting to status: active."`

3. **Minimum frontmatter for all new pages:**
   ```yaml
   type: <standard|framework|decision|playbook|procedure|research|reference|raw-intake|archive>
   title: "<page title>"
   description: "<one-sentence routing trigger: what question does this page answer?>"
   status: draft   # or active if born-linked
   maturity: hypothesis   # default for substantive new pages
   created: <YYYY-MM-DD>
   updated: <YYYY-MM-DD>
   ```
   Do not create a new page without this frontmatter. A page without frontmatter is a file, not knowledge. Note: `log` is NOT a valid type — use `reference` for index-style pages and `procedure` for step-by-step guides.

**Do NOT update CLAUDE.md.** It is routing-only. It never changes after Bootstrap.

### Step S6: Update hot.md

Rewrite hot.md entirely. This is a fresh current-state snapshot, not an append.

Use this exact section structure (include all sections, write "none" for empty ones):

```
# Hot Cache — [vault-name]

**Updated:** YYYY-MM-DD

## Current State
[What is live right now. Completed work, active builds, shipped decisions.]

## Active Decisions
[Choices made and locked this session — with status: DONE / IN PROGRESS / DEFERRED]

## Active Hypotheses
[Named assumptions being tested. Format: "Hypothesis: [claim] — Status: [testing / confirmed / rejected]"]

## Outstanding
[Items deferred, blocked, or queued for next session. One line each.]

## Episodic Trace
[Rejected approaches from this session. Format: "[Rejected: <approach>] — <one-line rationale>"]
[Only write this section if something was explicitly tried and discarded. Write "none" if nothing was rejected.]

## Next Session Entry Point
[Numbered: (1) files to load in order, (2) skill or command to invoke, (3) first concrete action]
```

**30-line cap (Section 9.2.2):** hot.md must stay under 30 lines total. If the rewrite would exceed 30 lines: compress Active Decisions to one line each, drop completed items from Current State, and move any item older than this session to session-handoff.md instead. Flag in the S9 report if compression was applied.

### Step S6.5: Write wiki/session-handoff.md

Overwrite entirely. All 7 sections must be present (use "none" or "Clean" for empty sections — do not skip):

- **Where It Started**: stated goal or problem at session open
- **Decisions Locked + Shipped**: every architectural, naming, or approach decision finalized
- **Key Files**: every file created or meaningfully modified — absolute paths only
- **Running State**: servers, background processes, build pipelines, env vars active at close. "Clean" if none.
- **Verification**: steps to confirm the work still holds
- **Deferred + Open Questions**: anything set aside, 1-line context each
- **Pick-Up Entry Point**: numbered, copy-pasteable: (1) files to load in order, (2) skill or command to invoke, (3) first concrete action

Never loaded proactively. Exists only for when the user asks "what happened last session."

### Step S6.7: Append to wiki/reasoning.md (only if enabled)

**Preference check:** read `.vault-config.yaml`. If `reasoning_log: disabled` (or the file doesn't exist and CLAUDE.md doesn't declare a preference): skip this step entirely. Do not create, read, or update reasoning.md.

If enabled: append one new entry. Do not overwrite. Do not reformat existing entries.

Populate by scanning the full conversation:
- **Goal** — match the actual stated goal
- **Starting assumption** — include any assumption that turned out wrong
- **Decisions made** — every significant choice with the explicit WHY
- **Alternatives rejected** — most valuable field, do not skip even if minor
- **How thinking changed** — what shifted; "none" if nothing did
- **Next assumption to test** — surfaces hidden dependencies

If exploratory with no concrete decisions, still append a short stub.

### Step S7: Update index.md

If new wiki pages were created in S5, add them to index.md. One line per page: `- [filename](path) — one-line description of what's in this page and when to load it`

### Step S8: Append to log.md

```
[YYYY-MM-DD HH:MM] SYNC — Source: chat session. Candidates: X found, Y passed filter, Z discarded. Pages updated: [list]. New pages created: [list or "none"]. Contradictions flagged: [count or "none"]. session-handoff.md updated. [reasoning.md appended.]
```

Omit the `reasoning.md appended` clause if `reasoning_log: disabled`.

### Step S8.5: File Length Guard

Skip entirely if `reasoning_log: disabled` (no reasoning.md to archive).

After appending to reasoning.md and log.md, check line counts.

**reasoning.md threshold: 400 lines**

If reasoning.md exceeds 400 lines:
1. Keep the 8 most recent entries live, regardless of month. The entry just appended is never archived in the same run.
2. Identify oldest archive-eligible entries. Entries are delimited by `---` on its own line and open with `[YYYY-MM-DD HH:MM]`. Never split an entry.
3. Archive by calendar month into `wiki/reasoning_archive/YYYY-MM.md`. Copy full entry text verbatim. If file exists, append only entries whose timestamp is not already present.
4. In reasoning.md, replace the extracted block with: `[YYYY-MM] ARCHIVED -> reasoning_archive/YYYY-MM.md. Sessions archived: N. Live recent sessions may remain below. Themes: [2-3 key decision themes].`
5. If a pointer line for that period already exists, update its session count/themes — do not duplicate.
6. Add archive file to wiki/index.md under `## Archives`. Match by path, not label. Format: `- [reasoning_archive/YYYY-MM.md](reasoning_archive/YYYY-MM.md) - Reasoning archive for YYYY-MM (N sessions)`
7. Repeat 2-6 until reasoning.md is under 400 lines (preferably under 300), or only the 8-entry active window remains.
8. If the 8-entry window alone exceeds 400 lines, stop and report: `S8.5: threshold exceeded, active window retained in full.`

**log.md threshold: 150 lines**

If log.md exceeds 150 lines:
1. Identify entries older than 90 days (one per line, format `[YYYY-MM-DD HH:MM] ...`)
2. Move to `wiki/log_archive/YYYY.md`, grouped by year. Append only lines not already present.
3. Replace the moved block with: `[Before YYYY-MM-DD] ARCHIVED -> log_archive/YYYY.md.` No duplicate pointer lines.
4. Add archive to `## Archives` in index.md if not already present (match by path). Format: `- [log_archive/YYYY.md](log_archive/YYYY.md) — Operation log archive for YYYY`

**Idempotency rules:**
- Archive files are append-only. Match entries by timestamp (reasoning) or full line content (log). Never duplicate.
- Pointer lines in reasoning.md / log.md: one per archive period, update in place.
- index.md Archives section: match by file path, not label.

If neither threshold is crossed: skip silently.

### Step S9: Report to User

Show:
- Pages updated (with what changed in 1 line each)
- New pages created (if any)
- Contradictions flagged (user must resolve, not the skill)
- Discarded candidates (brief list, not explanations)
- Stale file actions from S0.5 (additions handled, deletions removed, files outside vault catalog)
- Confirmation that CLAUDE.md was NOT modified
- Confirmation that reasoning.md was appended (or "skipped — reasoning_log disabled")

**Shallow ingestion check:** if this Sync touched fewer than 3 wiki pages, append a warning:
> Low crystallization: only N pages updated. Was this session's knowledge fully woven into the vault? The crystallization protocol can route one source to up to 15 pages.

Advisory only, not a block.

**Next-action hint (sparse, exception-based only):**

After the report, output ONE of the following. Do not output multiple. Do not output if no condition is met.

- `→ Run /vault-restructure` — fires when: S0.5 found 3+ unrecognized files and the user continued Sync anyway, OR the manifest was missing or corrupted, OR a `[RESTRUCTURE STUB]` was detected in CLAUDE.md.
- `→ Run /vault-lint` — fires when: this run created at least one non-placeholder knowledge page (new page with `maturity: hypothesis` or higher) OR touched 3+ wiki pages, AND there is no lint entry in `wiki/log.md` from the last 7 days. Check log.md for a line containing `LINT` within the last 7 days.
- Output nothing — if neither condition met. Do not write "Clean" or any other filler.

The lint threshold is NOT "any new page was created." It is "substantive pages created AND no recent lint." Firing on every run trains the user to ignore it.

### Step S9.5: Clear-Not-Compact Banner (compact-aware)

Runs immediately after S9, as the final user-facing output. Purpose: when 4+ compacts have accumulated in this session, tell the user to `/clear` instead of `/compact` next, and hand them a paste-ready resume prompt for the fresh session.

**Trigger:** `compact_count >= 4` (from `.vault-session-state.yaml`, updated in S0.3).

If the trigger does not fire, output nothing and end the run.

**When triggered:**

1. Read the freshly-written `wiki/hot.md` and `wiki/session-handoff.md` (just written in S6 and S6.5, so they reflect current session truth).

2. Extract four fields:
   - **Active focus**: first line under hot.md's "Active Focus" / "Current Focus" section
   - **Last decision**: most recent entry in hot.md's "Active Decisions" / "Recent Decisions" section
   - **Open thread**: first unresolved item from session-handoff.md's "Open Questions" / "Open Threads" section (or "none" if blank)
   - **Next action**: from session-handoff.md's "Pickup Point" / "Next Action" section

3. Output the following banner verbatim, with the four bracketed fields filled in from step 2 and N replaced with the current `compact_count`. Do NOT write this banner to any file — it is user-facing output only.

```
================================================================
STOP COMPACTING — TIME TO /clear
================================================================
You've accumulated N compacts in this session. Quality degrades
past 4 consecutive compacts (cache misses + summarization drift).

NEXT ACTION:
1. Run /clear (not /compact)
2. Paste the resume prompt below into the fresh session

----------------------------------------------------------------
RESUME PROMPT (copy everything below this line):
----------------------------------------------------------------

Read wiki/session-handoff.md for full prior-session context.
Current state snapshot:
  - Active focus: [active focus from hot.md]
  - Last decision: [last decision from hot.md]
  - Open thread: [open thread from session-handoff.md]
  - Next action: [next action from session-handoff.md]
Continue from the pickup point above.

----------------------------------------------------------------
This warning will keep appearing on every vault-sync until /clear
is detected. Counter resets to 0 after /clear.
================================================================
```

4. Update `last_warning_fired` to the current ISO 8601 timestamp in `.vault-session-state.yaml`. Do NOT touch `compact_count` — it only resets on detected `/clear` (Hard Rule 13).

**Do not reprint full session-handoff.md content.** The resume prompt points to the file; the four-field snapshot is the only freshly-synthesized content.

---

## Hard Rules

1. **Never modify CLAUDE.md after Bootstrap.** Routing-only, under 80 lines. Content goes in wiki pages.
2. **Never auto-resolve contradictions.** Flag with context. Surface to the user. The user decides.
3. **Never invent content.** If the conversation doesn't provide information for a layer or field, leave blank or stub. Do not fill gaps with plausible-sounding content.
4. **Never store one-off comments or context noise.** The durability filter exists for this reason.
5. **hot.md is always rewritten, never appended.** Current-state snapshot, not history. log.md is the history.
6. **session-handoff.md is always overwritten, never appended.** Most recent session only. Never loaded proactively.
7. **reasoning.md is always appended, never overwritten — except for lossless archival compaction (S8.5).** Permanent decision journal. One entry per SYNC, no exceptions. Skip entirely if `reasoning_log: disabled`.
8. **No em dashes in any output.** Use commas, periods, or colons.
9. **reasoning.md and log.md self-compress at 400 / 150 lines.** Archives in `wiki/reasoning_archive/` and `wiki/log_archive/`, indexed under `## Archives` in index.md. Archives are never deleted. reasoning.md retains the 8 most recent entries live.
10. **Token preview is mandatory at every run start (B0 / S0).** Never bypass. User must confirm before reads or writes.
11. **Manifest is consulted, not bypassed.** S0.5 always runs in Sync mode. B0.5 always runs in Bootstrap mode.
12. **`.vault-session-state.yaml` is operational, never human-facing.** Never link to it from index.md, never quote its contents in user reports beyond the one-line compact count in the S0 token preview. It is not a wiki page.
13. **`compact_count` resets ONLY on detected `/clear` (S0.3 step 5).** Never reset on warning fire, never reset manually inside the sync pipeline. The S9.5 warning is designed to persist until the user actually clears, which is the whole point of the feature.

---

## Reference Files (lazy-load at decision points)

- `references/vault-structure.md` — file templates: CLAUDE.md, hot.md, session-handoff.md, reasoning.md, index.md, log.md, wiki page (YAML + claim callouts). Load only when creating files (B2 / S5 new-page creation).
- `references/durability-filter.md` — 5 criteria, pass/fail examples. Load before S1.
- `references/four-layer-taxonomy.md` — declarative/procedural/contextual/conditional. Load before S3.
- `references/crystallization-protocol.md` — route knowledge across multiple pages (1 source, up to 15 pages). Load before S1.
- `references/contradiction-handling.md` — surface conflicts without auto-resolving. Load before S5.
