# Durability Filter

A knowledge candidate is written to the vault if it passes at least ONE criterion. Fails all five = discard silently.

---

## The 5 Criteria

| # | Criterion | Test | Examples that PASS | Examples that FAIL |
|---|---|---|---|---|
| 1 | **Repeatable** | Applies to more than one situation in this project | "CLAUDE.md stays under 80 lines" (applies every session) | "Today I started at 9am" |
| 2 | **Reusable** | Another project or person could benefit from knowing this | "Use index files when a subfolder has 5+ pages" (universally useful) | "The Zoom link for Thursday's call" |
| 3 | **Principle-adjacent** | Relates to an existing decision, pattern, or standard already in the vault | A new exception to an existing rule, a refinement of an existing framework | A one-off workaround with no connection to anything |
| 4 | **Measurable** | Has a trackable outcome, metric, or performance implication | "Using hot cache reduced irrelevant context loading by ~60%" | "It felt faster" |
| 5 | **Human-flagged** | User said "remember this", "save this", "note this", "important", "keep this", or equivalent | User explicitly says "make sure to save this" | User says nothing — candidate is just mentioned in passing |

---

## Pass/Fail Examples

### PASS examples

**"We decided the CLAUDE.md routing file stays under 80 lines because Claude deprioritizes oversized files."**
- Criterion 1 (Repeatable): applies every time CLAUDE.md is edited
- Criterion 3 (Principle-adjacent): relates to the identity-tier architecture principle
- Result: PASS — write to wiki with all four layers

**"The durability filter has 5 criteria and a candidate passes if it meets at least one."**
- Criterion 1 (Repeatable): used in every SYNC operation
- Criterion 2 (Reusable): applicable in any OS project
- Result: PASS

**"Sam wants the system to be model-agnostic."**
- Criterion 3 (Principle-adjacent): relates to the Platform Independence design principle
- Criterion 5 (Human-flagged): stated directly by Sam as a requirement
- Result: PASS

**"The vault-sync email to Sam should not mention v3 or architecture changes — single hook only (update cycle)."**
- Criterion 1 (Repeatable): communication strategy for this project
- Criterion 5 (Human-flagged): explicit strategic decision in the session
- Result: PASS

### FAIL examples

**"Today we started working at 2pm."**
- Not repeatable, not reusable, no principle connection, no metric, not flagged
- Result: FAIL — discard

**"The Granola app icon is blue."**
- None of the 5 criteria
- Result: FAIL — discard

**"I need to get coffee before the next call."**
- Ephemeral, context-specific, no ongoing relevance
- Result: FAIL — discard

**"We mentioned the Karpathy pattern briefly."**
- Already captured in the vault (wiki/research/ has full Karpathy documentation)
- Result: FAIL — already captured, do not duplicate

---

## How to Apply the Filter

1. List all candidates from the conversation
2. Test each against all 5 criteria
3. If any criterion is met: PASS — proceed to four-layer taxonomy
4. If no criterion is met: FAIL — do not write, do not explain to user unless asked
5. Report the tally: "X candidates, Y passed, Z discarded"

**Do not explain each rejection.** The filter is a gate, not a justification engine. Only elaborate if the user asks about a specific discard.

---

## Edge Cases

**Already captured:** If a candidate is already documented in the vault (same content, same page), treat it as FAIL regardless of criteria. No duplicates. If the new candidate adds nuance or an update to existing content, that update is a PASS.

**Contradicts existing content:** Still a PASS — but flag the contradiction instead of writing silently. See `contradiction-handling.md`.

**Borderline cases:** When uncertain, apply criterion 5 as a proxy — "would a future-me find this useful in 3 months?" If yes, PASS. If probably not, FAIL.
