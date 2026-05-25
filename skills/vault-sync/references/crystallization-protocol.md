# Crystallization Protocol

One knowledge candidate does not go into one file. It bonds to every wiki page it touches. This is crystallization — not accumulation.

---

## The Core Rule

One source in. Up to 15 pages updated in a single pass.

**Why:** Knowledge in isolation is a note. Knowledge woven into a structure is institutional memory. When a decision is recorded in 5 places that reference it, each session that touches any of those 5 places has the decision in context. When it's recorded in 1 place, it's only accessible when that specific page is loaded.

---

## How to Route a Candidate to the Right Pages

For each candidate that passed the durability filter:

### Step 1: Read wiki/index.md

Get a full map of every existing page. This is your routing table.

### Step 2: Ask the routing questions

For each existing page, ask: "Does this candidate add to, refine, or inform what's on this page?"

| Page type | Route a candidate here if... |
|---|---|
| hot.md | The candidate is currently active, in progress, or affects the next session |
| index.md | A new page was created that needs an entry |
| log.md | Always — every SYNC gets a log entry regardless of what else changed |
| Architecture pages | The candidate establishes, changes, or refines a design decision |
| Research pages | The candidate adds to a body of research or contradicts existing findings |
| Rollout/phase pages | The candidate affects timelines, phases, or adoption sequencing |
| Decision log pages | The candidate is a significant decision that deserves its own record |
| Scenario/walkthrough pages | The candidate adds an example, edge case, or new scenario |

### Step 3: Write to each page that qualifies

Do not append blindly. Integrate. Ask: "Where in the existing structure does this fit?" Then weave it in.

**Bad (accumulation):** Add a new section at the bottom of the page with the new content.

**Good (crystallization):** Find the existing section this content belongs in. Add a row to a table, refine a paragraph, add a new subsection in the right place, update a status. The page should look like it was always written this way.

### Step 4: Update hot.md and log.md last

After all other pages are updated:
- Rewrite hot.md with the full current-state snapshot
- Append to log.md with what changed

---

## Routing Examples

**Candidate:** "We decided vault-sync should not modify CLAUDE.md after Bootstrap mode."

Routes to:
- `wiki/architecture/context-routing.md` — CLAUDE.md discipline section (principle reinforced)
- `wiki/hot.md` — active decisions updated
- `wiki/log.md` — operation logged

**Candidate:** "Sam's email draft is ready: [exact text]. Send it only when he reaches out."

Routes to:
- `wiki/hot.md` — draft stored in Communication Drafts section with send condition
- `wiki/log.md` — operation logged

**Candidate:** "The durability filter uses 5 criteria. 'Standard-adjacent' is renamed 'Principle-adjacent' for project-agnostic use."

Routes to:
- `wiki/problems/p1-extraction.md` — durability filter section updated
- `architecture-research/os-architecture-master.md` — Part 4 filter table updated
- `wiki/hot.md` — if this was a decision made today, Active Decisions updated
- `wiki/log.md` — operation logged

---

## How Many Pages Is Too Many?

Up to 15 is the guideline. In practice:
- Simple session decisions: 2-4 pages (hot.md + log.md + 1-2 content pages)
- Architecture decisions: 5-8 pages
- Major pivots or new systems: up to 15 pages

If a single candidate touches more than 15 pages, it is likely either:
- Too broad (break it into multiple candidates)
- Already well-documented everywhere (check whether it's already captured)

---

## What NOT to Do

**Do not create a new page for every candidate.** New pages are for genuinely new topics. Refinements and updates belong in existing pages.

**Do not append without reading first.** Always read the existing page before writing to it. You may find the candidate is already there, or that the integration point is in the middle of the page, not the end.

**Do not duplicate.** If the same content ends up in two places with identical wording, one of them is a duplicate. Instead, write it fully in one place and reference it from the other: "See [[source-page]] for full details."

**Do not update CLAUDE.md.** It is routing-only. If a candidate seems to belong in CLAUDE.md, it belongs in a wiki page with a pointer from CLAUDE.md. The pointer goes in CLAUDE.md; the content goes in the wiki.
