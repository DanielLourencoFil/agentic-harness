---
name: decide
description: Architecture/implementation deliberation ritual. Use when Daniel asks "qual a melhor forma de...", "devo usar X ou Y?", "como implementar...", or any design decision with more than one defensible path. Produces the problem restated, real alternatives with costs, trade-offs against his values, a recommendation with when-NOT, and a paste-ready dated ADR line. Not for settled questions or quick facts.
---

# Decide: deliberation in the write-up standard

Format for any architecture or implementation decision. The standard to match is the
Redis-lock write-up: alternatives named, what each layer buys stated, failure modes
admitted before being asked. "The choice is a decision, not a default."

## The five steps, in order

1. **Problem, no jargon (Portuguese).** What is being decided, which constraint or
   invariant is at stake, and what happens if nothing is decided.
2. **Real alternatives (2-4).** Always include the boring default and, when honest,
   "do nothing". For each: what it buys, what it costs, where it breaks. No strawmen:
   an alternative that only exists to lose does not belong on the list.
3. **Trade-offs against the values:** correctness > trust > performance > dev speed.
   Name the honest hole of the winning option out loud, before being asked.
4. **Recommendation + when-NOT.** One pick, plus the concrete conditions under which
   it flips to another option.
5. **ADR line.** Close with one dated line ready to paste into the project's
   docs/DECISIONS.md: "YYYY-MM-DD — <decision>. Trigger: ... Adopted: ... Rejected: ...".

## Rules

- Conversation in Portuguese; the ADR line in English.
- If the decision touches auth, billing, guards, or a core algorithm: stop after step 4
  and ask for confirmation before implementing anything (standing rule).
- If the alternatives cannot be compared honestly with what is known, say exactly what
  is missing and the cheapest way to get it (logs, docs, a spike). Never guess to keep
  the format moving.
- No em dashes in anything written to files.

## Verifiable output

- The five-step write-up itself: problem, real alternatives with costs, trade-offs
  against the values, recommendation with its when-NOT conditions.
- The closing dated ADR line, ready to paste into the project's docs/DECISIONS.md.
