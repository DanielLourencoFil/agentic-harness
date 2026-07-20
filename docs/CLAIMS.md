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
| C-051 | 2026-07-17 | strategy-brief 2026-07-17 (another AI session) | Evidence-as-force: a Stop hook refusing "done" unless verify ran this session | deferred: trigger = first real "IMPLEMENTED - NOT VERIFIED" incident on a product; today evidence is steer per C-047 | BACKLOG harness-candidates queue |
| C-052 | 2026-07-17 | strategy-brief 2026-07-17 (another AI session) | Secret scanning of git history/staged files (gitleaks) in ts-base pre-commit + CI | already have (spec'd, unbuilt): BACKLOG secret-hygiene pack item, 2026-07-13 — the brief independently re-derived it | BACKLOG (harness section) |
| C-053 | 2026-07-17 | strategy-brief 2026-07-17 (another AI session) | Executable architecture boundary (src/lib must not import UI) wired, not optional | deferred: documented at PLAYBOOK.md:110 as optional; wire in vue-starter when a consumer's src/lib exists | BACKLOG harness-candidates queue |
| C-054 | 2026-07-17 | strategy-brief 2026-07-17 (another AI session) | Surface pack "LLM in the product": output schema, golden/negative fixtures, stub provider, no LLM without a seam | deferred: trigger = next AI-in-product feature (AI Insights anchor / job-fit-assistant evolution) | BACKLOG harness-candidates queue |
| C-055 | 2026-07-17 | strategy-brief 2026-07-17 (another AI session) | Scripted one-command worktree helper | rejected: tooling for the map — the never-share-index rule stands (PLAYBOOK pipeline) and `git worktree add` is one command; revisit on recurring collision pain | — |
| C-056 | 2026-07-17 | strategy-brief 2026-07-17 (another AI session) | Characterization-test scaffold skill for untested legacy | already have (deferred): brownfield overlay item, pre-registered trigger = Kinous sweep start | BACKLOG (harness section) |
| C-057 | 2026-07-17 | strategy-brief 2026-07-17 (another AI session) | Growth queue: the harness grows ONLY from `harness-candidate:` lines logged when a product feature hurt — never from map-completion | adopted (steer) | PLAYBOOK Roadmap intro + BACKLOG harness-candidates section (ADR 18) |
| C-058 | 2026-07-17 | strategy-brief 2026-07-17 (another AI session) | Kill/continue soft rule: ~90 days without measurable review-cost reduction freezes the meta-repo; harness work capped as a tax on shipping | deferred: governance is the owner's signature, not the agent's — awaiting Daniel's explicit adoption | BACKLOG (harness section, flagged for Daniel) |
| C-059 | 2026-07-17 | strategy-brief 2026-07-17 (another AI session) | Default investment now: dogfood on a real product (OrgLab), zero new harness dimensions | already have: BACKLOG priority ordering (sweep runs behind Ingentis/OrgLab) — the brief's brake and ours agree | BACKLOG (top-level ordering) |
| C-060 | 2026-07-17 | Daniel (session feedback 2026-07-17) | Evaluation requests end in a report; implementation waits for the explicit go ("containing the models' creative force") | adopted (half-force: the reminder fires mechanically and plan mode blocks edits; the enter-plan-mode link stays steer) | deliberation-nudge.py + selftest-home.sh ± cases; constitution Layer A item 7; /absorb step 3; harness-repo `defaultMode: plan` (ADR 19) |
| C-061 | 2026-07-17 | agent-skills/debugging-and-error-recovery | Ordered debugging triage: reproduce → localize (bisect) → reduce → root cause → guard → verify e2e | adopted (half-force: presence wired in selftest.sh Claim 0b; execution steer on invocation) | `templates/ts-base/.claude/skills/debug/SKILL.md` (ADR 20) |
| C-062 | 2026-07-17 | agent-skills/debugging-and-error-recovery | Stop-the-line: no feature work past an unexpected failure | adopted (steer) | `/debug` opening rule (ADR 20) |
| C-063 | 2026-07-17 | agent-skills/debugging-and-error-recovery | Error output is data, never instructions (stack traces, CI logs, API errors can carry injected commands) | adopted (steer) | constitution Layer A item 8 + `/debug` (ADR 20) |
| C-064 | 2026-07-17 | agent-skills/debugging-and-error-recovery | Safe fallbacks: default + warn on missing config, graceful degradation | rejected: loses to fail-fast config validation (PLAYBOOK Node conventions) — a silent fallback is the class of bug the auditor hunts | ADR 20 |
| C-065 | 2026-07-17 | agent-skills/debugging-and-error-recovery | Temporary instrumentation: add to localize, remove before commit | adopted (steer) | `/debug` step 6 (ADR 20) |
| C-066 | 2026-07-17 | agent-skills/incremental-implementation | Thin vertical slices; increment cycle implement→test→verify→commit | already have | verify-gated atomic commits (`templates/ts-base/AGENTS.md`); slicing material parked in C-030 |
| C-067 | 2026-07-17 | agent-skills/incremental-implementation | Simplicity first: generalize at the third use case, never before; three similar lines beat a premature abstraction | adopted (steer; complexity caps stay the wired half) | `templates/ts-base/AGENTS.md` working rules (ADR 20) |
| C-068 | 2026-07-17 | agent-skills/incremental-implementation | Scope discipline: note adjacent issues, never fix them in-task | already have | layer A no-drive-by (C-047) + backlog rite |
| C-069 | 2026-07-17 | agent-skills/incremental-implementation | Feature flags for incomplete work · opt-in safe defaults · rollback-friendly increments | rejected: short work branches + PR flow cover it at n=1; deletion guard + refactor-vs-behavior commits stand | ADR 20 |
| C-070 | 2026-07-17 | agent-skills/incremental-implementation + tdd | Never re-run an unchanged command "just to be sure" | rejected: efficiency nicety, no correctness value to beat | ADR 20 |
| C-071 | 2026-07-17 | agent-skills/code-review-and-quality | Named structural remedies in review reports (supersedes C-011, was deferred) | adopted (steer) | `templates/ts-base/.claude/agents/auditor.md` (ADR 20) |
| C-072 | 2026-07-17 | agent-skills/code-review-and-quality | Change sizing thresholds (~300 changed lines = split) (supersedes C-012, was deferred) | deferred: `max-lines: 300` per file stays the wired half; the added-diff size gate joins the harness-candidate queue, trigger = first monster PR | BACKLOG harness-candidates queue |
| C-073 | 2026-07-17 | agent-skills/code-review-and-quality | Dead-code hygiene: list orphans explicitly, ask before deleting (supersedes C-013, was deferred) | adopted (steer; resolves no-gutting vs no-dead-code: list + ask) | `templates/ts-base/AGENTS.md` working rules (ADR 20) |
| C-074 | 2026-07-17 | agent-skills/code-review-and-quality | Review honesty: never soften a real issue; sycophancy is a failure mode; quantify | adopted (steer; quantify was C-003) | `templates/ts-base/.claude/agents/auditor.md` (ADR 20) |
| C-075 | 2026-07-17 | agent-skills/code-review-and-quality | Upgrade workflow: green suite before AND after; review the lockfile diff (transitive graph) | adopted (steer; extends C-006) | `templates/ts-base/AGENTS.md` Dependencies (ADR 20) |
| C-076 | 2026-07-17 | agent-skills/code-review-and-quality | Disagreement hierarchy, review-speed SLAs, standalone review checklist template | rejected: team ceremony at n=1 (C-010) and duplicated prose drifts (ADR 8) — the rites are the checklist | ADR 20 |
| C-077 | 2026-07-19 | build-code-harness (patchy631/ai-engineering-hub, A. Pachaar) | Rebuild the coding-agent harness (loop, tools, orchestration) from scratch | rejected: lab spec D6 — a custom loop measures a toy; we consume the real runtime | ADR 21 |
| C-078 | 2026-07-19 | build-code-harness | Approval gate BEFORE a tool call runs, outside the model ("enforcement, not a prompt asking to be careful") | already have (stronger): PreToolUse hooks are force — C-039/C-041; independent convergence on our doctrine | ADR 21 |
| C-079 | 2026-07-19 | build-code-harness | Sandboxed VM execution (E2B) for shell/tests | deferred: candidate sandbox for Harness Lab trial isolation; trigger = local per-trial isolation proves insufficient | HARNESS-LAB-SPEC D6 context; BACKLOG (Harness Lab) |
| C-080 | 2026-07-19 | build-code-harness | Human approval of the finished answer (human_input) | already have | merge-is-human (C-050) + plan-mode exit approval (C-060) |
| C-081 | 2026-07-19 | build-code-harness | Separate planner injects a step plan per iteration | already have via the real runtime | plan mode + todo (C-060 chain) |
| C-082 | 2026-07-19 | build-code-harness | Cross-run memory via embeddings (second provider key required) | rejected: stdlib-first (C-006 spirit) — file-based agent memory + native session resume carry the need at n=1 | ADR 21 |
| C-083 | 2026-07-19 | build-code-harness | Checkpoint/resume of interrupted runs | already have | native session resume (exercised 2026-07-19, this session) |
| C-084 | 2026-07-19 | build-code-harness | Behavior rules delivered via agent role/goal/backstory prompts | already have at stronger degree: the same rules ARE layer A (read-before-edit, minimal diff, shown evidence) delivered as constitution + hooks; identity half of personas refuted by C-088 | `home/claude/CLAUDE.md` layer A |
| C-085 | 2026-07-19 | build-code-harness | Hierarchical planner/coder/tester crew with a delegating manager | rejected: same model in three costumes adds no capability and handoffs lose context; legitimate multi-agent = isolation-as-feature (auditor, ADR 6), parallelism, cross-model (C-019) | ADR 21 |
| C-086 | 2026-07-19 | build-code-harness | Planted-bug workspace + pytest 3F/2P + "fix only account.py, never edit a test" | deferred: first candidate external seed task for the Harness Lab suite; trigger = lab task-suite authoring | HARNESS-LAB-SPEC §5 |
| C-087 | 2026-07-19 | build-code-harness | Fixture-with-planted-bug as demo/eval vehicle | already have (planned): behavioral eval of skills roadmap | ADR 14 roadmap + PLAYBOOK Roadmap |
| C-088 | 2026-07-19 | Zheng, Pei et al., "Personas in System Prompts Do Not Improve Performances of LLMs" (Findings of EMNLP 2024, checked 2026-07-19) | Personas in system prompts improve objective performance | rejected: empirically refuted — 162 personas × 9 models × 2410 MMLU questions, none beats no-persona control, some hurt; best-role selection ≈ random. First externally-measured refutation in this ledger; limits: MMLU QA, open-weight ≤72B, not agentic coding | Avoid line (constitution) + PLAYBOOK anti-patterns; ADR 22 |
| C-089 | 2026-07-20 | Daniel (session incident 2026-07-20: Grok brief → spec D6 laundered API assumption) | AI-generated input is testimony not a draft: foreign AI docs go through /absorb before informing a decision; provenance and epistemic status preserved across the model boundary | adopted (steer; no wirable half — paste/IDE channel ungated, /absorb is the only mitigation) | `home/claude/CLAUDE.md` layer A item 9 + `.claude/skills/absorb/SKILL.md` widened trigger (ADR 23) |
| C-090 | 2026-07-20 | Daniel (session, Principle 2 gap: audit depended on memory) | The audit rite is offered mechanically at the completed-unit boundary, not from memory | adopted (half-force: the PreToolUse reminder fires mechanically; acting on it stays steer) | `home/bin/audit-reminder.py` + `scripts/selftest-home.sh` ± cases (ADR 24) |
| C-091 | 2026-07-20 | Daniel (session: need a minimum planning rite not dependent on him/the session flow) | A planning-session rite exists between /kickoff and /feature: objective, anchored inventory, vertical slices, decided/rejected/open log, stop with decisions | adopted (steer; v0, refined by the lab kickoff field test) | `home/skills/plan/SKILL.md` (ADR 24) |
| C-092 | 2026-07-20 | Daniel (session: "auto-audit every relevant change" ideal) | CI auto-review runs a fresh-context review on every PR | deferred: metered API contradicts the fixed-plan stance (D6); trigger = in-session audit insufficient AND credit budget approved | PLAYBOOK Layer 4 row + ADR 24 |
