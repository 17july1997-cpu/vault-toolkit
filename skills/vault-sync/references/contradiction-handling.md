# Contradiction Handling

When new knowledge contradicts existing knowledge in the vault, do not auto-resolve. Surface the conflict to the user and stop.

---

## What Counts as a Contradiction

A contradiction exists when:
- New candidate states X, and an existing wiki page states not-X
- New candidate gives a different number, date, or name than what's documented
- New candidate reverses or invalidates a previous decision
- New candidate describes a process differently than the existing procedure page

**Not a contradiction:**
- New candidate adds nuance to an existing statement (this is an update, not a conflict)
- New candidate provides a conditional exception ("...unless X, in which case Y") — this extends the existing knowledge, not contradicts it
- New candidate says the same thing in different words

---

## What to Do When You Find One

### Step 1: Identify both sides clearly

Write out the conflict in plain language:
- **Existing (wiki/page-name.md, line/section):** "[exact quote or paraphrase of what the vault currently says]"
- **New (from this session):** "[exact quote or paraphrase of what the conversation said]"

### Step 2: Do not write either version

Do not update the wiki page with the new version. Do not leave the old version as-is and skip it. Both actions hide the conflict.

### Step 3: Surface it to the user

Present the contradiction clearly:

```
CONTRADICTION FLAGGED
Page: wiki/[filename].md
Existing: "[what the vault says]"
New: "[what this session says]"
Action needed: Which version is correct? Should I update the existing, keep both with a note, or discard the new one?
```

### Step 4: Wait for user decision

Do not proceed past the contradiction report until the user resolves it. Complete the rest of the SYNC (other pages, hot.md, log.md) but mark the contradicted page as pending.

### Step 5: Apply the user's decision

| User says | What to do |
|---|---|
| "Update to the new version" | Overwrite the existing content. Update `updated:` date. Add `supersedes:` note if the old content was a formal decision. |
| "Keep both" | Add a `[!unverified]` callout with both versions and the date of conflict. Do not pick a winner. |
| "Discard the new one" | Do not write the new candidate to any page. Log the discard in log.md. |
| "The existing is wrong — archive it" | Move the old content to a `deprecated` section or a separate archive page. Update the active page with the new version. |

---

## Log Entry for Contradictions

Always note contradictions in the log.md entry, even if resolved:

```
[YYYY-MM-DD HH:MM] SYNC — ... Contradictions: 1 flagged (wiki/architecture/context-routing.md — CLAUDE.md line limit). Resolved: user updated to new version.
```

---

## Common Contradiction Types in Practice

**Version conflicts:** A decision was made in a previous session and the current session reverses it. Most common with architecture choices.
Resolution: New version usually wins — but ask the user to confirm before overwriting.

**Number conflicts:** A metric, count, or date in the vault doesn't match what was said today.
Resolution: Check whether the vault number is dated (could be stale) or the session number is an estimate. Ask.

**Naming conflicts:** Something was called X in the vault and Y in this session.
Resolution: If intentional rename, update all pages. If accidental inconsistency, pick one and standardize.

**Scope conflicts:** A rule in the vault says "always" but this session introduced an exception.
Resolution: This is usually not a true contradiction — it is a conditional extension. Update the existing page to add the conditional rather than replacing the rule.
