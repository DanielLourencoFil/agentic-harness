---
name: refactor
description: Safe-refactoring rite - measure the safety-net's blind spots first, then change per unit. Use when restructuring existing code (splitting a large file, extracting a module, re-deciding an architectural choice), standalone or from /brownfield's change phase. Not entering a repo (/brownfield) nor adding one feature (/feature).
---

# /refactor

Refactoring is its own activity, distinct from entering a repo (/brownfield) and adding one
feature (/feature): it CHANGES the structure or decisions of code that already works, and the
danger is breaking behavior you cannot see. This rite makes the invisible measurable before
you touch a wall.

Boundary: /brownfield is day one in a repo; /feature ships one new behavior with its tests;
/refactor changes existing structure or decisions with a net. Reorganizing (behavior
preserved) and re-deciding (behavior changed) are two ACTIVITIES, never mixed in a commit; and
in brownfield re-deciding is the deliberate exception, not the default, because it must respect
decisions already made. Re-deciding is greenfield-native; brownfield inherits and constrains.

## 1. Measure the blind spots first

Mess destroys human readability, not the measurability of impact. The compiler, the tests, and
the call graph give the blast radius of a change whether the code is tidy or not - what mess
takes is the ability to PREDICT before measuring, so you run the tools instead of reasoning:
slower, not less safe. But those instruments have blind spots, and refactoring is dangerous
only there. Measure them before moving anything (this is the principle; the concrete list is
stack-specific):

- where `any` or an untyped cast silences the compiler,
- where no test covers the code, so the suite is silent,
- opaque serialization the type system never saw (JSON columns, `unknown` payloads),
- dynamic access (string-keyed dispatch, reflection) invisible to both,
- **untyped boundaries** - a client whose types are hand-written twins of the server's, so a
  shape change compiles clean on both sides and only breaks at runtime in someone's browser.

A gate has no light where these live. Measure with commands, show the output, never guess.

## 2. Light the load-bearing blind spot before trusting the instruments there

The blind spot that carries the most risk is lit first - typically an untyped boundary, because
every decision downstream manifests through it. Lighting it (typing the boundary once, a
runtime contract, or characterization at the seam) is often cheaper than either tidying or
re-deciding, and it makes everything after it measurable. HOW to light it is itself a /decide,
not a foregone answer.

## 3. Then, per unit - never the whole house at once

For each domain or module, in order, and only for what survives triage (do not tidy code you
are about to rewrite):

1. **Characterize** - pin what the code does today, even the wrong behaviors, with tests. The
   net, not a clean house, is the precondition for safe change; it is cheap and per-target.
2. **Tidy** - reorganize with behavior preserved (split, extract, rename, move). The
   characterization tests stay green; if one breaks, you changed behavior by accident. Drawing
   the new seams IS a small reversible decision: choose them, do not default them.
3. **Judge** - /audit for what is wrong, /decide for each architectural choice worth
   revisiting. This produces behavior change.
4. **Change** - the behavior change ships with its own red-first test, in its own commit.

Sequential and commit-separated PER UNIT; globally you may interleave units. Never tidy-all
then judge-all (months of blind polishing), nor mix reorganize and re-decide in one commit.

## 4. Where the criterion comes from

When you judge a decision, name the provenance of the standard: the repo's own ADRs and docs
are authority; where they are silent, your judgment is testimony (ADR 23), labeled as such,
never passed off as doctrine. Each re-decision records its own ADR.

## Verifiable output

- The measured blind-spot report (commands and output shown), naming where each instrument is
  blind, especially any untyped boundary.
- The load-bearing blind spot named, and how it will be lit (a /decide if non-trivial).
- Per unit: characterization tests green before any tidy; tidy commits behavior-preserved and
  separate from behavior commits; each re-decision carrying its own ADR and its provenance.
