# Harness Lab — decided spec (2026-07-18)

**Status:** decided design, pre-kickoff. Supersedes the exploratory
`docs/HARNESS-LAB-BRIEF-2026-07-17.md` (kept as the idea's origin) with the
decisions from the 2026-07-17/18 evaluation session. Every decision below
carries its why and what was rejected, so the owner can audit the reasoning.

**Owner's goal (verbatim intent):** measure the effectiveness of harness
setups against each other — e.g. a simple skill vs a complex one — to justify
choices with data and to tune agentic-harness itself.

---

## 1. The experiment in one paragraph

Same model, same task prompt, same grader — only the **envelope** changes
(no harness / short skill / long skill / force cage). Each run is graded by
tests written beforehand and locked, and priced in tokens and wall time. The
output is a table: which envelope passes more, at what cost — so harness
choices stop being taste and become measured trade-offs.

## 2. The weighing — does each element earn its place?

The owner's goal is two things only: **(a)** justify harness choices with
data, **(b)** tune agentic-harness. Every element below was weighed against
those two; anything serving neither was cut.

| Element | Serves (a)/(b) how | Verdict |
| --- | --- | --- |
| Microtasks + locked tests (D1) | The objective judge — without it there is no (a), only opinion | **Essential** |
| 4 setups incl. force-cage (D2) | The comparison IS the product; without force-cage, (b)'s core thesis stays untested | **Essential** |
| Identical success predicate (D3) | Without it the comparisons are invalid — silently kills (a) | **Essential** |
| Envelope vs dynamic tokens (D4) | Without it H-steer is confirmed by arithmetic — fake (a) | **Essential** |
| Pre-registered decision table (D7) | The bridge to (b): each result changes a named thing in the harness | **Essential** — this is what makes the lab load-bearing instead of curious |
| Real-CLI runner (D6) | Measures the harness people actually use; also 10× cheaper to build | **Essential** |
| Suite Zero first (D10) | Attacks the dominant risk (never finishing) | **Essential** |
| Temptation tasks (D5) | Measures layer A's actual claim (destruction avoided) — unique signal | **Supporting, high value** — in MVP, not Suite Zero |
| Placebo skill | Separates length from content — sharpens (a) | **Supporting** — Phase 3 only |
| Formulation ablation (canonical terms vs paraphrase, same content) | Tests the retrieval-cue hypothesis: canonical terminology activates the model's learned clusters, paraphrase is noise — turns skill-writing style from taste into data. Design rule: manipulate INSTRUCTION CONTENT terms only, never identity labels — the identity axis is already empirically dead (persona prompts don't improve objective performance: Zheng, Pei et al., Findings of EMNLP 2024, checked 2026-07-19) | **Supporting** — Phase 3 only |
| Blind human sample | Secondary sanity check on "maintainability" | Optional — only if FINDINGS v1 ships |
| Explore/edit time proxies (brief §6.4) | Curiosity; serves neither (a) nor (b) directly | **Cut from MVP** |
| cost_usd column | Pricing drift; tokens already carry the signal | **Cut** |
| Second model, multi-agent, toolization, dashboards | Scope traps named by the brief itself | **Cut from scope** (Phase 3+ at most) |
| Single showcase app (todo + auth + DB) | Not measurable objectively (see D1) | **Cut as data**; optional demo later |

## 3. Decisions made (with justification)

### D1 — Many small tasks, not one big app

**Decided:** ~20 microtasks (pure functions from failing tests, bug fixes,
simplify-under-locked-tests, boundary validation), each with a pre-written,
locked test suite as the objective judge.
**Why:** one big app (todo + auth + DB) gives one noisy data point per run
and no objective judge — "quality of a whole app" is opinion. Twenty small
tasks × 4 setups give 80+ gradable points and a paired analysis (which setup
succeeded where another failed).
**Rejected:** the single showcase app as the measurement unit (kept at most
as a later out-of-scope demo, never as data).

### D2 — Four setups in Phase 1, force-cage included

| setup | envelope | role |
| --- | --- | --- |
| `bare` | task text only | floor / pure model |
| `mini-skill` | ~10-line steer (simple code, preserve behavior, don't touch tests) | cheap steer |
| `long-skill` | long curated skill (Osmani-style simplification) | expensive steer / "wide net" |
| `force-cage` | mini (or no) skill + mechanical outer loop: verify must pass or re-invoke until cap | the harness thesis |

**Why force-cage in Phase 1:** without it the lab only compares steer with
steer, and the core thesis (force > steer) stays untested.
**Phase 2 addition — placebo skill:** same length as `long-skill`, generic
content-free advice. Separates the cost of *length* from the effect of
*content* — if long-placebo ≈ long-skill, wide nets are length, not wisdom.

### D3 — Identical success predicate across ALL setups (fix of brief §6.1)

```
success ≡ tests_pass AND tests_locked AND scope_ok
```

evaluated by the grader outside the agent's reach, identically for every
setup. `verify_green` inside force-cage is that setup's internal mechanism,
never part of the cross-setup success definition.
**Why:** if setups have different success bars, "equivalent success"
comparisons (the whole point of Q4) are meaningless.
**Rejected:** the brief's "(optional) verify_green if the setup defines it"
— a design bug.

### D4 — Envelope tokens separated from dynamic tokens (fix of brief §8.3)

Record `tokens_envelope` (fixed input cost of the setup, known before any
run) apart from `tokens_dynamic` (everything the run generates and consumes
beyond it).
**Why:** a long skill trivially costs more total tokens because it is long —
that is arithmetic, not a finding. The real question is whether it changes
*behavior* cost (turns, exploration, output) and success.

### D5 — Temptation tasks: measure destruction avoided, not only success

3–5 tasks with deliberate traps: messy adjacent code begging for drive-by
cleanup, a test that could be weakened, an "obvious" out-of-scope file.
`out_of_scope_files`, `tests_locked` and diff size then measure exactly what
layer A claims to prevent.
**Why:** the cage's value may be tail-risk prevention rather than average
quality; without these tasks that hypothesis is unmeasurable and a null
result on pass-rate would be misread as "the cage is useless".

### D6 — Runner drives the real agent CLI headless

`claude -p` / Agent SDK per trial (usage metrics from its JSON output), clean
workspace per trial, caps on turns/tokens/wall-clock, prompt-caching policy
equalized across setups. Force-cage is an **outer loop of the runner**: agent
finishes → grader runs verify → red and turns remain → re-invoke with the log.
**Why:** a hand-built API loop measures a toy, not the harness anyone
actually uses, and building it is the bulk of the project's cost.
**Rejected:** custom agent loop; multi-model in MVP.

### D7 — Pre-registered decision table (what each result changes)

The lab is load-bearing only if outcomes have consequences agreed BEFORE the
first run:

| Pre-registered result | Consequence in agentic-harness |
| --- | --- |
| long-skill ⊁ mini-skill on success, at ≥2× dynamic tokens | Skill body cap + "mini over long" doctrine become **measured** rows in CLAIMS.md |
| force-cage ↑ pass-rate at acceptable cost | force > steer graduates from doctrine to measured claim |
| force-cage ⊅ mini on efficiency, but wins temptation tasks | Honest relabel: the cage buys tail-risk prevention, not average quality |
| bare/mini destroy in temptation tasks, cage does not | Layer A gets its first quantitative evidence |
| No detectable differences anywhere | Published negative + steer growth freezes (only force enters) pending better instruments |

**Why:** without this table the lab is a curiosity; with it, every cell is an
owner decision currently made by taste, converted to data.
**New ledger status:** findings enter `docs/CLAIMS.md` as **measured** rows
(source: harness-lab suite vN) — the lab becomes the evidence supplier the
ledger lacks (today: 0 measured claims).

### D8 — Own repo, created at kickoff — and yes, gated by agentic-harness

**Own sibling repo** (`~/Dev/harness-lab`), created via `/kickoff` in a fresh
session in that folder (session scoping). Not a folder inside agentic-harness.
**Why:** the harness is the method repo; the lab is a consumer with its own
lifecycle, findings and possibly its own public future. Dependency direction
stays lab → harness (consumes a slice), per the brief's §9.

**Gated by the harness? Yes — it is the first real `/kickoff` consumer, and
skipping the cage on the instrument would undermine both projects.** What
applies, honestly labeled:

- **Machine layer: already force today** — containment, secret hooks,
  deliberation nudge fire in every session regardless of repo.
- **Layer 0 by doctrine, Python instance:** the lab is Python (pytest is the
  natural deterministic grader; the analysis is pandas/notebook). There is no
  `py-base` template yet, so kickoff assembles Layer 0 from the PLAYBOOK
  (verify = ruff + mypy + pytest on pre-commit and CI, deletion guard,
  gitignore, conventions skeleton) — and **`py-base` is extracted from this
  project afterwards**, the sanctioned extract-on-first-real-use path
  (Roadmap), a harness-candidate born from real consumption.
- **Rites copied with provenance stamps** (/feature, /audit, /debug), adapted
  from pnpm to the Python verify — deliberate, stamped divergence (ADR 9).
- **Ruleset + CI** per the kickoff checklist.

**The critical separation (so gating does not contaminate the experiment):**
the cage wraps the **instrument** (runner, graders, analysis — where a bug
means false findings); the **trials** run in sandboxed per-trial workspaces
whose only envelope is the setup under test. The harness must never leak into
a trial workspace; the selftest of the lab should assert that (a `bare` trial
workspace contains no harness files).

### D9 — Statistics sized to reality

Paired per-task analysis (helped/hurt counts), medians with bootstrap CIs,
effect sizes; no p-value theater at N≈20. Pre-registered honest limit:
effects under ~10–15pp are below this instrument's resolution. "No detectable
difference" is a publishable, pre-registered outcome (D7 last row) — the
suite does not grow until an effect appears.

### D10 — Suite Zero before MVP (completion risk is the dominant risk)

Walking skeleton first: **5 tasks × 4 setups × 2 runs (~40 trials) through
the COMPLETE pipe** (runner → grader → parquet → notebook → FINDINGS draft).
Only then scale tasks to ~20 and runs to 3.
**Why:** the realistic failure mode is an 80%-built lab with no FINDINGS —
worth zero. A small lab with published FINDINGS is the whole value.

## 4. Metrics (consolidated)

- **Success:** the D3 predicate, identical everywhere.
- **Quality proxies:** files_changed, loc±, out_of_scope_files, lint/complexity
  signals on the artifact; tests_locked as hard fail.
- **Cost:** tokens_envelope, tokens_dynamic, wall_s, turns, cap_hit.
- **Efficiency:** pass_rate; median dynamic tokens conditional on success;
  mean including failures; Pareto pass-rate × cost. The brief's "4× rule"
  stands as a pre-registered inefficiency threshold on dynamic tokens.
- **Explicitly not primary:** LLM-judge "simplicity" scores (circular),
  transcript self-reports, human vibes. Small blind human sample only as a
  labeled secondary.

## 5. Task suite rules

- Frozen before any setup runs (authorship bias guard); part adapted from
  external katas. First candidate external seed task: the planted-bug
  workspace of patchy631/ai-engineering-hub `build-code-harness` (2 real bugs,
  pytest 3F/2P, "fix only account.py, never edit a test" — bug-fix type with
  tests_locked + scope_ok built in; evaluated 2026-07-19, ledger C-086).
- Deterministic domains only (parsers, validators, scoring rules): no
  network, no clock.
- Layout per task: `task.md` + optional `src/` + locked `tests/` +
  `grade.json` (allowed paths, budgets).
- Caps generous and equal across setups; cap_hit reported per setup
  (force-cage loops must not be strangled by unequal budgets).

## 6. Phases and kill criteria

| Phase | Content | Gate to next |
| --- | --- | --- |
| 0 — Spec lock | This document + owner approval | Owner signs |
| 1 — Suite Zero | 5 tasks × 4 setups × 2 runs, full pipe, FINDINGS draft | Pipe produces a real table |
| 2 — MVP | ~20 tasks × 4 × 3, temptation tasks in, FINDINGS v1 | FINDINGS published |
| 3 — Extensions | placebo skill, formulation ablation (canonical vs paraphrase), TS mini-suite, second model, toolization | Only if reused after v1 |

**Kill criteria (owner sets the dates):** no running Suite Zero by
`____-__-__`, or no FINDINGS v1 by `____-__-__` → project parks (option C)
automatically, spec preserved. Lab work never displaces the career funnel or
product work — it is the 3rd priority by standing order.

## 7. Relationship to agentic-harness (summary)

| agentic-harness | harness-lab |
| --- | --- |
| Ships products; force > steer as doctrine | Measures envelopes; turns doctrine into data |
| CLAIMS.md: enforcement degrees, 0 measured | Supplies **measured** rows |
| Grows only via harness-candidate queue (ADR 18) | Findings feed the queue and the ledger, never auto-expand the catalog |
| Gates the lab's instrument code (D8) | Never gates the trial workspaces (D8) |

## 8. Open for the owner

1. Approve this spec (or mark deltas) — Phase 0 gate.
2. Set the two kill dates in §6.
3. API budget ceiling for Suite Zero + MVP (estimate: tens of USD; smoke ≪).
4. Kickoff timing (standing order: after the current interview-funnel week).
