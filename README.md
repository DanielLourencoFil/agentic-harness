# agentic-harness

**How I engineer software with AI agents — as an executable system, not advice.**

My thesis: you cannot prompt quality into an AI. Persona prompts ("act like a senior
engineer") are theater. There are only two levers that work: give the agent **good
procedures and real context**, and **mechanically reject bad output** — types, lint,
tests, hooks, CI. This repo is that system, in the exact form my agents consume at
project kickoff.

```
agentic-harness/
├── PLAYBOOK.md          # the assembly spec an AI reads at project kickoff
├── docs/DECISIONS.md    # dated one-line ADRs, sources cited inline
├── scripts/selftest.sh  # consumes ts-base as documented; run by CI on every push
└── templates/
    └── ts-base/         # the TypeScript quality cage — copy, don't rebuild
```

The harness is **agent-agnostic by construction**: conventions live in the vendor-neutral
`AGENTS.md` (with `CLAUDE.md`/`GEMINI.md` as one-line adapters), and the layers that
actually *force* quality — git hooks, CI, branch rulesets — are actor-blind. Which AI
sits on the other side is an implementation detail.

## How it works

Starting a new project is one instruction to the agent:

> "Read `PLAYBOOK.md` and this project plan. Assemble the harness and run the
> kickoff checklist."

The playbook is written **for the AI, not for humans** — layered and imperative:

- **Layer 0 — Universal:** every commit passes typecheck + lint + test (pre-commit
  *and* CI); zero warnings; deletion guard; decisions logged as dated one-line ADRs.
- **Layer 1 — Language (TypeScript):** the `ts-base` template — strict tsconfig,
  `no-explicit-any` / `no-floating-promises` / complexity caps as errors.
- **Layer 2 — Framework (Vue / React / Nest):** the enforceable rule subset per
  framework, plus the conventions linters can't catch (e.g. *derived state is
  `computed`, never a watcher* — the anti-pattern AIs inherit from their training data).
- **Layer 3 — Surface packs:** extra mandates when the project touches a DB, auth,
  money, queues, a public API, secrets/PII.
- **Layer 4 — Contextual:** a use-when/skip-when table. Skipping is a feature:
  applying every practice everywhere is the failure mode this repo exists to prevent.

Plus two operating routines: a **feature loop** (negative tests specified before
production code; "done" requires shown evidence) and an **audit routine** (fresh
context, neutral framing, every finding needs a concrete reproduction — findings are
hypotheses that must be reified into failing tests, because "find bugs" *manufactures*
bugs).

## Principles under it all

1. **Steer vs force.** If a rule can be a tool/test/hook, wire it; only what can't be
   reified goes into convention docs. Documented-but-unwired governance is a prayer.
2. **The harness is externalized memory.** No check depends on me remembering to ask.
3. **Fluency ≠ correctness.** AI output is the statistical center of its training data
   — average code, including institutionalized anti-patterns. Green CI ≠ good design;
   the semantic gap is closed by owned test scenarios and human review.
4. **Knowing ≠ applying.** Maturity is choosing which practices *not* to use.

Distilled from my projects, including a production SaaS, and held to its own standard:
this repo's CI runs `scripts/selftest.sh`, which consumes the template exactly as its
README instructs — the template's claims are gates, not prose. Each project feeds
lessons back into the playbook.
