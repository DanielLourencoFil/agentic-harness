# AGENTIC PLAYBOOK — project harness assembly spec

**Audience: the AI agent setting up or working on a project.** At project kickoff, read this
file plus the project plan, then assemble the harness by stacking the layers that match the
project's stack and surfaces. Propose the resulting subset to the human with a one-line
justification per item ("load-bearing because X" / "skipped because Y"). It is correct to skip
layers — applying everything everywhere is the failure mode this file exists to prevent.

```
Layer 0  UNIVERSAL        → always, every project
Layer 1  LANGUAGE         → TypeScript
Layer 2  FRAMEWORK        → Vue | React | Node/NestJS
Layer 3  SURFACE PACKS    → DB, auth, money, queues, public API, secrets/PII, user content
Layer 4  CONTEXTUAL       → decision table (use-when / skip-when)
```

Reusable artifacts live in `~/Dev/agentic-harness/templates/` (currently: `ts-base/` — copy, don't rebuild).
Meta-rule for every layer: **prefer force over steer.** If a rule can be reified into a
tool/test/hook, wire it; only what cannot be reified goes into CLAUDE.md as convention.

---

## Layer 0 — UNIVERSAL (every project, no exceptions)

**Enforced (wire these, they must physically block):**
- `verify` = typecheck + lint + test — on **pre-commit** (Husky) and re-run in **CI**
  (local hooks can be bypassed; CI cannot). Green verify on empty scaffold before feature code.
- **Zero-warning lint.** No warning budgets (that's legacy-debt management, not a fresh project).
- **Deletion guard** on pre-commit (>80 deleted lines blocked unless `ALLOW_BIG_DELETE=1`).
- Formatting via Prettier + lint-staged (mechanical, never discussed).

**Convention (CLAUDE.md of the project):**
- Values: correctness > trust > performance > dev speed. Never ship unverified claims —
  show command output as evidence ("compiles" ≠ "works").
- Plan before code · minimal diff · one concern per commit (conventional messages) ·
  read a file fully before editing · reuse-scan before creating a component/util.
- Tests ship in the same commit as the logic. Tests are a **ratchet**: a test changes only
  when its requirement changes, in a dedicated commit. Never weaken a test to pass it.
- Architecture for testability: isolate non-determinism (time, network, LLM, randomness)
  behind a fakeable seam; keep load-bearing logic **pure** and test it hard without mocks.
- Test at the lowest level that can catch the bug. Every test must fail if the logic breaks;
  assert concrete values. **No coverage % target** (diagnostic only).
- The human owns the scenario checklist (what is always true / never possible); AI may write
  the test code but not decide alone what "tested" means.
- Decisions → dated one-line ADRs in `docs/DECISIONS.md`, captured live.
- Audits run in a **fresh context**, scoped, after a complete unit. Neutral framing (allow
  "none found"); each finding needs a concrete reproduction; findings are hypotheses —
  reify real ones into failing tests.
- Doc privacy: `DECISIONS.md`/`AGENT-LOG.md` public; personal learning notes gitignored.

---

## Layer 1 — TypeScript (any TS project)

**Template: copy `~/Dev/agentic-harness/templates/ts-base/` — do not rebuild.** It contains:
- `tsconfig` strict + `noUncheckedIndexedAccess`, `noImplicitOverride`, `verbatimModuleSyntax`.
- ESLint (flat, typed): `strictTypeChecked` + as **errors**: `no-explicit-any`,
  `no-floating-promises`, `ban-ts-comment`, `complexity: 10`, `max-lines-per-function: 60`,
  `max-lines: 300`, `no-console`.
- Vitest (coverage as diagnostic, no threshold) · Husky pre-commit (deletion-guard →
  lint-staged → verify) · CI workflow running verify.

**Convention:** rely on inference internally; explicit types at public boundaries. `unknown` +
narrowing instead of `any`. Runtime validation at trust boundaries is schema-first (**Zod**),
never `class-validator` (decorator-based, legacy).

**Honest scope note:** tooling forces *objective proxies* (types, size, complexity, dependency
direction) — not SOLID, not correctness. The semantic gap is closed by tests + human review.

---

## Layer 2 — FRAMEWORK modules (stack `ts-base` + one of these)

### Vue 3
**Enforce — `eslint-plugin-vue` (preset ≥ `strongly-recommended`) with as errors:**
`no-mutating-props` · `require-v-for-key` · `no-use-v-if-with-v-for` ·
`no-side-effects-in-computed-properties` · `require-explicit-emits` · `no-v-html` (XSS) ·
`multi-word-component-names`; add `eslint-plugin-vuejs-accessibility`.
**Convention (CLAUDE.md):**
- `<script setup>` + Composition API only.
- **Derived state = `computed`. `watch`/`watchEffect` ONLY for side-effects/external sync;
  every `watch` needs a one-line justification why computed doesn't fit.** (The corpus
  over-uses watchers — same failure as React's useEffect abuse; the linter can't catch it.)
- Business logic in composables/`src/lib` (pure, no framework imports), components render.
- Pinia for shared state; props down / emits up; no prop drilling past ~2 levels (provide/inject
  or store).
**Optional arch rule (one line, cheap):** forbid `src/lib/**` from importing `vue`/components
(dependency-cruiser or eslint import rule) — keeps the pure core pure.

### React
**Enforce:** `eslint-plugin-react-hooks` (`rules-of-hooks`, `exhaustive-deps` as errors) ·
`react/jsx-key`.
**Convention:** derived state computed during render — **no `useEffect` for deriving state**
("You Might Not Need an Effect"); effects = external sync only; event logic in handlers;
server state in TanStack Query, not effects+setState.

### Node / NestJS (backend)
**Enforce:** schema-first validation at every boundary (`nestjs-zod` / Zod) — `class-validator`
forbidden · guards/authz tested with negative cases · structured logger, `no-console`.
**Convention:** DI via framework; depend on abstractions at module seams; config validated at
startup (fail fast); errors are handled paths with consistent shapes, no stack leaks.

---

## Layer 3 — SURFACE PACKS (add per surface present in the project)

| Surface | Mandatory practices |
| --- | --- |
| **Database / persistence** | migrations only (never `db push --accept-data-loss`); soft-delete for business data; seed guard (no prod seeds); canonical fixtures — never invent JSON shapes; integration tests against a real (dockerized) DB |
| **Multi-tenant** | every query scoped by tenant id — no exceptions; test the negative (cross-tenant access → 404) |
| **Auth / authz** | backend and frontend check independently (FE hides, BE blocks); token invariant tests (valid → 200 · wrong → 403/404 · **stored hash as input → 404** · expired → 410/403 · other tenant → 404); least privilege |
| **Money / critical mutations** | idempotent operations; webhooks idempotent + replayable; audit log with actor/reason |
| **Queues / async** | idempotent consumers; retries + dead-letter; side-effects fire-and-forget off the critical path |
| **Public API** | schema validation at boundary; rate limiting; consistent error shapes; no stack traces to clients |
| **Secrets / PII** | secrets never in code or logs; zero PII in logs; agent read-block on `.env*`; dependency audit gate in CI |
| **User-generated content rendering** | no raw HTML injection (`no-v-html` / sanitize); CSP |
| **Multi-region** | data residency; connections never cross zones |

---

## Layer 4 — CONTEXTUAL (decision table)

| Practice | Use when | Skip when |
| --- | --- | --- |
| Data-boundary contract tests (fixtures: valid/malformed/partial) | any untrusted input (LLM, JSON, CSV, API) | no external data |
| Behavioral contract suite (shared tests vs all impls — reifies Liskov) | >1 interchangeable implementation | single impl |
| Consumer-driven contracts (Pact) | multiple independently deployed services | monolith / SPA |
| Arch tests / dependency-cruiser boundaries | large codebase, layers, many contributors | small app (keep only the pure-core rule) |
| Coverage-ratchet on core folder | want to force test presence without a gameable % | tiny app |
| **File lockdown** (deny-write in `.claude/settings.json` + PreToolUse hook + git gate on path; keep read allowed) | a critical file has **stabilized** and must never change silently | greenfield still in flux |
| Custom ESLint AST rule for a semantic anti-pattern | it recurs across a large team codebase | small app (CLAUDE.md rule + review suffice) |
| Auto code-review on PR (fresh context) | PR flow exists | solo → run scoped review manually per completed unit |
| E2E smoke (Playwright) | one critical happy path worth a wiring test | keep to ≤1 — E2E tests wiring, not logic |
| Component tests | component has real interaction/logic | presentational only |
| Task-named Skill (packages a heavy recurring procedure + points at checks) | chunky recurring task, ideally with a script | one-offs; project-wide prefs (→ CLAUDE.md) |
| MCP server | agent needs real external actions (DB, browser, API) | self-contained app |
| Subagent | isolatable/parallel work; fresh-context audit | small linear work |

---

## PIPELINE (CI is universal; CD scales with the surface)

**Universal CI (every project):**
- CI runs `verify` on **every push AND every pull_request** — never PR-only. (Lesson learned:
  PR-only triggers + a direct-push workflow = deploys from commits that never ran CI.)
- **Hermetic CI:** no cloud dependencies, no shared state. Ephemeral services (DB/Redis as
  workflow `services:`) when needed; a runtime guard that rejects cloud URLs in test env.
- **Branch protection + required status check** on the main branch — merge is physically
  blocked without green CI. Don't rename the required job (it's pinned by name in the rule).
- Hygiene: `concurrency: cancel-in-progress`, a job timeout, skip dependabot actors.
- Known pitfall: `paths-ignore` + required checks can leave docs-only PRs stuck on a pending
  check (GitHub's workaround: a no-op job with the same name). Prefer no path filtering
  unless CI cost is real.
- Weekly dependency audit job (`pnpm audit --prod --audit-level=high`).
- **CI is confirmation, not discovery.** If CI goes red often, the local gate is too weak —
  run full `verify` on pre-push/pre-commit so red CI is rare.
- **Automation by default: whatever can be automated, is.** The red-CI loop has two layers:
  - *In-session:* after any push, the agent watches the run in the background (`gh run watch`)
    and on failure reads `gh run view --log-failed` and fixes — the human neither reports the
    failure nor pastes logs.
  - *Out-of-session (optional):* a `workflow_run`-on-failure trigger invokes a coding-agent
    action that diagnoses the failed log and pushes a fix to the PR branch — the repo heals
    itself while the human is away. (Needs an API token secret; costs credits.)
- **The boundary that stays manual — by principle, not by limitation:** deciding a PR exists,
  reviewing the diff, and arming `gh pr merge --auto`. Never combine an auto-fixing bot with
  pre-armed auto-merge such that unreviewed code can merge — 100% of the *work* automated,
  100% of the *decision* human ("never ship what you don't understand").
- **Commit/push rite — automatic, never asked.** The agent commits atomically (gated by
  verify) and pushes the work branch without asking; pushing a work branch has no
  irreversible consequence once branch protection walls the default branch, force-push is
  denied, and secrets are read-blocked. The ask-worthy act is the **merge**, not the push.
  Team context: identical, plus required approvals ≥1 on the PR.
- **Solo flow:** work branch → PR → agent-watched CI → human reviews diff and arms auto-merge
  → merges on green → platform deploys from main.

**CD — frontend-only (SPA/static):**
- Platform auto-deploy (Vercel/Netlify) from green main + **preview deploy per PR**. That is
  the whole pipeline — do not add ceremony.

**CD — backend/DB surface pack (add when the surface exists):**
- **One artifact, config via env** — the same container image runs in every region/env;
  behavior differs only by environment variables.
- **Migrations tested in CI** (apply to the ephemeral DB before tests) and **applied at
  release** (`migrate deploy` at container startup is fine for single-instance platforms;
  use a release phase/job when instances scale horizontally).
- Deploy only from green: enable the platform's "wait for CI" check, or deploy via a
  workflow that depends on the verify job.
- Post-deploy: a health endpoint checked after release; rollback = redeploy previous image
  (know the platform's mechanism before you need it).

---

## KICKOFF CHECKLIST (execute at project start, after layers are chosen)

1. **Scaffold + harness first, features second.** Copy the language template
   (`~/Dev/agentic-harness/templates/ts-base/`), add framework module rules, get `pnpm verify` green on the
   empty scaffold. Commit #1 = "chore: scaffold + guardrails".
2. **Docs skeleton:** `docs/SPEC.md` (what/why/scope in-out) · `docs/DECISIONS.md` (dated
   one-line ADRs) · `AGENT-LOG.md` (public: where the agent helped/failed) · project
   `CLAUDE.md` (only conventions the tooling cannot enforce — no duplication of lint rules).
3. **`.gitignore` privacy block** from day one: `INTERVIEW-NOTES.md`, `/notes/` (personal
   learning stays private; never `git add -f` them).
4. **`.claude/settings.json` baseline:**
   - deny **read** on `.env`, `.env.*` (secrets — the agent never sees them);
   - **allow** `git commit` and `git push` to work branches — the commit/push rite is
     automatic, never asked (safe because verify gates commits, branch protection walls
     master, and force-push is denied);
   - deny `--no-verify`, force-push, and pushing/merging to the default branch
     (the agent opens PRs — the human merges);
   - file lockdown (deny **write**, keep read) only later, when a critical file stabilizes.
5. **CI** wired and green before the first feature (verify runs on every push/PR).
6. **Branch protection — server-side, scripted (if the repo is on GitHub):** apply a ruleset
   via `gh api repos/{owner}/{repo}/rulesets` — require PR (0 approvals when solo — you can't
   approve your own PR; the real gate is the required check + the human clicking merge),
   `non_fast_forward` (no force-push), `deletion`. After the first CI run exists, add the
   verify job as a **required status check**. This binds *everyone* — human, local agent,
   bots — even if local settings fail. (Free on public repos; private needs a paid plan.)
   Agent may **open** PRs; merging to the default branch is always the human's act.
7. Skills: create none by default. Only add a **task-named** skill when a heavy recurring
   procedure with a script emerges (see Mechanism selection).

## ROUTINE — feature loop (every feature, no exceptions)

1. **Specify before implementing** — answer 4 questions, human owns the answers:
   what is ALWAYS true? (→ positive test) · what is NEVER possible? (→ negative test —
   the one AI always forgets) · which state transition is forbidden? (→ impossible-case
   test) · how would a malicious/careless user abuse this?
2. Scenario checklist goes into SPEC.md; **negative tests are written before production code.**
   If you can't write the negative test, you don't understand the feature yet — stop.
3. Implement minimal diff; tests ship in the same commit as the logic.
4. **Evidence gate:** a feature is "done" only with command output shown (verify green).
   No evidence = status "IMPLEMENTED — NOT VERIFIED", with the exact command the human runs.
5. Non-obvious choices: state the why + trade-off in one line (the human will probe).

## ROUTINE — audit (after each complete, coherent unit — feature/module, not per micro-change)

- **Fresh context, always** (new session or subagent — the session that wrote the code is
  contaminated and will rationalize its own choices). Scoped to one concern per run.
- **Neutral prompt template** (anti-confabulation — never "find bugs", which manufactures them):
  > "Review <scope> for: correctness bugs, implementation problems, architecture concerns,
  > dead/orphan code. For each category, if nothing qualifies, write 'none'. Every finding
  > must include a concrete reproduction: exact input/state → wrong output. Rate confidence."
- **Triage = reify:** each claimed finding becomes a test — real bug → test goes red → fix →
  green; test passes on current code → finding was confabulated, discard. Low-confidence
  findings are leads to check, not facts.
- Log outcome in `AGENT-LOG.md` (found-real / confabulated counts — this calibrates trust).
- With a PR flow, `/code-review` (or a PR review action) replaces the manual prompt — same
  rules embedded (reproduction + verify pass).

## Mechanism selection (when adding any new rule)

always-true invariant → **CLAUDE.md** · heavy recurring task → **Skill (named by the task)** ·
must be impossible → **hook / lint / CI gate** · new capability → **MCP** · isolatable work →
**subagent** · human-triggered flow → **slash command**.
Most agentic-setup mistakes are a rule in the wrong mechanism (e.g. an invariant in a Skill
that never fires).

## Anti-patterns (never do)

- Documented-but-not-wired governance (guardian scripts, constitutions, manual checklists) —
  if no hook/CI runs it, it's a prayer, not a gate.
- Persona/tone prompting as a quality lever ("act like a senior engineer").
- Coverage % as a target · warning budgets in fresh projects.
- A Skill per design principle (`principle_D`) — wrong mechanism, never fires.
- Claiming tooling "forces SOLID" — it forces proxies; design review stays human.
- Trusting audit findings without reproduction — "find bugs" manufactures bugs.
- Offloading 100% to tooling — linters catch classes of errors, never "right design /
  right problem". Human review is not optional.

## Roadmap (assets to extract as stacks get used)

- `ts-base` ✅
- `vue-starter` = ts-base + Vue module → **extract during OrgLab Fase 0**
- `react-starter`, `nest-base` → extract on first real use, not before
- Later: push starters as GitHub template repos (`degit`)
