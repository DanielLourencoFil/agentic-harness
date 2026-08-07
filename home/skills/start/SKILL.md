---
name: start
description: Neutral entry to project work - asks the greenfield-or-brownfield question that routes everything, then dispatches to /greenfield or /brownfield. Use before any scaffold, install, or edit when a project is not yet under way.
---

# /start

The greenfield/brownfield fork inverts the whole harness posture, so it is decided
first, by the human, before any action. Greenfield holds the repo to zero from line
one; brownfield holds the diff to the standard and the repo to a ratchet (see the
PLAYBOOK). Picking wrong poisons every downstream gate: a greenfield gate on legacy
demands retroactive perfection and CI drowns in pre-existing violations; a brownfield
ratchet on a fresh repo grandfathers debt into a clean scaffold.

## 1. Ask the human, before touching anything

One question, and no scaffold, install, or edit before it is answered:

> Is this a GREENFIELD project (empty repo, from nothing but an idea) or a
> BROWNFIELD one (an existing codebase you are entering)?

The classification is a human decision, never detected mechanically: a just-copied
template already has files, so a file count misreads a fresh scaffold as legacy. It
is trivial for the human to answer - the gate's only job is to make sure it is asked,
not skipped. That is also its honest limit: /start is steer, so a hook that hard-blocks
the first scaffold until the fork is declared stays a deferred option (a once-per-project
event did not earn it yet).

## 2. Route

- **Greenfield** run `/greenfield`: spec interview, layer selection, kickoff checklist.
- **Brownfield** run `/brownfield`: archaeology, zero-cost gates, baseline and ratchet.

Do nothing else here. This rite owns the fork and the handoff, nothing downstream.

## Verifiable output

- The green/brown question asked and answered before any scaffold, install, or edit.
- The matching skill (`/greenfield` or `/brownfield`) named as the next step.
