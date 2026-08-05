---
name: audit-tests
description: Fresh-context audit of a unit's TESTS — missing, wrong-level, or too weak to fail. Use after a feature is tested, or on demand for a named scope. Phase 1 of ADR 35; the mutation reify arm is Phase 2.
---

# /audit-tests <scope: directory, module, or diff>

The /audit rite checks whether the CODE is right. This one checks whether the
TESTS are worth anything. Separate on purpose: bug-framing and test-framing
dilute each other.

1. Launch the `test-auditor` agent (fresh context, read-only) on the named scope.
   Pass the scope verbatim. The auditor's prompt is neutral; "none found" is a
   valid outcome and must not be second-guessed into invented findings.
2. Triage each finding by KIND, because tests reify differently from bugs:
   - **Missing negative / could-never-fail:** reify by writing the missing test.
     It should be red now (the rule it guards is untested) and named for what it
     pins. A "missing test" finding that a written test proves already covered was
     confabulated: discard it.
   - **Wrong level:** structural. Name the move (test the endpoint, not the
     service; drop the mock of the unit under test). Do not rewrite unasked.
   - **Weak assertion:** this is the one only mutation can settle, and mutation is
     Phase 2 (not yet wired). Until then, flag it and let the human decide; do not
     dismiss it because the test is green — green is exactly the symptom.
3. **The authoring session RESPONDS; it does not judge.** This session wrote the
   tests and will rationalize them. State agreement or disagreement per finding
   WITH a reason, and leave the verdict to the human. Where Phase 2 is wired, a
   surviving mutant is the tiebreaker; until then, an unresolved weak-assertion
   finding stays open, not closed.
4. Log in `AGENT-LOG.md`: N findings, N reified-real, N confabulated, N left open
   for mutation. The ratio calibrates trust in future test audits.

## Rationalizations this rite refuses

Replies are statements, never open questions.

| Alibi | Reply |
| --- | --- |
| "The tests pass, so they are fine" | Passing proves they run, not that they can fail. A test green from birth tested nothing (2026-07-27). |
| "I wrote these tests; I can judge the audit" | The authoring session defends its own tests. The auditor is fresh (step 1); this session responds, the human decides (step 3). |
| "This weak-assertion finding is probably nothing" | Probably is unmeasured. It stays open until a mutant kills it or survives (Phase 2), never dismissed on a green run. |
| "Zero findings looks lazy" | "None found" is welcome. An invented finding costs a confabulation entry in the log. |

## Verifiable output

- The test-auditor's report: per-finding category, severity, confidence, and the
  concrete gap (test `file:line`, the forbidden input or surviving mutation).
- One test per reified missing-case finding, shown red, or discarded as confabulated.
- The authoring session's per-finding response, with reasons, verdict left to the human.
- The `AGENT-LOG.md` line: findings, reified-real, confabulated, open-for-mutation.
