---
name: audit-tests
description: Fresh-context audit of a unit's TESTS — missing, wrong-level, or too weak to fail. Use after a feature is tested, or on demand for a named scope. Phase 1 is the fresh-context find; Phase 2 is a named-list mutation probe that settles weak-assertion findings (ADR 35 + 59).
---

# /audit-tests <scope: directory, module, or diff>

The /audit rite checks whether the CODE is right. This one checks whether the
TESTS are worth anything. Separate on purpose: bug-framing and test-framing
dilute each other.

1. Launch the `test-auditor` agent (fresh context, read-only) on the named scope.
   Pass the scope verbatim. The auditor's prompt is neutral; "none found" is a
   valid outcome and must not be second-guessed into invented findings.
2. Triage each finding by KIND, because tests reify differently from bugs:
   - **Missing negative / could-never-fail:** reify by writing the missing test,
     but redness is only available when the code is BROKEN. Split by case:
     - *missing test over broken code* — the test is red now; that is the signal.
     - *missing test over CORRECT code* (the common brownfield case: the rule
       works, it just has no test) — the test PASSES on the first run, so redness
       proves nothing. Write it, name the mutation that must kill it, then run the
       PROBE (Phase 2): the named mutant must now DIE against the new test. A green
       test alone does not resolve it; the mutant dying does.
       (Verified against the first real run, 2026-08-05: six Criticals were
       missing tests over correct code; Phase 1 alone closed zero.)
     A "missing test" finding that a written test proves already covered was
     confabulated: discard it.
   - **Wrong level:** structural. Name the move (test the endpoint, not the
     service; drop the mock of the unit under test). Do not rewrite unasked.
   - **Weak assertion:** only mutation settles this, and Phase 2 wires it. Run the
     PROBE: apply the exact mutation the auditor named to the production code, run the
     suite, report live/dead. A surviving mutant IS the finding, proven; a dead one
     closes it with measurement. Do not dismiss on a green run — green is the symptom.
     The probe is a named list, not a full mutation run: it mutates only the flagged
     lines, so it is fast (seconds) and reaches code Stryker's src/lib scope does not
     (UI, route handlers) — where the ex-3 audit measured 16 survivors the reified tests
     then killed (ADR 59, refuting ADR 38's "UI is the least reward").
3. **The authoring session RESPONDS; it does not judge.** This session wrote the
   tests and will rationalize them. State agreement or disagreement per finding
   WITH a reason, and leave the verdict to the human. A surviving mutant from the probe
   is the tiebreaker that settles a weak-assertion finding; a finding is closed only
   when its named mutant dies.
4. Log in `AGENT-LOG.md`: N findings, N reified-real, N confabulated, N closed by the
   probe (named mutant killed). The ratio calibrates trust in future test audits.

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
- The `AGENT-LOG.md` line: findings, reified-real, confabulated, closed-by-probe.
- For each weak-assertion finding: the named mutation shown surviving, then killed by the
  reifying test (or left surviving, which keeps the finding open).
