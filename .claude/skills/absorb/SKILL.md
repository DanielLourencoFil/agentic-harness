---
name: absorb
description: Absorb an external source (article, repo, skill, or ANY AI-generated artifact used to inform a decision - a brief, a spec draft, a review) into the harness via an anchored claim table - every "have it" carries a verified path, every adoption lands as a diff, ADR line and BACKLOG entry are the closing artifacts. Use when reviewing external engineering material, AND before building anything from a foreign AI document (ADR 23).
---

# /absorb <source: URL, file, or repo path>

Systematic absorption of one external source per run. The source is a quarry,
never a package: nothing is installed or vendored from it (WATCH stance); what
survives the table below enters the harness as our own diff, on our terms.

This rite also fires on **any AI-generated artifact used to inform a decision**
(a brief, a spec draft, a review from another model or session), including when
it will serve as a draft to build on (ADR 23). Building an artifact *from* a
foreign AI doc without this pass launders its unflagged assumptions into your
premises: the doc is testimony to evaluate, never a scaffold to inherit.

## 1. Grep the ledger, then read the source

`docs/CLAIMS.md` is the registry of every claim ever evaluated. Search
it for the source and its claims FIRST: a previously evaluated claim cites its
`C-NNN` row instead of being re-deliberated. Then read the source in full and
extract each discrete, actionable claim (a practice, a rule, a format, a
gate). Ignore prose that carries no instruction. Number the claims.

## 2. The anchored table (the output contract)

One row per claim:

| # | Claim (theirs) | Do we have it? | Action |
| --- | --- | --- | --- |

- **"Do we have it?"** is answered against THIS repo, and every "yes" or
  "partial" MUST carry a verified path (`file:line` or a command run now,
  output shown). An unanchored "yes" is a lie waiting to be found; write
  "hypothesis / not verified" if the anchor is missing (anchoring law).
- **Action** is one of: **adopt** (name the target file, the mechanism per
  the PLAYBOOK's Mechanism selection, and the enforcement degree the ledger
  records — force / half-force / steer, force preferred; a steer adoption
  states why it cannot be reified, and obedience that cannot be forced at any
  degree nor seen violated is decoration → reject) · **reject** (one line
  naming the value or ADR it loses to) · **already have** (the anchor says
  where) · **defer** (goes to BACKLOG with its pre-registered trigger).

## 3. Close with artifacts, not opinions

- Adoptions that fit this session: PROPOSE the diffs in the report and wait
  for the human's explicit go (ADR 19); then implement minimal-diff, gate
  first where a gate exists (the form gate must stay green).
- Adoptions that do not fit: one BACKLOG entry each, with trigger.
- **Append one ledger row per claim** to `docs/CLAIMS.md` (next free
  `C-NNN` id, dated; verdict from the closed set; anchor in the Where column).
  The table above is the working view; the ledger is what survives and what
  the next run greps.
- One dated ADR line for the source (adopted/rejected summary, source cited
  inline with a checked-on date), ready to paste into `docs/DECISIONS.md`.
- If a sweep is running, state the lot's adoption count against the
  pre-registered stopping criterion (a lot with <2 adoptions ends the sweep).

## Rationalizations this rite refuses

Replies are statements, never open questions.

| Alibi | Reply |
| --- | --- |
| "Their whole skill is good; just install it" | WATCH stance: an installed catalog propagates silent upstream changes (ADR 9). Steal rows, not repos. |
| "We obviously have this already" | Obviously means unanchored. The row gets a path or it gets "hypothesis / not verified". |
| "Adopt it all; more discipline is free" | Every steer line charges context in every session. A claim that does not beat a value or close a gap is rejected. |

## Verifiable output

- The claim table, every "yes"/"partial" row carrying a verified path or
  shown command output.
- The ledger rows appended to `docs/CLAIMS.md` (one `C-NNN` per claim).
- The diffs of same-session adoptions (or BACKLOG entries with triggers for
  deferred ones).
- The paste-ready dated ADR line citing the source.
