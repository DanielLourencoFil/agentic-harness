# Harness Lab — evaluation brief (2026-07-17)

**Audience:** another AI (or human) evaluating whether to pursue this as a portfolio project, a personal tool, or both.  
**Author context:** Daniel — data-science bootcamp portfolio search; owner of `agentic-harness` (personal force-first engineering cage for coding agents). Not building this as a startup; primary use is evidence over “I think.”  
**Related docs:** `docs/STRATEGY-BRIEF-2026-07-17.md` (harness strategy), `docs/RATIONALE.md` (force vs steer taxonomy), `PLAYBOOK.md`.  
**Status:** idea / design brief only. No implementation in this document’s session of origin.

---

## 1. One-line pitch

**A small evaluation lab that holds the model and the user request fixed, varies only the agent harness (skills / force gates / bare), and scores runs with objective graders plus cost (tokens, time) — so harness choices stop being faith and become measured trade-offs.**

---

## 2. Problem statement

### 2.1 Industry habit

People claim:

- long curated skills improve code quality,
- “harness engineering” matters more than model choice,
- simplification / clean-code skills make agents produce better code,

…usually **without**:

- fixing the model and the task,
- ablating skill length vs force gates,
- reporting **tokens and wall time**,
- defining **success** so “conceptually equal” is operational, not aesthetic.

### 2.2 Causal confusion

Public evidence already shows **scaffold/harness effects are large**:

- Same model under different scaffolds can swing double-digit points on SWE-bench / CORE-bench-style evals.
- Papers argue against comparing LLM agents without disclosing the harness (within-model harness variance can exceed within-harness model variance).
- Leaderboards and “harness-bench” style matrices treat **model × harness** as the real unit.

So the category “measure the harness” is **not delusional**. What is missing for an individual engineer is a **small, reproducible protocol** aimed at:

1. **steer ablation** (mini skill vs long skill vs task-only),  
2. **force ablation** (bare generation vs skill-only vs verify/lint/test loop),  
3. **efficiency** (success-normalized tokens and time),  
4. especially **code simplification** and form metrics (scope, complexity proxies), not only “issue resolved.”

### 2.3 Personal thesis to stress-test

From Daniel’s engineering stance (`agentic-harness`):

- Long lists of principles in prompts are **steer**, not guarantees.  
- Wide “nets” of questions/requests often produce **narrative diligence**, not item-by-item compliance.  
- **Force** (tests, lint, typecheck, hooks, CI) is where guarantees live.  
- If two setups achieve the same objective success but one uses **~4× tokens or time**, that setup is **inefficient** and should lose.

The lab exists to **falsify or support** these claims with data.

---

## 3. Goals and non-goals

### 3.1 Goals

| ID | Goal |
| --- | --- |
| G1 | Same **model** + same **user task prompt** + different **harness setups** → measurable differences in output and process cost |
| G2 | Objective primary graders (tests, locked test files, optional lint/verify) |
| G3 | Cost accounting: tokens (in/out/total), wall-clock; optional explore-vs-edit proxies |
| G4 | Efficiency metrics: success rate, cost **conditional on success**, cost including failures, Pareto of quality vs cost |
| G5 | Portfolio-grade reproducibility: one command for a subset run, fixed task suite, written method + limits |
| G6 | Optional evolution into a **personal harness-testing tool** (YAML setups → run → grade → table), not a SaaS |

### 3.2 Non-goals (explicit)

| Non-goal | Why |
| --- | --- |
| Replace SWE-bench / vendor leaderboards | Wrong scale; different question |
| Claim “best harness in the world” | N and task domain limited |
| Automate “human readability” as ground truth | Content judgment; human raters only on a sample |
| Complete agentic-harness roadmap first | Lab consumes a **subset** of the cage; extract-on-pain |
| Multi-model multi-agent platform in MVP | Scope trap |
| LLM-as-judge as primary scorer for “simpler” | Circular with simplification skills; secondary only |

---

## 4. Core questions (pre-register these)

### Q1 — Does harness change outcomes under fixed model and request?

> Holding `model_id` and user task text fixed, do different harness setups produce different objective grades?

### Q2 — Steer: does a long simplification skill beat a mini skill?

> On the same tasks, is `long-skill` better than `mini-skill` on success and/or quality proxies, after cost?

**Working hypothesis H-steer:** long skill does **not** reliably beat mini on success; long skill costs **≥2× tokens** (often more) for equivalent success.

### Q3 — Force: does a verify/lint/test loop beat bare / skills-only?

> Does a force cage improve success (tests green, tests locked) enough to justify extra tokens/turns?

**Working hypothesis H-force:** force setup raises success rate; may raise tokens; **efficiency = success/tokens** can still win or lose — data decides.

### Q4 — Efficiency / “4× tokens”

> Conditional on **equivalent success**, is setup A dominated by setup B on tokens and/or wall time?

**Decision rule:** if success predicates match and tokens_B ≥ 4× tokens_A (median), declare B **inefficient** relative to A for that task class (unless B wins on a pre-registered secondary that A fails — document explicitly).

---

## 5. Experimental design

### 5.1 Unit of analysis

One **trial** =

```
(task_id, setup_id, model_id, seed_or_run_index) → artifact + grade + cost
```

### 5.2 Fixed factors (control)

| Factor | MVP choice |
| --- | --- |
| Model | **One** frontier coding model (record exact id + date) |
| Temperature / sampling | Fixed; if API allows seed, set it; else multiple runs |
| Task suite | 15–40 microtasks, versioned in git |
| User-facing task prompt | Identical across setups for a given task (only harness envelope changes) |
| Grader | Outside agent reach; tests read-only to the agent |

### 5.3 Varied factor: harness setup

Minimum **three** setups for MVP:

| `setup_id` | Envelope | Intent |
| --- | --- | --- |
| `bare` | Task text only; single-shot or minimal tool loop; **no** lint/test feedback loop | Lower bound / pure model |
| `mini-skill` | Short steer: e.g. “simple clear code; preserve behavior; do not modify tests; run tests if you can” | Cheap steer |
| `long-skill` | Long curated simplification/process skill (e.g. Osmani-style code-simplification or equivalent) | Expensive steer / “wide net” |
| `force-cage` (strongly recommended 4th) | Mini or null skill + **mechanical loop**: typecheck/lint/test must pass or iterate until pass/fail cap | Force-first (subset of agentic-harness) |

Optional later (not MVP):

- `skills-only-no-force` vs `force-no-skills` (2×2 ablation)  
- deletion-guard / max-diff policies  
- stop/evidence hook (“cannot claim done without verify”)  
- second model (generalization)

### 5.4 Task suite design

Each task directory:

```
tasks/<id>/
  task.md           # user request (fixed)
  src/              # starter code (optional; bug or “messy but tested”)
  tests/            # LOCKED — grader fails trial if agent mutates these
  grade.json        # optional metadata: allowed paths, time budget
```

**Task types (suggested mix):**

1. Implement pure function from failing tests (greenfield small)  
2. Fix bug with tests defining behavior  
3. **Simplify** messy module without changing tests (core for Q2)  
4. Boundary validation (schema-like) with negative cases  

Prefer **deterministic domains** (parsers, scoring rules, validators). Avoid tasks that need network or flaky time.

**N (MVP):** 20 tasks × 3 setups × 2–3 seeds ≈ 120–180 trials (cost-aware; start with 10 tasks × 3 × 1 seed smoke).

### 5.5 Isolation

- Clean workspace per trial (no leakage of prior trial files or git history that reveals answers).  
- Cap max turns / max tokens / wall timeout → cap exceeded = `success=false`, still record cost.  
- No shared mutable cache that favors later conditions unevenly; if prompt caching exists, equalize policy across setups.

---

## 6. Metrics

### 6.1 Primary success predicate (operational “conceptually good enough”)

```
success ≡
    tests_pass
AND tests_locked          # test files hash/diff unchanged
AND (optional) verify_green   # tsc + lint + test if force setup defines it
AND (optional) scope_ok       # only allowed paths modified
```

Only trials with `success=true` enter **“equivalent outcome”** efficiency comparisons.

### 6.2 Quality proxies (secondary, automatic)

| Metric | Meaning |
| --- | --- |
| `files_changed` / `loc_added` / `loc_deleted` | Size of change |
| `out_of_scope_files` | Drive-by / gutting risk |
| Aggregate complexity / max-depth signals if ESLint (or similar) runnable on artifact | Form proxy — not “beauty” |
| Whether agent weakened tests | Hard fail via `tests_locked` |

### 6.3 Cost metrics

| Metric | Definition |
| --- | --- |
| `tokens_in`, `tokens_out`, `tokens_total` | From API usage; if unavailable, document proxy |
| `wall_s` | End-to-end trial wall clock |
| `turns` | Agent loop iterations / tool rounds |
| `cost_usd` | Optional, from public pricing table pinned in README |

### 6.4 Time split (optional, labeled as proxy)

Do **not** claim “cognitive planning time.” Use:

| Proxy | Heuristic |
| --- | --- |
| `t_first_edit_s` | Time until first Write/Edit |
| `explore_turns` | Read/Grep/Glob/list only |
| `edit_turns` | Write/Edit/apply_patch |
| `verify_turns` | Test/lint commands |

Report as **explore vs edit proxy**, phase 2 of analysis.

### 6.5 Efficiency (decision-facing)

```
pass_rate(setup) = mean(success)

tokens_per_success(setup) = median(tokens_total | success)
wall_per_success(setup)   = median(wall_s | success)

efficiency(setup) = pass_rate / mean(tokens_total)     # or median tokens
# also report:
mean_tokens_all(setup)   # includes failures — punishes fail-fast cheap setups fairly when paired with pass_rate
```

**Pareto:** plot pass_rate vs median tokens (or wall_s). No single winner required.

### 6.6 Human preference (small sample, not primary)

Blind pairwise preference on 10–20 successful pairs (“which is easier to maintain?”). Report separately; never overwrite automatic grades.

### 6.7 What must not be primary

- LLM judge score for “simplicity” aligned with the long skill text  
- “Looks cleaner” from the same session that wrote the skill  
- Self-reported checklists inside the agent transcript

---

## 7. Analysis plan

1. **Descriptives:** pass_rate, token/wall distributions per setup.  
2. **Paired task view:** per `task_id`, which setups succeeded; **helped vs hurt** counts (setup X succeeds where Y fails and vice versa).  
3. **Conditional cost:** among tasks where **both** A and B succeed, ratio of tokens and wall (test the “4×” claim).  
4. **Ablation narrative:**  
   - bare → mini → long (steer axis)  
   - bare/mini → force-cage (force axis)  
5. **Sensitivity:** drop flaky tasks; recompute.  
6. **Pre-registered conclusions language:**  
   - Support / reject H-steer, H-force with explicit numbers.  
   - State limits (one model, synthetic tasks, no full SWE-bench).

Statistical ambition for bootcamp: medians, bootstrap CIs if feasible, or at least full tables + helped/hurt. Avoid overclaiming p-values on tiny N.

---

## 8. Proposed system shape (tool)

### 8.1 Layout

```
harness-lab/   # may live as sibling repo or package under portfolio org
  tasks/
  setups/
    bare.yaml
    mini-skill.yaml
    long-skill.yaml
    force-cage.yaml
  runners/
    run_trial.py
  graders/
    grade_trial.py
  results/
    raw/*.json
    runs.parquet
  notebooks/
    analysis.ipynb
  report/
    FINDINGS.md
  README.md
  Makefile
```

### 8.2 Setup config (illustrative)

```yaml
# setups/force-cage.yaml
id: force-cage
model: ${MODEL}
system_append: |
  Preserve behavior. Do not modify tests.
  You must end with passing tests.
loop:
  max_turns: 20
  max_tokens: 200000
  on_edit: null
  before_done:
    - cmd: "pnpm test"   # or pytest
      must_pass: true
    - cmd: "pnpm lint"
      must_pass: true
skills: []   # or [mini]
```

### 8.3 Trial record (schema)

```json
{
  "task_id": "014-simplify-parser",
  "setup_id": "long-skill",
  "model_id": "…",
  "run_index": 0,
  "success": true,
  "tests_pass": true,
  "tests_locked": true,
  "scope_ok": true,
  "tokens_in": 12000,
  "tokens_out": 4000,
  "tokens_total": 16000,
  "wall_s": 180.4,
  "turns": 12,
  "t_first_edit_s": 45.0,
  "explore_turns": 5,
  "edit_turns": 7,
  "verify_turns": 3,
  "files_changed": 2,
  "cap_hit": false,
  "error": null
}
```

### 8.4 CLI (MVP UX)

```bash
make smoke          # 3 tasks × all setups × 1 seed
make run SUITE=mvp
make grade          # if grade not inline
make report         # notebook → FINDINGS.md tables
```

---

## 9. Relationship to `agentic-harness`

| agentic-harness | Harness Lab |
| --- | --- |
| Tool for **shipping products** with force > steer | Instrument for **measuring** envelopes |
| PLAYBOOK, templates, `home/`, selftests | Task suite + setups + graders + analysis |
| Grows under product pain | Grows under measurement need |

**Dependency direction:** Lab **consumes** a thin slice of force ideas (verify loop, test ratchet, locked tests). It must **not** block on completing Layer 0–4 of the PLAYBOOK.

Findings may feed one-line ADRs or AGENT-LOG entries (“long skill failed efficiency test on suite v1”) without expanding the harness catalog by default.

---

## 10. Portfolio / bootcamp framing

### 10.1 Story

> Industry sells prompt packs and “harness magic.” I built a small lab that fixes the model and the request, varies only the harness, and measures success, tokens, and time. Result: [data]. Long skills / force cages win or lose on **efficiency**, not vibes.

### 10.2 Deliverables for evaluators

1. Repo with tasks + runners + results sample  
2. `FINDINGS.md` with hypotheses, method, tables, limits  
3. Notebook with plots (pass rate, tokens per success, Pareto)  
4. Honest failure modes (what we cannot claim)

### 10.3 Skills demonstrated (DS + eng)

Experimental design · confounders · ablation · cost metrics · reproducibility · clear negative results · software packaging of an eval pipeline.

---

## 11. Field context (for the reviewing AI)

Relevant existing work / concepts (non-exhaustive; re-check links at implementation time):

- SWE-bench and variants: task success via tests; scaffold often confounded with model  
- “Stop comparing LLM agents without disclosing the harness” (scaffold variance literature)  
- Public reports of large score swings for **same model, different scaffold**  
- harness-bench style **model × harness** matrices (accuracy + wall time)  
- Anthropic (and others) on **agent eval harnesses**, isolation between trials, deterministic graders for code  
- Prompt-length / many-rules studies: longer input and huge rule lists often **hurt** adherence or reasoning  
- Ablation-style skill studies: long generated skills may not beat task-only baselines while costing more tokens  

**Gap this lab targets:** personal-scale, force-vs-steer-vs-skill-length ablation with **efficiency** as a first-class outcome — especially simplification under locked tests — not another global coding leaderboard.

---

## 12. Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Scope explosion | Kill criteria: no FINDINGS table in T days → freeze new setups |
| Cost blowup | Smoke suite; token caps; one model |
| Gameable graders | Locked tests; grade outside sandbox; no agent write to grader |
| Confounding model updates | Pin model id + date; freeze during suite run window |
| “Success” too weak | Require tests_locked; optional scope allowlist |
| Proxy time misread as cognition | Label explore/edit as proxy only |
| Lab becomes meta-career | Timebox; product work remains primary |

---

## 13. Phased plan

### Phase 0 — Spec lock (this brief + human approval)

- Freeze Q1–Q4, setups list, success definition, efficiency rule  

### Phase 1 — MVP portfolio (recommended first ship)

- 10–20 tasks  
- 3 setups: `bare`, `mini-skill`, `long-skill`  
- Metrics: success, tokens, wall_s  
- Smoke + full run + FINDINGS  

### Phase 2 — Force cage

- Add `force-cage`  
- Re-run suite; compare efficiency  

### Phase 3 — Toolization

- Stable CLI + setup YAML schema  
- Optional CI on lab repo (grade determinism on fixtures)  

### Phase 4 — Optional extensions

- Human blind ratings sample  
- Second model  
- Explore/edit proxies  
- Open-source release if still useful  

---

## 14. Kill / continue criteria

**Continue** if Phase 1 yields a clear table answering Q2 with cost, even if the result rejects H-steer.

**Pause lab development** if:

- cannot run ≥10 tasks × 3 setups within budget/time, or  
- graders are flaky, or  
- work displaces product/career anchors without a shipped FINDINGS.md  

**Expand to “tool”** only after Phase 1 FINDINGS exist and Daniel reuses the runner on a second suite or harness change.

---

## 15. Open questions for the evaluating AI

1. Is the MVP scope (3 setups, 10–20 tasks, one model) sufficient for a strong DS portfolio, or is `force-cage` mandatory in Phase 1 for narrative coherence with agentic-harness?  
2. Which primary efficiency denominator is better for the thesis: tokens, wall time, or tokens×time?  
3. Should tasks be Python-first (bootcamp DS) or TypeScript-first (agentic-harness dogfood)? Or dual mini-suites?  
4. Minimal viable runner: API-only single-shot vs real tool-using agent loop — what is the smallest loop that still tests “harness” rather than “chat completion”?  
5. Any critical confounder missing from §5 / §12?  
6. Naming: Harness Lab vs Agent Cage Bench vs Steer-vs-Force Eval — any collision with existing projects?  
7. Given bootcamp + career load, recommended calendar (hours/week) so this stays a lab not a cathedral?  

---

## 16. Suggested decision options (for human after AI review)

| Option | Meaning |
| --- | --- |
| **A — Portfolio MVP only** | Phase 1, stop at FINDINGS; no toolization |
| **B — MVP + force-cage** | Phase 1–2; best story for harness thesis |
| **C — Defer** | Capture idea; ship product work first; reopen under timebox |
| **D — Full tool ambition now** | **Not recommended** until A or B ships |

---

## 17. Summary for the reviewing model

This is a **serious, non-delusional** proposal: the field already shows harness/scaffold effects dominate many comparisons; the author wants a **small ablation lab** that fixes model and request, varies steer/force envelopes, and judges with **locked tests + tokens + time**, including the rule that **4× cost for equivalent success ⇒ inefficient setup**.

It is **not** a proposal to rebuild SWE-bench. It is a proposal to turn “force over steer” and “long skills are wide nets” into **pre-registered, falsifiable measurements**, usable as a data-science portfolio piece and later as a personal harness regression instrument.

**Default recommendation to implementers:** Option **B** if budget allows one force setup; else **A**, with force as Phase 2. Do not start with multi-model platforms or LLM judges as primary metrics.

---

*Brief written 2026-07-17 for external AI evaluation. Re-verify citations and market tools at implementation time; experimental claims in §11 are orientation, not a literature review.*
