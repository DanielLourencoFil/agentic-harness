---
name: plan
description: Planning-session rite for a body of work — the layer between /kickoff (project birth) and /feature (one feature). Use when breaking a chunk of work into an ordered, sliced, justified plan ("como implementar isto", "plano de implementação", "quebrar isto em tarefas", "por onde começo"). Produces a one-sentence objective, an anchored inventory, vertical slices sized to one session, a live decided/rejected/open log, and a stop with decisions. Not a single decision (/decide) nor a single feature (/feature).
---

# /plan <the body of work>

A planning session run as a rite, so the process lives here — not in anyone's
memory or the particular flow of a session (externalized memory, ADR 24). The
AI drives the questions; the human owns the answers. v0: the specced shape,
to be refined by real use at the first project kickoff.

## The steps, in order

1. **Objective in one sentence.** If it does not fit in one sentence, the scope
   is unclear — narrow it before proposing anything.
2. **Anchored inventory before proposing.** Read the relevant code and docs and
   state what already exists, each claim carrying a verified path (anchoring
   law). Never plan against an imagined repo.
3. **Slice vertically, never horizontally.** Each slice is one complete path
   that leaves the system working and testable — not "all the DB, then all the
   UI". Order by dependency and risk: the riskiest slice first (fail fast).
4. **Size each slice to one focused session.** An "and" in a slice's title
   means it is two slices; more than ~5 files touched means split it.
5. **One proposal per round.** Propose one slice (or one decision), take the
   human's verdict, then the next — never a wall of decisions at once.
6. **Live log: decided / rejected / open.** Keep a running list; a rejected
   option carries its one line of why, so it does not return next round.
7. **Checkpoints every 2-3 slices.** State must be green (tests pass, build
   clean) before proceeding — the natural place for the human to review.
8. **Stop with decisions, not prose.** End with the ordered slice list and the
   open questions named. The plan is a view over tests, never a parallel source
   of truth (ADR 6); each slice becomes a `/feature`.

## Rationalizations this rite refuses

Replies are statements, never open questions.

| Alibi | Reply |
| --- | --- |
| "The plan is obvious, let me just start" | An unwritten plan lives only in your head — the failure mode the harness exists to kill. Write the slices. |
| "Let me draft it all first, slice later" | A horizontal draft hides the dependency order and the risk. Vertical slices surface both now. |
| "One big slice is fine" | If its title needs an "and", it is two. Size each to one session. |

## Verifiable output

- The one-sentence objective and the anchored inventory (paths shown).
- The ordered vertical slices, each sized to one session, riskiest first.
- The decided / rejected (with why) / open log.
- Each slice named as a future `/feature`; the open questions listed for the human.
