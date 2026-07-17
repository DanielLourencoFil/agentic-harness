# CLAIMS LEDGER — the single source of truth for what the harness claims

Every claim lives here, in one format and one ID space (ADR 16/17): the
guarantees the harness itself asserts (source: harness) and every externally
sourced claim ever evaluated (source: the external doc). This file answers
both standing questions in one grep:

- **"What does the harness assure, and at what degree?"** — the adopted rows,
  each carrying its enforcement degree. The degree mix (force / half-force /
  steer) is the measured guard against becoming one more prompt-and-pray
  skills repo; the selftest prints the mix on every run.
- **"Has this claim been evaluated before?"** — the entry point of the
  improvement pipeline: any incoming source resolves per claim to already
  addressed (cite the row) · new (evaluate) · better than ours (supersede by
  appending a row citing the old ID) · principle we lacked (adopt).

One row per claim per evaluation, appended, never edited: a row is a **dated
snapshot** — its anchor was verified on that date and may rot honestly, like
an ADR's checked-on date.

Rules:
- **Grep here first.** Every `/absorb` run starts by searching this file for the
  source and its claims; a previously evaluated claim cites its row instead of
  being re-deliberated.
- IDs are stable and sequential (`C-NNN`); the selftest rejects duplicates.
- Verdict is one of: **adopted** · **rejected** (with the value it loses to) ·
  **already have** · **deferred** (with its trigger in BACKLOG).
- **Every adopted row carries its enforcement degree, honestly labeled**
  (prefer force over steer — PLAYBOOK meta-rule): `(force)` wired as
  hook/lint/CI gate · `(half-force)` mechanical half wired, semantic half
  convention · `(steer)` rite text or convention, admitted only when the rule
  cannot be reified AND is load-bearing. A claim whose obedience cannot be
  forced at any degree, nor even be seen violated in review or audit, is
  decoration and is rejected. The selftest rejects a bare `adopted`.
- **Force rows cite their executor** (the selftest case, hook, or workflow
  that proves them), and every `scripts/selftest*.sh` gate must be indexed
  here — a new gate without a ledger row fails CI (coverage check). Honest
  limit: the checks verify existence and reference, not semantic match; the
  prose-to-gate correspondence stays human (ADR 1).

| ID | Date | Source | Claim | Verdict | Where |
| --- | --- | --- | --- | --- | --- |
| C-001 | 2026-07-17 | agent-skills/code-review-and-quality | Severity ladder Critical/Required/Nit/FYI on findings | adopted (steer) | `templates/ts-base/.claude/agents/auditor.md` (ADR 14) |
| C-002 | 2026-07-17 | agent-skills/code-review-and-quality | Order findings by leverage; never bury structural under nits | adopted (steer) | `auditor.md` (ADR 14) |
| C-003 | 2026-07-17 | agent-skills/code-review-and-quality | Quantify findings — counts, not qualifiers | adopted (steer) | `auditor.md` (ADR 14) |
| C-004 | 2026-07-17 | agent-skills/code-review-and-quality | Security and performance as review axes | adopted (steer) | `auditor.md` (ADR 14) |
| C-005 | 2026-07-17 | agent-skills/test-driven-development | Rationalization table: alibi → short declarative reply | adopted (steer) | `feature`/`audit`/`absorb` SKILL.md (ADR 14) |
| C-006 | 2026-07-17 | agent-skills review discussion (2026-07-15) | Dependency discipline: 1 dep/PR, changelog before upgrade, stdlib-first, lockfile never by hand | adopted (steer; wired half = weekly pnpm audit in CI) | `templates/ts-base/AGENTS.md` (ADR 14) |
| C-007 | 2026-07-17 | agent-skills review discussion (2026-07-15) | Skill instructions demand verifiable artifacts; open questions are decoration | adopted (half-force) | PLAYBOOK Mechanism selection + `scripts/selftest-skills.sh` (ADR 14) |
| C-008 | 2026-07-17 | agent-skills review discussion (2026-07-15) | Form limits on skills: 1-line description, body cap, mandatory output section | adopted (force) | `scripts/selftest-skills.sh` (ADR 14) |
| C-009 | 2026-07-17 | agent-skills (catalog) | Install the catalog / router skill | rejected: ADR 9 silent propagation + context saturation | ADR 14 |
| C-010 | 2026-07-17 | agent-skills/code-review-and-quality | Review-speed SLAs, multi-round reviewer process | rejected: team ceremony at n=1 | ADR 14 |
| C-011 | 2026-07-17 | agent-skills/code-review-and-quality | Named structural remedies in reviews (propose the move, not just the problem) | deferred: sweep lot 2 | BACKLOG (harness) |
| C-012 | 2026-07-17 | agent-skills/code-review-and-quality | Change sizing thresholds + splitting strategies | deferred: sweep lot 2 | BACKLOG (harness) |
| C-013 | 2026-07-17 | agent-skills/code-review-and-quality | Dead-code hygiene: list orphans explicitly, ask before deleting | deferred: sweep lot 2 | BACKLOG (harness) |
| C-014 | 2026-07-17 | agent-skills/doubt-driven-development | Fresh-context review before non-trivial output stands | already have | `templates/ts-base/.claude/skills/audit/SKILL.md:8`; PLAYBOOK routine audit (ADR 15) |
| C-015 | 2026-07-17 | agent-skills/doubt-driven-development | Adversarial reviewer framing ("find what is wrong") | rejected: neutral-prompt anti-confabulation; reify-to-test is the arbiter | ADR 15 |
| C-016 | 2026-07-17 | agent-skills/doubt-driven-development | Reviewer gets artifact + contract, never the author's claim or reasoning | already have | `audit/SKILL.md:9-10`; `auditor.md:7-9` |
| C-017 | 2026-07-17 | agent-skills/doubt-driven-development | Non-trivial decision definition (branching / boundary / type-unverifiable / irreversible) | adopted (steer) | `home/skills/decide/SKILL.md` (ADR 15) |
| C-018 | 2026-07-17 | agent-skills/doubt-driven-development | Bounded doubt loop (3 cycles) + doubt-theater flag | rejected: single-pass audit + AGENT-LOG real/confabulated ratio covers calibration | ADR 15 |
| C-019 | 2026-07-17 | agent-skills/doubt-driven-development | Cross-model second opinion (read-only sandbox, stdin piping) | deferred: trigger = audit miss from shared blind spot, or a 2nd model CLI present | BACKLOG (harness) |
| C-020 | 2026-07-17 | agent-skills/test-driven-development | Prove-it: a bug fix starts with a failing reproduction test | adopted (steer) | `templates/ts-base/AGENTS.md` + PLAYBOOK Layer 0 (ADR 15) |
| C-021 | 2026-07-17 | agent-skills/test-driven-development | Assert outcomes/state, never internal call sequences | adopted (steer) | `templates/ts-base/AGENTS.md` + PLAYBOOK Layer 0 (ADR 15) |
| C-022 | 2026-07-17 | agent-skills/test-driven-development | DAMP over DRY in test code | adopted (steer) | `templates/ts-base/AGENTS.md` (ADR 15) |
| C-023 | 2026-07-17 | agent-skills/test-driven-development | Double ladder: real > fake > stub > mock | already have | `templates/ts-base/AGENTS.md:24-25` fakeable seam; PLAYBOOK.md:39-40 |
| C-024 | 2026-07-17 | agent-skills/test-driven-development | Test pyramid percentages + small/medium/large taxonomy | rejected: quota-shaped; "lowest level that can catch the bug" does the work | ADR 15 |
| C-025 | 2026-07-17 | agent-skills/test-driven-development | Beyonce rule: behavior you rely on carries a test | already have | PLAYBOOK.md:41-44 human-owned checklist + tests ship with logic |
| C-026 | 2026-07-17 | agent-skills/test-driven-development | Browser runtime verification via DevTools MCP | rejected: Layer 4 E2E row covers it; no consumer yet | PR #13 table |
| C-027 | 2026-07-17 | agent-skills/test-driven-development | Subagent writes the reproduction test blind to the fix | rejected: ceremony at n=1; the auditor covers the audit case | PR #13 table |
| C-028 | 2026-07-17 | agent-skills/planning-and-task-breakdown | Plan before code, read-only, human approves | already have | `templates/ts-base/.claude/skills/feature/SKILL.md` step 2 |
| C-029 | 2026-07-17 | agent-skills/planning-and-task-breakdown | Standing tasks/plan.md + tasks/todo.md checklists | rejected: ADR 6 — plan docs are views over tests; hand-ticked checklists lie | ADR 15 |
| C-030 | 2026-07-17 | agent-skills/planning-and-task-breakdown | Vertical slicing, task sizing ("and" in title = two tasks), checkpoint cadence, contract-first parallelization | deferred: folded into the /plan rite item | BACKLOG (harness) |
| C-031 | 2026-07-17 | agent-skills/planning-and-task-breakdown | Highest-risk task first (fail fast) | already have | `.claude/skills/kickoff/SKILL.md:15-16` riskiest assumption |
| C-032 | 2026-07-17 | harness (ADR 1) | ts-base is consumed exactly as its README instructs; `verify` is green on the empty scaffold | adopted (force) | selftest.sh Claim 1, in CI on every push |
| C-033 | 2026-07-17 | harness (ADR 2) | AGENTS.md is canonical; CLAUDE.md/GEMINI.md are one-line adapters; settings.json valid | adopted (force) | selftest.sh Claim 0 |
| C-034 | 2026-07-17 | harness (ADR 6) | /feature + /audit rites and the auditor ship in the template; the auditor stays read-only | adopted (half-force) | presence + read-only tools line: selftest.sh Claim 0b; execution of the rites: steer on invocation |
| C-035 | 2026-07-17 | harness (ADR 1) | Commit #1 passes the pre-commit chain deletion-guard → lint-staged → verify | adopted (force) | selftest.sh Claim 2 |
| C-036 | 2026-07-17 | harness (ADR 1) | The deletion guard blocks a >80-line deletion unless explicitly overridden | adopted (force) | selftest.sh Claim 3 |
| C-037 | 2026-07-17 | harness (ADR 7) | The lint gate REJECTS violating code — any, eqeqeq, switch-exhaustiveness, no-cycle, max-depth each seen firing (no wired-but-blind rules) | adopted (force) | selftest.sh Claim 4 |
| C-038 | 2026-07-17 | harness (roadmap 2026-07-10) | vue-starter is consumed per its README; the gate rejects validity, vue and pure-core violations | adopted (force) | selftest-vue.sh |
| C-039 | 2026-07-17 | harness (ADR 10/13) | Writes outside the project root are denied — plain, `../` and symlink escapes — with a named allowlist (memory, scratchpad, data repo) | adopted (force) | write-containment.py + selftest-home.sh |
| C-040 | 2026-07-17 | harness (secret-hygiene 2026-07-13) | Secret-shaped prompts are blocked before leaving the machine | adopted (force) | secret-scan.py + selftest-home.sh |
| C-041 | 2026-07-17 | harness (secret-hygiene 2026-07-13) | Env-dumping commands (printenv, cat .env) are denied; the sanctioned substitution flow passes | adopted (force) | env-dump-guard.py + selftest-home.sh |
| C-042 | 2026-07-17 | harness (ADR 10) | Every home hook is wired in settings.json and executable — an unreferenced hook fails the selftest | adopted (force) | selftest-home.sh wiring section |
| C-043 | 2026-07-17 | harness (ADR 16) | Ledger contract: unique ids, closed verdict set, adopted rows carry a degree | adopted (force) | scripts/selftest-skills.sh ledger checks |
| C-044 | 2026-07-17 | harness (pipeline doctrine) | CI runs the selftests on every push AND every pull_request, never PR-only | adopted (force) | .github/workflows/selftest.yml `on:` block |
| C-045 | 2026-07-17 | harness (ADR 3) | Branch protection ruleset at kickoff: PR required, no force-push, required status check — binds every actor server-side | adopted (steer; force in the consumer repo once the ruleset is applied) | PLAYBOOK kickoff step 6 |
| C-046 | 2026-07-17 | harness (ADR 9) | Copied skills carry `source: agentic-harness@<sha>` provenance | adopted (steer; drift report deferred per ADR 12) | `.claude/skills/kickoff/SKILL.md` step 3 |
| C-047 | 2026-07-17 | harness (ADR 12) | Layer A anti-destruction: minimal diff, read before edit, no drive-by cleanup, no gutting, shown evidence, anchoring law | adopted (steer; read-before-edit is half-force via the harness, write containment is force) | `home/claude/CLAUDE.md` Layer A section |
| C-048 | 2026-07-17 | harness (ADR 6) | Plan/checklist docs are views over tests, never a parallel source of truth | adopted (steer) | PLAYBOOK Layer 0 + /feature closeout |
| C-049 | 2026-07-17 | harness (ADR 6) | Audits run fresh-context, neutrally framed, findings reified into tests | adopted (steer; auditor read-only is force per C-034) | `templates/ts-base/.claude/skills/audit/SKILL.md` + PLAYBOOK routine |
| C-050 | 2026-07-17 | harness (pipeline doctrine) | Commit/push of work branches is automatic; merge to default is always the human's act | adopted (steer; force once the consumer ruleset walls the default branch) | PLAYBOOK pipeline section |
