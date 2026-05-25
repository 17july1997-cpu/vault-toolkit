# Four-Layer Taxonomy

Every knowledge candidate that passes the durability filter must be structured across four layers before being written to the vault. A summary covers only declarative. A complete knowledge object covers all four.

---

## The Four Layers

| Layer | Question to ask | What it captures |
|---|---|---|
| **Declarative** | What is the rule, fact, or decision? | The statement itself — what is true or decided |
| **Procedural** | How is it done? Step by step? | The process — how to execute or apply it |
| **Contextual** | Why does it exist this way? What's the history? | The reasoning — why this approach and not another |
| **Conditional** | When does the rule change? What are the exceptions? | The boundaries — edge cases, triggers, overrides |

---

## Examples

### Example 1: CLAUDE.md size rule

**Raw candidate from conversation:**
"We keep CLAUDE.md under 80 lines."

**Four-layer extraction:**

| Layer | Content |
|---|---|
| Declarative | CLAUDE.md routing files stay under 80 lines. Project files: under 80 lines. Global file: under 15 lines. |
| Procedural | If CLAUDE.md approaches 80 lines, move content to a new wiki page and replace with a one-line pointer to that page. Content belongs in wiki/, routing belongs in CLAUDE.md. |
| Contextual | Community research shows Claude deprioritizes and compresses oversized CLAUDE.md files. A 3,000-line file is not 40x more powerful than a 75-line one — it is actively worse. The routing file teaches navigation; content lives in the wiki. |
| Conditional | Under 80 lines for project-level CLAUDE.md. Under 15 lines for global CLAUDE.md (~/.claude/CLAUDE.md). These limits do not apply to wiki pages, which can be any length. |

---

### Example 2: Email strategy decision

**Raw candidate from conversation:**
"Don't send an email to Sam about v3 — save it for the meeting."

**Four-layer extraction:**

| Layer | Content |
|---|---|
| Declarative | The Sam follow-up email uses a single hook (update cycle) only. No mention of v3, architecture changes, MCP, or data ownership in the email. |
| Procedural | Send the email when Sam reaches out, not preemptively. Open Round 2 / the hiring conversation with v3 as a live demonstration. |
| Contextual | Describing improvements before Sam has finished reviewing what you sent creates noise and implies the original work was insufficient. Showing v3 in person is more powerful than announcing it via email. |
| Conditional | If Sam explicitly asks about architecture updates in his reply, then briefly acknowledge; otherwise, keep the email to the single update-cycle hook. |

---

### Example 3: Hot cache pattern

**Raw candidate:**
"hot.md is rewritten each sync, not appended."

**Four-layer extraction:**

| Layer | Content |
|---|---|
| Declarative | hot.md is a current-state snapshot. It is rewritten entirely on every SYNC, not appended to. |
| Procedural | On each vault-sync run: read the current conversation, extract what is live now, rewrite hot.md from scratch using the template. Do not preserve previous hot.md content unless it is still current. |
| Contextual | hot.md is not a log — it is a "what's happening right now" file. Old information in a hot cache is worse than no information, because it causes the next session to start with stale context. log.md is the history; hot.md is the present. |
| Conditional | If nothing meaningful changed in the session (e.g., a very short session with no decisions), hot.md may be left unchanged. Update only when there is something new to reflect. |

---

## How to Apply the Taxonomy

1. Take the raw candidate (what was said or decided in the conversation)
2. Ask each of the four layer questions in sequence
3. Fill in each layer from the conversation. If the conversation doesn't provide the answer, leave the layer blank. Do not invent.
4. A candidate with one layer = a note. Write it as a short bullet in the relevant wiki page.
5. A candidate with all four layers = a knowledge object. Write it as a full structured section or page.

**Blank layers are fine.** It means the conversation didn't cover that dimension. Leave them blank and let future sessions fill them in as the knowledge matures.

---

## When to Create a New Wiki Page vs. Update an Existing One

**Update existing page** when:
- The candidate adds to, refines, or updates something already documented
- The candidate is a sub-point or exception to an existing rule

**Create new page** when:
- The candidate introduces a distinct topic not yet in the vault
- 3+ candidates all relate to the same new topic (consolidate into one page)
- The candidate is a decision or event that deserves its own log entry

**Update index.md** whenever a new page is created.
