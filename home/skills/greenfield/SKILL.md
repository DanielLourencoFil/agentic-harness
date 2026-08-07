---
name: greenfield
description: Greenfield branch of kickoff - spec interview, layer selection, then the PLAYBOOK kickoff checklist. Routed to by /start for a fresh scaffold; use when starting a brand-new project from an idea.
---

# /greenfield <one-line idea>

Reached via /start (greenfield branch). If there is existing code here, stop and
use /brownfield - this rite assumes an empty scaffold.

The playbook's kickoff checklist assumes a project plan exists. This rite
produces it. No scaffolding, no `pnpm install`, no code before step 3.

## 1. Spec interview (one question at a time)

- What problem, whose problem, and how do they solve it today?
- What is IN scope for v1? What is explicitly OUT?
- What is the riskiest assumption, and what is the cheapest way to kill it? The kill criteria
  are a NAMED TEST - red if the assumption is false; if it needs the feature built first, a
  `test.skip`/`test.todo` carrying the assertion and a reason. NEVER a dated prose line, which
  is a reminder nothing runs (the lint gate keeps a skipped kill test visible, not silent).
- How will we know it worked? (a real-world metric, not a vanity metric)
- Which surfaces AND effects exist (selects the Layer 3 packs): DB? auth? public API?
  secrets/PII? queues? and, by effect not noun, any operation that must not double-apply
  (idempotency), any critical state mutation, any concurrent-write contention (atomicity)?
  A state-mutating action a user can repeat is a critical mutation even with no money in
  sight - ask by effect, or the noun-shaped question skips the pack that guards an invariant.
- Which stack? (selects the Layer 1/2 template)

## 2. Write the spec, propose the harness

Write `docs/SPEC.md`: what / why / scope in-out / kill criteria / metric.
Then propose the harness subset per `PLAYBOOK.md`, one line of justification
per layer ("load-bearing because X" / "skipped because Y"). Skipping layers
is correct; applying everything everywhere is the failure mode.

## 3. Only after the human approves the spec

Execute the KICKOFF CHECKLIST in `PLAYBOOK.md`: git init, copy the template,
empty-scaffold verify green, CI, ruleset.

Then stamp provenance (ADR 9): in each skill copied from the catalog
(`.claude/skills/*/SKILL.md`), add one frontmatter line

    source: agentic-harness@<sha>

where `<sha>` = `git -C ~/Dev/agentic-harness rev-parse --short HEAD`. The stamp
is what a future drift report compares against; a copy may diverge deliberately —
the stamp keeps the divergence visible instead of silent.

## 4. Before the first feature: /plan, not straight to code

The kickoff assembles the harness; it does not design the feature. Before writing any
interface, hand the first unit of work to `/plan` (one proposal per round, the human's
verdict each time), surfacing the design decisions that are the human's - especially the
ones that LOCK an interface (a persistence signature, an HTTP status map, a client/server
boundary), which cannot be deferred. For a genuinely single-feature project, run that
decision pass inline here before touching code rather than hopping to `/plan`. Proposing
layers or writing a signature before these are answered is the atropelo this step exists
to stop (ADR 52).

## Verifiable output

- `docs/SPEC.md` written: what / why / scope in-out / kill criteria / metric.
- The proposed harness subset, one justification line per layer.
- Empty-scaffold `pnpm verify` output shown green before any feature code.
- Every copied skill carrying its `source: agentic-harness@<sha>` stamp.
- The human-owned design decisions surfaced one per round, each interface-locking one
  answered (or routed to `/plan`) before its interface is written.
