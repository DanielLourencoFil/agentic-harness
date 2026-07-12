---
name: feature
description: Feature implementation rite - spec interview, plan approval, negative tests first, evidence gate. Use when starting any new feature; the rite runs on invocation instead of from memory.
---

# /feature <short feature description>

Run the playbook's feature loop. Do not skip or reorder steps.

## 1. Spec interview (the human owns the answers)

Ask the human, one question at a time, and record the answers:

- What is ALWAYS true once this feature works? (becomes the positive tests)
- What must NEVER be possible? (becomes the negative tests: the cases AI forgets)
- Which state transition is forbidden? (becomes the impossible-case test)
- How would a malicious or careless user abuse this?

Write the resulting scenario checklist into `docs/SPEC.md`.

## 2. Plan before code

Propose a short plan: files affected, existing components to reuse (run the
reuse-scan first), and any scenarios you would add to the human's checklist.
Do NOT write production code until the human approves the plan.

## 3. Negative tests first

Write the negative tests from the checklist and show them failing. If you
cannot write a negative test, you do not understand the feature yet: stop
and ask.

## 4. Implement

Minimal diff until `pnpm verify` is green. Tests ship in the same commit as
the logic. Commit and push per the repo conventions.

## 5. Evidence and closeout

"Done" requires shown command output: verify green, plus the feature actually
exercised. No evidence = report status as "IMPLEMENTED - NOT VERIFIED" with
the exact command the human should run. If the project keeps a plan or
execution doc, update its matching entry now (the doc is a view over the
tests, never a parallel source of truth). Remind the human that a completed
unit gets `/audit` in a fresh context.
