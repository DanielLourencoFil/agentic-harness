---
name: onboard
description: Deeply understand an existing codebase before, or independent of, changing it - purpose, structure, conventions, health, character, and the questions only a human can answer. Produces a personal, git-excluded onboarding map. Use on day one in any repo you did not write (a new job, a third-party repo, a handoff).
---

# /onboard [what you were told about the project, if anything]

The highest-leverage hour on any codebase is the first one: what you understand now
recapitalises into every later change. So this rite does NOT optimise for tokens or time.
Read deeply; depth is the feature, not the cost. Read-only: understand, do not change.

**The code is the source of truth; docs are testimony verified against it, never inherited.**
Docs (READMEs, architecture notes, ADRs) are claims about the code, and they rot - the classic
trap is buying a stale doc as ground truth and mapping a system that no longer exists. Derive the
map from the code; use docs as hints and for the WHY the code cannot state; and spot-check a few
load-bearing claims against the code, which calibrates how far to trust the rest.

Distinct from its siblings: `/brownfield` enters code TO CHANGE it (and leans on this rite for
the understanding); `/audit` hunts bugs adversarially. This rite only understands, and never
accuses.

## The map (write it as you go, one navigable doc)

Section by section, reading the code AND the git history, never guessing. State what you find;
mark what you could not determine as an open question, never an invention.

1. **Purpose and domain.** What does this project do, and for whom? Infer it from the code and
   any README when there are no docs. Name the domain in plain language.
2. **Structure and architecture.** The module map, the layer boundaries, the data flow, where
   the load-bearing logic lives, the entry points. A navigable sketch, not a tome.
3. **Conventions (the repo's ACTUAL style).** Naming, patterns, test style, error handling, how
   state and effects are organised - so your code will look like the repo, not like your
   training data. The guest-mode contract: their conventions win.
4. **State, health, and history.** Does it build and test (run the baseline, show the output)?
   Where are the gaps? Which files churn most (`git log`)? And the WHY behind the load-bearing
   files (`git log` and blame - history carries the reasons the docs do not).
5. **Character: virtues and vices.** Descriptive, never a bug hunt: what is clean and well
   tested, what is tangled or unpinned, where to tread carefully. Honest, not adversarial.
   Doc-vs-code divergence is itself a health signal: where docs match the code the team keeps
   them honest (a virtue); where they rot, that zone is neglected and its docs lie. Mapping
   where they agree, drift, or go silent charts what is cared for.
6. **Harness comparison.** Their discipline vs this harness - what they enforce and what they
   lack (tests, CI, types, hooks, budgets). For YOUR situational awareness only. Guest mode:
   you adapt to their repo on day one, you do not arrive with a list of what is wrong with it.
7. **Questions for the team.** The tribal knowledge you cannot infer: the why of a surprising
   decision, the deploy gotchas, the undocumented invariant, who owns what, and any doc that
   contradicts the code (which one is right?). This turns passive reading into active
   onboarding, and is often the most valuable page.

## Where the map lives (never contaminate their repo)

The map is PERSONAL and stays local. Exclude it with `.git/info/exclude` (a local, untracked
git exclude) so it never appears in `git status`, never gets committed, and never touches their
tracked `.gitignore`. In your own repo the `.gitignore` privacy block (`/notes/`) also serves.
It holds your evolving understanding and your candid read of the vices, and neither belongs in
their history.

## Verifiable output

- One personal onboarding map, git-excluded, with the seven sections filled from observation
  (open questions marked as such, never invented).
- The baseline shown: the build and test command run, with its output.
- The "questions for the team" list: the things the code could not tell you.
