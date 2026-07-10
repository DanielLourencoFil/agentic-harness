# RATIONALE — why these rules exist

The configs say *what* is enforced; this file says *why*. Rules never carry this
vocabulary — a lint rule is named `eqeqeq`, not "anti-equivocation". The mapping lives
here, for whoever asks.

## The organizing idea

An AI coding agent produces fluent output at near-zero cost. Fluency is not
correctness, and review capacity is the scarce resource. The harness therefore guards
four different things, with four different mechanisms:

| Category | Protects | Mechanism | Examples |
| --- | --- | --- | --- |
| **Validity rules** | the soundness of inferences the code embodies | lint / type rules (physical rejection) | `no-explicit-any` (one name, one meaning), `eqeqeq` (no coerced equality), `switch-exhaustiveness-check` (no ignored cases), import-cycle ban (no circular justification) |
| **Examinability rules** | the *feasibility* of refutation — an artifact too large to review is shielded from criticism regardless of its correctness | size/complexity caps | `max-lines: 300`, `complexity: 10`, minimal diffs, one concern per commit, deletion guard |
| **Procedure gates** | the honesty of the investigation itself | structural checks on artifacts | negative tests before code; audit findings require a reproduction; neutral audit framing (allow "none found"); pre-registered kill criteria for product bets |
| **Content judgment** | fitness to the actual problem | human review — deliberately NOT automated | are these the right scenarios? is this the right definition? is the design right? |

Two consequences worth stating plainly:

- **Tools verify form, never content.** A gate can check that a claim has a test
  attached; whether it is the *right* test is human judgment. Any claim that tooling
  "forces good design" is false and treated here as an anti-pattern.
- **Examinability is a first-class concern, not ergonomics.** Review-effectiveness
  research consistently shows defect detection collapsing on large changes; an
  unreviewable diff is unfalsifiable in practice. The size caps exist to keep every
  change inside the region where human refutation actually works — which matters
  doubly when the author is an AI that produces volume for free.

## How rules get generated

New rules are not collected from style guides; they are derived by asking, for each
known failure of reasoning or of process: *does it have a syntactic signature in
code?* If yes → lint/type rule. If it has a procedural signature → a gate on the
artifact. If neither → it stays with the human, explicitly.

Worked examples (2026-07-10): treating classic reasoning failures as a generator
produced three rules this template had missed — coerced equality (`eqeqeq`),
incomplete case analysis (`switch-exhaustiveness-check`), and circular dependency
between modules (import-cycle ban). The method is auditable in this repo's history.

## Lineage, honestly labeled

The decomposition-order-evidence-enumeration discipline that "clean code" popularized
is much older than software; the same precepts organize systematic method since early
modern rationalism, and computing itself descends from formal logic. This is stated
as genealogy, not as authority: the mapping earns its place only where it *generates*
enforceable rules or gates (see above), and is dropped where it merely renames.
