---
name: kickoff
description: From idea to project - spec interview, harness layer selection, then the PLAYBOOK kickoff checklist. Use when starting a brand-new project from nothing but an idea.
---

# /kickoff <one-line idea>

The playbook's kickoff checklist assumes a project plan exists. This rite
produces it. No scaffolding, no `pnpm install`, no code before step 3.

## 1. Spec interview (one question at a time)

- What problem, whose problem, and how do they solve it today?
- What is IN scope for v1? What is explicitly OUT?
- What is the riskiest assumption, and what is the cheapest way to kill it?
  (pre-registered kill criteria, with a date)
- How will we know it worked? (a real-world metric, not a vanity metric)
- Which surfaces exist: DB? auth? money? queues? public API? secrets/PII?
  (selects the Layer 3 packs)
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
