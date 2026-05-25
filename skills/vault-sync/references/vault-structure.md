# Vault Structure Reference

## Folder Layout

```
[project-root]/
├── CLAUDE.md                    ← routing file (NEVER exceeds 80 lines, routing only)
└── wiki/
    ├── hot.md                   ← current session cache (~500 words, rewritten each sync)
    ├── session-handoff.md       ← last session summary (overwritten each sync, load on demand)
    ├── reasoning.md             ← decision journal: why + how thinking evolved (append-only, pull on demand)
    ├── index.md                 ← one-line directory of every wiki page
    ├── log.md                   ← operation audit trail (append-only)
    └── [topic-pages].md         ← created as knowledge accumulates
```

Additional folders added as the project grows:
- `wiki/architecture/` — if architectural decisions accumulate
- `wiki/research/` — if research findings accumulate
- `wiki/decisions/` — if decision logs accumulate
- `raw/` — drop-inbox for unprocessed material (transcripts, PDFs, URLs)

Do not create subfolders pre-emptively. Create them when 3+ pages of the same type exist.

---

## CLAUDE.md Template

Fill in [BRACKETED FIELDS] from conversation context. If context is insufficient, use `[FILL IN: description]` as a stub.

```markdown
# [Project Name] — [Version or Status]

## Identity
[1-2 sentences: what this project is and who it's for]

## Navigation Protocol
1. Read wiki/hot.md FIRST — current focus and active decisions
2. Read wiki/index.md — one-line map of every wiki page
3. Load specific wiki pages by name — never load the full wiki/ folder
4. Load reference files on demand — only what the current task needs

## Vault Structure
[project-root]/
├── CLAUDE.md          ← you are here (routing only, <80 lines)
└── wiki/
    ├── hot.md         ← current session cache (read first)
    ├── index.md       ← page directory (read second)
    ├── log.md         ← operation audit trail
    └── [pages]/       ← load specific pages on demand

## Key Constraints
- CLAUDE.md stays under 80 lines (routing only — content lives in wiki/)
- No em dashes in any output
- [Any project-specific constraints from conversation]
```

**Rules:**
- Must stay under 80 lines after population
- If it exceeds 80 lines, move content to a wiki page and replace with a pointer
- Never add content here during SYNC mode — only created once in BOOTSTRAP mode

---

## hot.md Template

Rewrite entirely on every SYNC. This is not a log — it is a current-state snapshot.

```markdown
# Hot Cache — [Project Name]

**Updated:** YYYY-MM-DD

## Current State
- [Item]: [Status — DONE / IN PROGRESS / DEFERRED]
- [Item]: [Status]

## Active Decisions
- [Decision]: [Outcome and where it lives]
- [Decision]: [Outcome and where it lives]

## Outstanding
- [Item that needs to be done next session]
- [Item that is deferred with reason]

## [Optional: Communication drafts ready to send]
> [Paste the exact draft here if there is one waiting]

## Next Session Entry Point
[One sentence: what to load first and what to work on]
```

**Rules:**
- Updated date = today's date
- Current State: things that exist and are complete
- Active Decisions: choices that have been made and locked
- Outstanding: things that need to happen but haven't yet
- Optional section: only include if there is an actual draft/communication ready
- Next Session Entry Point: specific and actionable, not generic

---

## session-handoff.md Template

Overwrite entirely on every SYNC. Never append. Load only when the user asks "what happened last session" or needs to resume after a break.

```markdown
---
type: session-handoff
title: Last Session Handoff
description: "Load only when the user asks what happened last session or needs to resume after a break. Overwritten every SYNC."
updated: YYYY-MM-DD HH:MM
---

# Last Session Handoff

## Where It Started
[Context when this session opened: what was the stated goal or problem]

## Decisions Locked + Shipped
- [Decision] — [what it affects or where it lives]

## Key Files
- [absolute/path/to/file.md] — [what changed and why]

## Running State
[Servers, background processes, build states, env vars that were active at close. Write "Clean" if none.]

## Verification
- [Step to confirm the work from this session still holds]

## Deferred + Open Questions
- [Item] — [1-line context so it can be picked up cold]

## Pick-Up Entry Point
1. Load: [file1], [file2] (in this order)
2. Invoke: [skill or command if applicable, e.g. /ai-interview-coach — or "none"]
3. First action: [concrete, copy-pasteable instruction]
```

**Rules:**
- All 7 sections must be present, even if some are "none" or "Clean"
- Absolute paths only in Key Files — never relative
- Pick-Up Entry Point must be specific enough to paste into a new session's first message
- If nothing substantive happened (e.g. session was exploratory only), write a minimal stub — do not invent state
- Never load this file proactively — only when the user explicitly asks about the last session

---

## reasoning.md Template

Append-only. Never rewrite or delete existing entries. This is the permanent decision journal — it accumulates across every session and holds the full history of why things were built the way they were.

Load only when the user needs to: present their thought process, explain how a decision evolved, trace an idea from origin to its current form, or review what alternatives were rejected and why.

```markdown
# Reasoning Journal — [Project Name]

---

[YYYY-MM-DD HH:MM] — [Session topic or change in one phrase]

**Goal:** [What this session set out to do — 1 sentence]
**Starting assumption:** [What we believed was true when we started]
**Decisions made:**
- [Decision 1] — Why: [the reasoning, not just the outcome]
- [Decision 2] — Why: [the reasoning]
**Alternatives rejected:**
- [Option A] — Why rejected: [the reason]
**How thinking changed:** [What shifted from start to end of session — or "none" if it didn't]
**Next assumption to test:** [What this decision is predicated on that hasn't been proven yet]

---
```

**Rules:**
- Always append — never overwrite or delete existing entries
- One entry per SYNC (even if brief)
- "Alternatives rejected" is required whenever any approach was discussed and not chosen — this is the most valuable field for future presentation
- "How thinking changed" can be "none" — do not fabricate evolution
- "Next assumption to test" surfaces the hidden dependency in the current decision; write "none" only if truly nothing is uncertain
- If session was exploratory with no concrete decisions, write a short stub entry — do not skip the append entirely

**Archival exception:** Step S8.5 may move whole entries verbatim to reasoning_archive/YYYY-MM.md and replace them with an ASCII pointer line. This is lossless compaction, not deletion. The constraint "never overwrite" applies to session content, not archival pointers. reasoning.md keeps an active window of the 8 most recent entries live. Older whole entries may be archived even when they are from the current calendar month.

---

## index.md Template

One line per page. Load specific pages from this map — never load the full wiki folder.

```markdown
# Wiki Index — [Project Name]

One-line summary per page. Load specific pages by name — never load the whole folder.

## Core
- [wiki/hot.md](hot.md) — current active decisions and session state (always read first)
- [wiki/session-handoff.md](session-handoff.md) — last session summary: decisions, files, pick-up point (load on demand only)
- [wiki/reasoning.md](reasoning.md) — full decision journal: why things were built this way and what was rejected (load when presenting or tracing thought process)
- [wiki/log.md](log.md) — operation audit trail: timestamps and file counts (not decisions)

## [Category — add as pages accumulate]
- [wiki/page-name.md](page-name.md) — one sentence: what this page is and when to load it
```

**Rules:**
- Every page in wiki/ must have an entry here
- One line per page — description tells the AI when to load it, not just what it contains
- Add new entries immediately when new pages are created
- Group into categories when 5+ pages exist

---

## log.md Format

Append-only. Never rewrite. One line per operation. This is an audit trail of WHAT happened — for WHY decisions were made, see reasoning.md.

**Archival exception:** Step S8.5 may move entries older than 90 days to log_archive/YYYY.md and replace them with a pointer line. Content is never deleted.

```markdown
# Operation Log — [Project Name]

[YYYY-MM-DD HH:MM] BOOTSTRAP — Vault created. Source: chat session. Files created: CLAUDE.md, wiki/hot.md, wiki/session-handoff.md, wiki/reasoning.md, wiki/index.md, wiki/log.md.

[YYYY-MM-DD HH:MM] SYNC — Source: chat session. Candidates: X found, Y passed filter, Z discarded. Pages updated: [page1, page2]. New pages: [page3 or "none"]. Contradictions: [count or "none"]. session-handoff.md updated. reasoning.md appended.
```

---

## Wiki Page Template (for new pages created during SYNC)

```markdown
---
type: [decision | framework | research | procedure | reference | scenario]
title: "[Descriptive page title]"
description: "[One sentence: load this page when you need to know X — this is the LLM routing trigger]"
status: active
maturity: [hypothesis | tested | proven | standard]
created: YYYY-MM-DD
updated: YYYY-MM-DD
supersedes: [filename this replaces, or "none"]
related: [related-page-1.md, related-page-2.md]
tags: [tag1, tag2]
---

# [Page Title]

## Summary
One paragraph: what this page contains and why it exists.

## Content
[The actual knowledge — structured by what fits: rules, rationale, procedures, examples]

Use claim callouts to signal confidence level on every substantive claim:
> [!source] Verbatim quote or documented fact — cite the origin
> [!analysis] Inference drawn from evidence — show the reasoning chain, not just the conclusion
> [!unverified] Stated but not yet confirmed — prevents treating assumptions as facts
> [!gap] Known missing knowledge — what we don't know yet that matters here

## Decision Rules (if applicable)
- IF [condition] THEN [action]

## Links
- Related: [[related-page-1]], [[related-page-2]]
```

**YAML field rules:**
- `description:` is required — it is the routing trigger the LLM reads in index.md to decide whether to load this file
- `maturity:` tracks reliability: `hypothesis` (untested idea) → `tested` (tried once) → `proven` (validated repeatedly) → `standard` (locked in)
- `supersedes:` enables versioning — when you update a decision, point to the old file so the evolution is traceable
- `related:` is structured cross-linking in the frontmatter — must also appear in the Links section at the bottom

**Claim callout rules:**
- Every substantive claim should carry a callout — no naked assertions in the Content section
- `[!source]` is the highest confidence tier — only use with a direct quote or documented origin
- `[!analysis]` requires showing the reasoning chain, not just the conclusion
- `[!unverified]` prevents the LLM from treating working assumptions as confirmed facts
- `[!gap]` is as important as the others — known unknowns prevent hallucination fill-in
