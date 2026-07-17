---
name: checklist
description: Checklist ritual for NON-code workflows only (go-live sequences, external submissions, bureaucracy, ops runbooks). Refuses code-implementation checklists and redirects to tests and the project /feature rite ("a plan is a view over tests"). Produces items with observable completion criteria, owners, and order.
---

# Checklist: non-code workflows with observable "done"

## Guard, before anything

If the request is about implementing code, do not produce a checklist. State the
standing doctrine: implementation plans are views over tests (a scenario that matters
becomes a named test; "done" = that test green in CI, never a ticked box), and the
project's /feature rite covers it. This skill exists for the world outside the repo.

## The four steps, in order

1. **Elicit in one pass:** the goal, the deadline (absolute date), known blockers, and
   who else is involved.
2. **Produce the checklist.** Every item carries:
   - a concrete action, verb first;
   - an observable completion criterion ("done when X is visible/confirmed");
   - an owner: Daniel, agent, or a named third party;
   - its dependency, when order matters.
3. **Third-party items get a follow-up date**, not just a hope. If the third party is
   silent past it, the follow-up action is already on the list.
4. **Offer to register** the checklist (or a pointer to it) in `~/Dev/BACKLOG.md`
   under the matching section, so it survives the session.

## Rules

v  the session.
