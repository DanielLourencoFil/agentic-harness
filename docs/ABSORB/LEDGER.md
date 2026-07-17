# ABSORB LEDGER — every externally sourced claim, its verdict, and where it landed

The entry point of the improvement pipeline (ADR 16): when any external source
arrives — the skill of the week, an article, a demo — this file answers in one
grep which of four cases each claim is: **already addressed** (cite the row) ·
**new solution** (evaluate) · **better solution than ours** (re-evaluate;
supersede by appending a new row that cites the old ID) · **principle we did
not have in mind yet** (adopt). One row per claim per evaluation, appended by
the `/absorb` rite, never edited: a row is a **dated snapshot** — its anchor
was verified on that date and may rot honestly, like an ADR's checked-on date.

Rules:
- **Grep here first.** Every `/absorb` run starts by searching this file for the
  source and its claims; a previously evaluated claim cites its row instead of
  being re-deliberated.
- IDs are stable and sequential (`C-NNN`); the selftest rejects duplicates.
- Verdict is one of: **adopted** · **rejected** (with the value it loses to) ·
  **already have** · **deferred** (with its trigger in BACKLOG).

| ID | Date | Source | Claim | Verdict | Where |
| --- | --- | --- | --- | --- | --- |
| C-001 | 2026-07-17 | agent-skills/code-review-and-quality | Severity ladder Critical/Required/Nit/FYI on findings | adopted | `templates/ts-base/.claude/agents/auditor.md` (ADR 14) |
| C-002 | 2026-07-17 | agent-skills/code-review-and-quality | Order findings by leverage; never bury structural under nits | adopted | `auditor.md` (ADR 14) |
| C-003 | 2026-07-17 | agent-skills/code-review-and-quality | Quantify findings — counts, not qualifiers | adopted | `auditor.md` (ADR 14) |
| C-004 | 2026-07-17 | agent-skills/code-review-and-quality | Security and performance as review axes | adopted | `auditor.md` (ADR 14) |
| C-005 | 2026-07-17 | agent-skills/test-driven-development | Rationalization table: alibi → short declarative reply | adopted | `feature`/`audit`/`absorb` SKILL.md (ADR 14) |
| C-006 | 2026-07-17 | agent-skills review discussion (2026-07-15) | Dependency discipline: 1 dep/PR, changelog before upgrade, stdlib-first, lockfile never by hand | adopted | `templates/ts-base/AGENTS.md` (ADR 14) |
| C-007 | 2026-07-17 | agent-skills review discussion (2026-07-15) | Skill instructions demand verifiable artifacts; open questions are decoration | adopted | PLAYBOOK Mechanism selection + `scripts/selftest-skills.sh` (ADR 14) |
| C-008 | 2026-07-17 | agent-skills review discussion (2026-07-15) | Form limits on skills: 1-line description, body cap, mandatory output section | adopted | `scripts/selftest-skills.sh` (ADR 14) |
| C-009 | 2026-07-17 | agent-skills (catalog) | Install the catalog / router skill | rejected: ADR 9 silent propagation + context saturation | ADR 14 |
| C-010 | 2026-07-17 | agent-skills/code-review-and-quality | Review-speed SLAs, multi-round reviewer process | rejected: team ceremony at n=1 | ADR 14 |
| C-011 | 2026-07-17 | agent-skills/code-review-and-quality | Named structural remedies in reviews (propose the move, not just the problem) | deferred: sweep lot 2 | BACKLOG (harness) |
| C-012 | 2026-07-17 | agent-skills/code-review-and-quality | Change sizing thresholds + splitting strategies | deferred: sweep lot 2 | BACKLOG (harness) |
| C-013 | 2026-07-17 | agent-skills/code-review-and-quality | Dead-code hygiene: list orphans explicitly, ask before deleting | deferred: sweep lot 2 | BACKLOG (harness) |
| C-014 | 2026-07-17 | agent-skills/doubt-driven-development | Fresh-context review before non-trivial output stands | already have | `templates/ts-base/.claude/skills/audit/SKILL.md:8`; PLAYBOOK routine audit (ADR 15) |
| C-015 | 2026-07-17 | agent-skills/doubt-driven-development | Adversarial reviewer framing ("find what is wrong") | rejected: neutral-prompt anti-confabulation; reify-to-test is the arbiter | ADR 15 |
| C-016 | 2026-07-17 | agent-skills/doubt-driven-development | Reviewer gets artifact + contract, never the author's claim or reasoning | already have | `audit/SKILL.md:9-10`; `auditor.md:7-9` |
| C-017 | 2026-07-17 | agent-skills/doubt-driven-development | Non-trivial decision definition (branching / boundary / type-unverifiable / irreversible) | adopted | `home/skills/decide/SKILL.md` (ADR 15) |
| C-018 | 2026-07-17 | agent-skills/doubt-driven-development | Bounded doubt loop (3 cycles) + doubt-theater flag | rejected: single-pass audit + AGENT-LOG real/confabulated ratio covers calibration | ADR 15 |
| C-019 | 2026-07-17 | agent-skills/doubt-driven-development | Cross-model second opinion (read-only sandbox, stdin piping) | deferred: trigger = audit miss from shared blind spot, or a 2nd model CLI present | BACKLOG (harness) |
| C-020 | 2026-07-17 | agent-skills/test-driven-development | Prove-it: a bug fix starts with a failing reproduction test | adopted | `templates/ts-base/AGENTS.md` + PLAYBOOK Layer 0 (ADR 15) |
| C-021 | 2026-07-17 | agent-skills/test-driven-development | Assert outcomes/state, never internal call sequences | adopted | `templates/ts-base/AGENTS.md` + PLAYBOOK Layer 0 (ADR 15) |
| C-022 | 2026-07-17 | agent-skills/test-driven-development | DAMP over DRY in test code | adopted | `templates/ts-base/AGENTS.md` (ADR 15) |
| C-023 | 2026-07-17 | agent-skills/test-driven-development | Double ladder: real > fake > stub > mock | already have | `templates/ts-base/AGENTS.md:24-25` fakeable seam; PLAYBOOK.md:39-40 |
| C-024 | 2026-07-17 | agent-skills/test-driven-development | Test pyramid percentages + small/medium/large taxonomy | rejected: quota-shaped; "lowest level that can catch the bug" does the work | ADR 15 |
| C-025 | 2026-07-17 | agent-skills/test-driven-development | Beyonce rule: behavior you rely on carries a test | already have | PLAYBOOK.md:41-44 human-owned checklist + tests ship with logic |
| C-026 | 2026-07-17 | agent-skills/test-driven-development | Browser runtime verification via DevTools MCP | rejected: Layer 4 E2E row covers it; no consumer yet | PR #13 table |
| C-027 | 2026-07-17 | agent-skills/test-driven-development | Subagent writes the reproduction test blind to the fix | rejected: ceremony at n=1; the auditor covers the audit case | PR #13 table |
| C-028 | 2026-07-17 | agent-skills/planning-and-task-breakdown | Plan before code, read-only, human approves | already have | `templates/ts-base/.claude/skills/feature/SKILL.md` step 2 |
| C-029 | 2026-07-17 | agent-skills/planning-and-task-breakdown | Standing tasks/plan.md + tasks/todo.md checklists | rejected: ADR 6 — plan docs are views over tests; hand-ticked checklists lie | ADR 15 |
| C-030 | 2026-07-17 | agent-skills/planning-and-task-breakdown | Vertical slicing, task sizing ("and" in title = two tasks), checkpoint cadence, contract-first parallelization | deferred: folded into the /plan rite item | BACKLOG (harness) |
| C-031 | 2026-07-17 | agent-skills/planning-and-task-breakdown | Highest-risk task first (fail fast) | already have | `.claude/skills/kickoff/SKILL.md:15-16` riskiest assumption |
