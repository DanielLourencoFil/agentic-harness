---
name: brownfield
description: Brownfield branch of kickoff - entering an existing codebase. Archaeology first, zero-cost gates day one, baseline-and-ratchet for the rest, the diff held to the full standard. Routed to by /start when code already exists.
---

# /brownfield

Reached via /start (brownfield branch). If this is an empty scaffold, stop and use
/greenfield. The adaptation principle: hold the diff to the full standard; hold the
repo to a ratchet. The gate cannot demand retroactive perfection. (Full spec: the
BROWNFIELD section in `PLAYBOOK.md`.)

## 1. Archaeology before any change (read-only)

Map the system first. Write the story bible from observation: `AGENTS.md` with the
codebase's ACTUAL conventions (new code looks like the repo, not the model's training
data); `docs/DECISIONS.md` started now, decisions recorded as discovered, never
invented; a danger-zones list (money, auth, undocumented invariants).

## 2. Wire the zero-cost gates day one

They never touch legacy: prettier via lint-staged (staged files only), deletion guard,
commit conventions, secrets read-block, CI running whatever is already green.

## 3. Baseline + ratchet for everything else

Snapshot current violation counts (lint, type errors). The gate: counts may only fall,
CI fails on any increase. As a rule reaches zero in a directory, flip it to error there
permanently. Zero-warnings stays the greenfield rule; in brownfield it is a ratchet.

## 4. The diff is greenfield

New and changed code meets the full standard: strict rules on staged files, tests ship
in the same commit, evidence gate as always.

## 5. Characterization before modification

Untested legacy about to be touched gets characterization tests first - pin what the
code does, then change. Refactor commits never mix with behavior commits.

## 6. Audit-on-touch for inherited AI code

Code of unknown provenance is untrusted testimony: before building on an unpinned
module, run a scoped fresh-context audit and reify findings into tests. Expect
plausible-but-subtly-wrong plus each prior model's pattern drift.

## 7. Forbid the drive-by cleanup

No mass refactors, no repo-wide autofixes, no improving adjacent code inside a feature
commit. The deletion guard and the minimal-diff rule enforce this; the ratchet channels
improvement into deliberate, separate commits.

## 8. Provenance from day one, going forward

The past's provenance is unrecoverable; stop losing the future's (Co-Authored-By
trailer on agent commits, the PR provenance section).

## Verifiable output

- `AGENTS.md` written from the repo's actual conventions, plus a danger-zones list.
- The zero-cost gates wired and CI green on the existing tree.
- A baseline snapshot of violation counts, with the ratchet (counts may only fall) in CI.
- Characterization tests pinning any legacy touched, before it is modified.
