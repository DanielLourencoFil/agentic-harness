# Project conventions — canonical, vendor-neutral

Every coding agent reads this file (the [agents.md](https://agents.md/) standard).
`CLAUDE.md` / `GEMINI.md` are one-line adapters pointing here — edit THIS file, never
the adapters. Only conventions tooling cannot enforce belong here; lint/type/test
rules are wired (see the configs), not written as prose.

## Values

correctness > trust > performance > dev speed. Never claim "done" without command
output as evidence — "compiles" ≠ "works". Run `pnpm verify` before declaring anything.

## Working rules

- Plan before code; minimal diff; one concern per commit (conventional messages).
- Read a file fully before editing; reuse-scan before creating any component/util.
- Names are grep-first: unique and searchable, no generic `handler` / `Manager` /
  `data`. Agents (and humans) navigate by search; a generic name is noise.
- A non-obvious constraint in code gets a one-line why-comment at the site pointing
  to its ADR (`// why: <constraint> (ADR N)`). Agents read the file they are
  editing, not the docs folder; the why must live where the risk is.
- Tests ship in the same commit as the logic. A test changes only when its requirement
  changes, in a dedicated commit. Never weaken a test to pass it.
- Isolate non-determinism (time, network, LLM, randomness) behind a fakeable seam;
  keep load-bearing logic pure and test it without mocks.
- A bug fix starts with a reproduction test shown failing, then turned green by the
  fix in the same commit — a fix without the red-first test is a hypothesis.
- Tests assert outcomes, never internal call sequences (interaction tests break on
  refactor while behavior holds). In test code, readable duplication beats clever
  shared helpers: each test reads as a spec on its own.
- Decisions → dated one-line ADRs in `docs/DECISIONS.md`, captured live. External
  sources are cited inline in the ADR they support, with a checked-on date.
- Commit atomically (verify-gated) and push the work branch without asking; merging
  to the default branch is the human's act — open a PR and stop.
- Agent-assisted commits carry a `Co-Authored-By` trailer naming the model; every PR
  fills the Provenance section of the template (tool, model + version, reviewer).

## Dependencies

- Stdlib-first: prefer the platform, the standard library, and deps already in
  `package.json` over adding a new one. A new dependency is a decision, not a reflex.
- One new dependency per PR, in its own commit, with a one-line why (and the
  alternative it beat) in the commit body; load-bearing picks get an ADR.
- Upgrades read the changelog first — never bump on version number alone.
- The lockfile is machine-written: never edit `pnpm-lock.yaml` by hand; it ships
  in the same commit as the `package.json` change that caused it.

## TypeScript

- Rely on inference internally; explicit types at public boundaries.
- `unknown` + narrowing, never `any`. Runtime validation at trust boundaries is
  schema-first (Zod), never decorator-based validators.

## Project specifics

<!-- Filled at kickoff: the architecture rule that defines this codebase, domain
     constraints, framework conventions (e.g. Vue: derived state = computed). -->
