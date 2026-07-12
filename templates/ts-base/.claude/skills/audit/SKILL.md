---
name: audit
description: Fresh-context audit of a completed unit with reify-to-test triage. Use after a feature or module is complete, or on demand for a named scope.
---

# /audit <scope: directory, module, or diff>

1. Launch the `auditor` agent (fresh context, read-only) on the named scope.
   Pass the scope verbatim. Do not add "find bugs" framing: the auditor's
   prompt is neutral by design, and "none found" is a valid outcome.
2. Triage every finding by reifying it into a test:
   - Write a test that reproduces the finding.
   - Test fails on current code = real bug: report it and propose the fix
     (apply only if the human asks).
   - Test passes on current code = the finding was confabulated: discard it
     and delete the test.
   - Low-confidence findings without a reproduction are leads, not facts:
     list them separately, do not act on them.
3. Log the outcome in `AGENT-LOG.md`: N findings, N real, N confabulated.
   This ratio calibrates how much to trust future audits.
