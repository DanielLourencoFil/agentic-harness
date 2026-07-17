# Strategy brief — agentic-harness (session 2026-07-17)

**Audience:** another AI (or human) analysing next steps.  
**Source:** read-only evaluation + brainstorm with Daniel; no code changes in that session beyond this document.  
**Owner intent (binding):** this repo is a **personal engineering tool** for shipping products with coding agents. Not a product, not a category play, not an innovation claim. External adoption is secondary.

**Repo state at analysis (verified):**
- Branch history ~2026-07-09 → 2026-07-17; Layer A (ADR 10/12/13) merged to `main` via PR #10.
- Core artifacts: `PLAYBOOK.md`, `templates/ts-base/`, `templates/vue-starter/`, `home/`, `scripts/selftest*.sh`, `docs/{DECISIONS,RATIONALE,TOUR}.md`.
- Open at analysis time (may have moved): PR #11 `feat/consumption-model` (docs: three consumption modes + ADR 9 skill provenance stamp).

---

## 1. Thesis of the project (already stated in-repo)

You cannot prompt quality into an AI. Persona prompts are theater. Working levers:

1. Good procedures + real context  
2. **Mechanical rejection** of bad output (types, lint, tests, hooks, CI)

Meta-rule: **prefer force over steer.** If a rule can be a tool/test/hook, wire it; only what cannot be reified goes into `AGENTS.md`. Documented-but-unwired governance is a prayer.

Four-category taxonomy (`docs/RATIONALE.md`):

| Category | Protects | Mechanism |
| --- | --- | --- |
| Validity | soundness of inferences in code | lint / types (physical rejection) |
| Examinability | feasibility of human/agent refutation | size/complexity caps, minimal diff, deletion guard |
| Procedure | honesty of the investigation | structural checks on artifacts (negative tests first, audit reproduction, selftest negatives) |
| Content judgment | fitness to the real problem | **human** — deliberately not automated |

Honest limit: tooling forces **objective proxies**, never “good design” / SOLID-as-such.

---

## 2. Brutal evaluation (as personal tool)

### 2.1 Verdict

| Frame | Verdict |
| --- | --- |
| Personal OS for shipping with agents | **Worth serious follow-through** — thesis correct, execution above typical “method repos” |
| OSS product / industry category | **Not the goal**; do not optimize for it |
| “Need full map before any use” | **Wrong** — core is already usable for solo TS/Vue |

### 2.2 What is strong

- **Force > steer** as a rule *generator*, not a style guide dump  
- **Selftest that consumes templates as documented** + **negative cases** (gate must be *seen rejecting*) — including the real `import-x/no-cycle` wired-but-blind incident (`AGENT-LOG`)  
- Dual delivery: **`templates/`** (per-project cage, copy) vs **`home/`** (machine layer, symlink) for guest/third-party  
- Epistemic honesty: Bash hole, skills = steer, content judgment human, Layer A force/steer labels  
- Dogfood artifacts: one-line ADRs, CI, Layer A containment with realpath/symlink tests  

### 2.3 What is weak / incomplete

- Large share of “system” remains **steer** (minimal diff, evidence, negative-first, surface packs as tables)  
- **Agent-agnostic** force layers are real (hooks/CI/rulesets); machine hooks are still **Claude-shaped**  
- Surface packs (DB, auth, money, …) mostly **aspirational** — not installable packs with selftests  
- Thin external proof (stars/forks irrelevant for personal tool; **AGENT-LOG sparse**; few product metrics)  
- Risk: **meta-work outrunning products** (cathedral vs toolbox)

### 2.4 Rough scores (personal-tool frame)

| Axis | /10 | Note |
| --- | --- | --- |
| Thesis correctness | 9 | Structural |
| Originality | 6 | Composition + honesty, not new primitives |
| Execution of gates | 8 | Selftest + hooks |
| Dimensional coverage | 5 | Strong greenfield TS/Vue + machine hygiene |
| World proof of value | 3 | Dogfood early |
| Over-engineering risk | 7 (high) | Map grows faster than consumers |

### 2.5 Kill / continue soft rule (proposed)

If within ~90 days the harness has not *noticeably* reduced review cost or “implemented but not verified” incidents on real products, **freeze meta-repo** and reopen only under concrete pain.

Practical time budget: harness work as **tax on shipping** (e.g. ≤20% eng time), only rounds that end in **wired + selftested** artifacts (ADR 12 discipline).

---

## 3. “Does it need more content before use?”

**No — not for Daniel’s primary stacks (TS / Vue greenfield solo).**

### Already enough to code a repo

| Need | Present? |
| --- | --- |
| Cage rejecting bad code | Yes — `ts-base` + selftest |
| Vue overlay | Yes — `vue-starter` + selftest |
| Kickoff assembly | Yes — PLAYBOOK + `/kickoff` |
| Feature / audit rites | Yes — template skills |
| Machine-portable anti-destruction | Yes — `home/` Layer A + write containment |
| Claims proven in CI | Yes — selftests |

### Not required before first use

React/Nest starters, installable surface packs, brownfield overlay, skill drift report, progressive “YouTube maturity tables”, multi-vendor force ports.

### Correct mental model

```
Force core (exists) → use on 1–2 products → concrete pain → one extract → use again
```

Not:

```
Complete the map → then use
```

**Two meanings of “early”:**
- Catalog breadth: early (OK)  
- Force core: past “usable” threshold  

Evidence of usability already: job-fit-assistant gate setup (gates fired on real commits); vue-starter extracted from OrgLab; OrgLab already carries husky/eslint; Layer A on `main`.

---

## 4. Where to invest **now**

### Primary investment (not a harness feature)

**Consumption / dogfood on a real product (OrgLab first).**  
Run the feature loop with live gates. Grow the harness only when something breaks or blocks.

### Secondary (cheap hygiene, not a “round”)

- Merge/review open PR #11 if still open (three consumption modes + ADR 9 stamp) — small docs/kickoff delta; then stop.  
- Do **not** open Layer B abstract expansion, `/plan` skill, React/Nest “because the map has a hole”.

### Explicit non-investments now

| Item | Why skip |
| --- | --- |
| More Layer A list items | Round A closed + merged |
| ADR 9 skill drift report | Deferred until 2nd skill consumer (ADR 12) |
| Generic brownfield overlay | No real legacy consumer yet |
| Surface packs without product surface | YAGNI |
| YouTube progressive scoreboard as harness product | Ritual at product kickoff, not a system to build |

### Product kickoff ritual (keep; don’t productize)

Live scoreboard while mounting a cage on a **product** repo:

| Gate | Status | Proof |
| --- | --- | --- |
| … | ✅ only if seen firing | command / incident |

This updates during **harness assembly**, not magically as feature code advances. Distinct from **brownfield violation ratchet** (monotonic error counts in CI) — already in PLAYBOOK; wire when a real brownfield appears.

---

## 5. Process map: force vs steer (dimensions)

| Dimension | Force / half-force | Steer / hole |
| --- | --- | --- |
| Spec / idea | — | `/kickoff`, human owns scope |
| Scaffold | template + empty-scaffold green verify + selftest | — |
| Edit blast radius | write-containment PreToolUse (realpath, symlink) | Bash = honest hole (OS sandbox) |
| Code quality | tsc strict, ESLint as errors, size/complexity | design quality, naming semantics |
| Commit | husky: deletion-guard → lint-staged → verify | agent deny `--no-verify` = adapter only |
| Tests | verify runs tests | negative-first, scenario ownership = human/skill |
| “Done” claims | — | **shown evidence still steer** (see gaps) |
| CI / merge | push+PR verify, ruleset, human merge | — |
| Secrets | prompt scan, env-dump guard, deny-read `.env*` | IDE-selection channel ungated; **git history secrets** incomplete |
| Guest / third-party | machine `home/` Layer A | cannot install project cage in foreign git |
| Audit | auditor read-only tools | skill = steer; reify-to-test is the truth procedure |

---

## 6. Neglected tools / strategies worth considering

Ranked for **personal product shipping**, not completeness.

### Tier 1 — high ROI when pain appears

1. **Stop / “done” evidence gate (make evidence force)**  
   Hook at end of agent turn: refuse “done” unless `verify` (or scoped command) passed this session. Natural Layer A upgrade without more constitution prose. Lives in `home/`.

2. **Secrets in git history (gitleaks / detect-secrets)**  
   Pre-commit + CI. Actor-blind. Complements Claude prompt/shell nets; catches staged files the agent hooks never see.

3. **Executable architecture boundary**  
   One dependency-cruiser rule or ESLint `no-restricted-imports`: e.g. `src/lib` must not import Vue/components. PLAYBOOK already allows it; rarely wired. High value as agent mush grows.

4. **Surface pack: “LLM in the product”**  
   Harness is strong on **agent writing code**; weak as reusable cage for **LLM behind a boundary** (Zod output schema, golden/negative fixtures, stub provider, seam, no LLM without seam). High career/product leverage for AI-in-product work.

5. **Scripted worktree helper**  
   Documented (“never share git index”) but not one-command. Cheap operational force after multi-session collisions.

6. **Characterization scaffold**  
   Feathers practice is in PLAYBOOK; missing a short skill/pattern: pin behavior before change on untested modules. Not a full brownfield overlay.

### Tier 2 — situational

| Item | Use when |
| --- | --- |
| Knip / unused exports | Dead code / orphan agent output accumulating |
| Added-diff size gate | Complements deletion guard against monster PRs |
| Single Playwright smoke | One critical wiring path only |
| Coverage ratchet on `src/lib` only | Force tests on pure core without global % games |
| File lockdown on stabilized critical paths | Auth, money, migrations |
| Custom ESLint AST for one recurring anti-pattern | Only if corpus repeats it |
| Contract fixtures (valid/malformed/partial) | Untrusted external input |
| Stacked PRs | Only if review volume justifies |

### Tier 3 — correctly neglected (fashion)

Multi-agent planner/coder/tester theater · BMAD/spec-kit ceremony piles · coverage % targets · persona system prompts · codebase RAG for small solo repos · global mutation testing · always-on multi-model review · pre-building React/Nest “for the map” · full OS sandbox on day one (real Bash fix, heavy).

### Structural process gap (almost free)

**Product → harness feedback without meta sessions:**

- After any product feature that *hurt*: one line `harness-candidate: …` in product `AGENT-LOG` or `~/Dev/BACKLOG.md`  
- Harness grows **only** from that list, with negative selftest  

This is the missing roadmap generator that prevents abstract “rounds.”

### Coverage sketch of gaps

```
[done claims]   evidence              — STEER  → candidate: stop hook
[secrets]       prompt/shell only     — partial → gitleaks
[arch]          pure core             — convention → one boundary rule
[AI-in-app]     evals/seam pack       — almost absent
[parallel]      worktrees             — docs only
[legacy]        characterization      — docs only
```

---

## 7. If forced to pick **one** next harness growth (when a PR is justified)

| Horizon | Pick |
| --- | --- |
| Operational short-term | Stop/evidence gate **or** gitleaks in `ts-base` |
| Product/career medium-term | **LLM boundary** surface pack (schema + fixtures + stub + negatives) |
| When codebase fattens | Single **lib ↛ UI** architecture rule + CI |

Default until then: **zero new dimensions; ship product code.**

---

## 8. Rule generation method (for any future addition)

For each known failure of reasoning or process:

1. Syntactic signature in code? → lint/type rule + **negative selftest**  
2. Procedural signature? → hook / CI / pre-commit gate + negative selftest  
3. Neither? → human judgment, **explicitly labeled** — never fake a gate  

Golden rule from AGENT-LOG:

> A wired rule is not a live rule until it has been **seen rejecting** a violation.

Anti-patterns already owned by the repo: skill-per-principle, documented-but-unwired governance, claiming tooling forces SOLID, coverage targets, hand-ticked checklists that drift and lie (plans are **views over tests**).

---

## 9. Consumption modes (intent; may land via PR #11)

Mode decided by **whose git** it is:

1. **My project** — stamp via `/kickoff` (vendored copies; project carries its law)  
2. **My machine** — `home/bootstrap.sh` symlinks (constitution + Layer A + hooks)  
3. **Someone else’s repo** — envelope folder per engagement; their clone untouched; never nest git; portable Layer A only  

Do not install project cage into foreign trees without their process.

---

## 10. Open questions for the analysing AI

1. Given OrgLab + interview pipeline load, is **any** harness PR justified this week, or only dogfood?  
2. Between **stop/evidence gate**, **gitleaks**, and **LLM boundary pack**, which maps to the next *actual* product pain?  
3. Should `AGENT-LOG` / BACKLOG gain a permanent `harness-candidate` section as the only legal growth queue?  
4. Any Tier 1 item above that is **already** half-solved in-repo and only needs wiring (avoid duplicate design)?  
5. What would falsify the “core is usable” claim on OrgLab in one afternoon (concrete commands)?

---

## 11. Non-goals (do not recommend these as “next”)

- Completing PLAYBOOK Layer 0–4 as mandatory backlog  
- Building a progressive maturity dashboard product  
- Multi-vendor force parity for purity  
- Expanding Layer A prose without a new mechanical gate  
- Treating this brief as license for a large meta-round  

---

## 12. One-line summary for the other model

**agentic-harness is a usable personal force-first cage (TS/Vue + machine Layer A); grow it only under product pain; highest neglected upgrades are evidence-as-force, git secret scanning, arch boundary, and an LLM-in-product pack; default investment now is dogfood on OrgLab, not catalog expansion.**

---

*Document written 2026-07-17 for handoff analysis. Claims about repo layout and PR #10 merge were verified in that session; re-check git/PRs before implementing.*
