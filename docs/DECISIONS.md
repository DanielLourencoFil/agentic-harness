# DECISIONS — one-line ADRs (the harness eats its own dog food)

Criterion for an entry: a fresh AI session would need it to avoid a wrong move.
External sources are cited **inline in the ADR they support**, with a checked-on
date — never in a separate SOURCES.md (a link without its decision is trivia, and
separate link files rot unread; see ADR 3).

1. **2026-07-09 — Template claims are enforced by a selftest in this repo's CI,
   not stated in prose.** An audit reproduced the README consumption path and found
   `verify` red on all three steps in an empty scaffold — the template had never been
   exercised in its primary use case. Root cause was structural (claims without an
   executor), so the fix is structural: `scripts/selftest.sh` consumes the template
   exactly as documented on every push.
2. **2026-07-10 — `AGENTS.md` is the canonical conventions file; `CLAUDE.md` and
   `GEMINI.md` are one-line adapters.** The standard is vendor-neutral and stewarded
   by the Agentic AI Foundation / Linux Foundation since 2025-12; read natively by
   Codex, Cursor, Copilot, Windsurf, Amp, Zed and (since spring 2026) Claude Code
   (source: https://agents.md/, checked 2026-07-10). Gemini CLI still needs the
   pointer file.
3. **2026-07-10 — Agent-agnosticism lives in the enforcement layers, not in porting
   agent permissions.** Git hooks, CI and rulesets are actor-blind; per-vendor
   permission files (`.claude/settings.json`) are defense-in-depth adapters, never
   the last line of defense. Corollary: the server-side gate (ruleset + required
   check) is the only guarantee that binds every agent.
4. **2026-07-10 — Sources inline in ADRs, dated; no separate sources file.** The
   fact a source supports is the decision itself; coupling them keeps both honest,
   and the checked-on date bounds staleness when links or facts drift.
5. **2026-07-11 — Brownfield section + provenance convention.** Trigger: the gaps a
   practitioner article made visible (C. Taurion, "A dívida técnica invisível da IA",
   LinkedIn, 2026-07-09, checked 2026-07-11) — legacy adoption and provenance were
   unaddressed here. Adopted: diff-held-to-full-standard + repo ratchet (monotonic
   violation counts), characterization-before-modification (established legacy
   practice — M. Feathers, *Working Effectively with Legacy Code*), audit-on-touch
   for inherited AI code, `Co-Authored-By` + PR provenance template. Rejected:
   enterprise DORA metric suites at solo scale (theater at n=1; the meaningful
   subset — red-CI rate, escaped defects, rework — feeds AGENT-LOG instead).
6. **2026-07-12 — Recurring rites are packaged as skills/agents; plan docs are views
   over tests.** A prompt retyped per session is governance by memory, and it rots
   (field lesson: a hand-ticked implementation checklist drifted until it lied).
   Adopted: `/feature` (spec interview → plan approval → negative tests first →
   evidence gate) and `/audit` + read-only `auditor` agent (fresh context, neutral
   framing, reify-to-test triage) ship in `ts-base/.claude/`; `/kickoff` (idea →
   `SPEC.md` → layer selection) lives in this repo's `.claude/skills/`. Honest label:
   skills are steer executed on invocation, not force; the binding gates remain
   verify/CI. The selftest asserts the files exist and the auditor stays read-only.
7. **2026-07-13 — External review absorbed through the rule generator: "Clean Code
   for AI Agents" (F. Akita, akitaonrails.com, 2026-04-20, checked 2026-07-13).**
   The article re-ranks Clean Code for the agent-as-reader; each claim was run
   through this repo's generator (syntactic signature → lint; else convention).
   Adopted: `max-depth: 3` as error + a negative selftest case (a wired rule must
   be seen rejecting); grep-first naming and site why-comments pointing at ADRs as
   `AGENTS.md` conventions (no syntactic signature); dual-reader rationale for the
   size caps (agent tool-call and context limits join human review-effectiveness)
   in RATIONALE. Rejected: coverage ≥80% as a target (gameable, and an agent
   produces test volume for free; behavior-gated tests + the brownfield ratchet
   stand) and explicit-types-everywhere (inference internally, explicit types at
   public boundaries stands).
8. **2026-07-13 — Conventions prose concatenates; nest a conventions file only where
   a subtree genuinely diverges.** Trigger: "shouldn't every folder have its own
   conventions file with its skills?". The three config channels resolve conflicts
   differently, and only two have an arbiter: **settings** resolve by precedence
   (enterprise > CLI > project-local > project > user; specific wins), **skills**
   shadow by name (project over user; shadowing is the specialization mechanism,
   not a conflict), and **conventions prose** just concatenates (root file plus
   subtree files, the latter loaded when the subtree is touched) with no mechanical
   arbiter. Therefore a child file refines, never contradicts: a contradiction is a
   config bug with undefined behavior, not a resolvable override. Corollaries: a
   nested file that would repeat its parent must not exist (duplicated prose drifts,
   and drifted prose lies); nesting is justified at genuine divergence boundaries
   (monorepo packages), not per folder. Conventions are always-on and charge context
   in every session: invariants only; procedures belong in skills (on-demand). A
   pointer line from conventions to a skill is a steering optimization for when
   description-matching fails to fire, not architecture.
9. **2026-07-13 — Skills come in three tiers; stack skills are vendored at kickoff
   with a provenance stamp; drift is detected, not blocked.** Trigger: kickoff needs
   a rule for which skills a new project starts with. Tiers: **universal-personal**
   (user dir `~/.claude/skills/`; never copied into repos, available everywhere by
   nature); **stack-family** (`/feature`, `/audit`: live in the template catalog,
   copied at kickoff according to the spec's stack); **project-specific** (created
   only when a heavy task recurs in the project, never speculatively at kickoff;
   YAGNI applies to skills, see the skill-per-principle anti-pattern). The dividing
   line between user dir and repo is "who must obey": if the repo must obey (any
   agent, any human, CI), the skill is versioned in the repo, reviewable like code;
   personal rituals stay in the user dir. Distribution is **vendoring, not
   reference/plugin**: a referenced catalog propagates silent behavior changes to
   every consumer (action at a distance defeats examinability); a copy may diverge
   deliberately. Each copied `SKILL.md` carries `source: agentic-harness@<sha>`;
   the selftest compares copies against the catalog and **reports** divergence
   (deliberate divergence is legitimate; ignored divergence is visible debt).
   Wiring pending (roadmap): stamp emission in `/kickoff` + drift report in
   `selftest.sh`. Until wired, this is a convention, honestly labeled.
10. **2026-07-13 — Filesystem containment is asymmetric: writes outside the project
    root are denied with a short allowlist; reads ask; Bash is contained by
    sandbox/worktree, not by command regex.** Trigger: proposal to forbid all file
    access outside the project root. Rejected as an absolute: a blanket ban breaks
    designed flows (agent memory dir, session scratchpad, package stores, `gh`
    config) and breeds prompt fatigue, where the human starts blanket-approving and
    the gate dies socially. Adopted: **write** outside root = deny-by-default with a
    named allowlist (agent memory, scratchpad); **read** outside root = ask, with
    hard denies on sensitive zones (`~/.ssh`, other projects' `.env*`); the blast
    radius lives on the write side. Mechanisms ranked by force: settings path rules
    (template baseline) → PreToolUse hook resolving the real path of file-tool calls
    (catches `../` and symlinks) → **Bash is the honest hole**: scanning command
    strings with regex is wired-but-blind (the `no-cycle` lesson, AGENT-LOG); real
    Bash containment is an OS-level sandbox. Precision: a per-session worktree
    isolates the git index (collision protection), **not** the filesystem — it is
    no security boundary; the process still runs with the full user's permissions.
    Negative selftest required before this counts as wired: an attempted write
    outside the root must be seen blocked.
11. **2026-07-15 — agentic-home folds into this repo as `home/` (the machine layer:
    constitution, secret-hygiene hooks, conversation rituals, bootstrap); 3 repos
    become 2 (method public, data private in the organizer repo).** Trigger: the
    3-repo split exceeded the owner's explanation budget (sessions of re-derivation,
    2026-07-15) and mislabeled method as private — nothing in the coding practices
    is secret; the real private boundary is the data. Adopted: `home/` as the
    reference implementation of the machine layer, delivered by symlink once per
    machine (vs. project stamps, copied per repo — content and delivery are
    different questions: the secret hooks must fire in sessions that have no
    project); career rituals (`/teach`) migrate to the data repo with the data;
    agentic-home archived, not deleted. Rejected: status quo (confusion tax recurs
    per session) and two public repos (keeps "why separate?" permanently open with
    no compensating gain).
12. **2026-07-17: Next round targets layer A, the portable anti-destruction
    discipline for the user's AI in any repo, including third-party.** Deliberated
    via /decide in the desk session. Order inside the round: (1) wire the mechanical
    core first: the ADR 10 write-containment hook plus a negative selftest case (a
    write outside the project root must be seen blocked); (2) close the short
    layer-A rule list (minimal diff, read before edit, no drive-by cleanup, shown
    evidence, claims anchored in repo paths); (3) package it in `home/`
    (constitution plus rite), labeled force vs steer honestly. Trigger: the harness
    only covers greenfield solo TS, the rarest real scenario; guest and legacy work
    is the actual year ahead (handoff 2026-07-15). Adopted: wirable-core-first (a
    round must end with something wired and selftested, never prose alone).
    Rejected: brownfield overlay now (its consumer is still hypothetical; flips the
    moment a real one exists), both fronts in one round (the 2026-07-15
    circular-session lesson), ADR 9 drift wiring (a single skill consumer so far).
13. **2026-07-17: The cross-project data repo (`~/Dev/organizer/`) joins the
    containment allowlist.** Trigger: minutes after the ADR 10 hook went live it
    blocked the backlog rite itself — the agent writing "do later" items to
    `~/Dev/BACKLOG.md` (realpath: organizer) from a project session. Two decided
    rules collided; the human resolved it the way ADR 10's own rationale dictates:
    the allowlist exists precisely for designed flows a blanket ban would break
    (agent memory, scratchpad), and the backlog rite is the same category. Wired:
    the hook's named allowlist plus a positive selftest case. Rejected:
    propose-a-line rite (returns backlog keeping to governance by memory) and
    human-only edits (same cost, without recording why).
14. **2026-07-17 — Skill infrastructure round: instructions demand verifiable
    artifacts; external material enters only through `/absorb`'s anchored claim
    table.** Trigger: reviewing A. Osmani's agent-skills catalog
    (https://github.com/addyosmani/agent-skills, checked 2026-07-17) — 24
    all-steer skills plus a router made the saturation risk concrete, while
    individual rows were worth stealing. Adopted: severity ladder
    (Critical/Required/Nit/FYI) + leverage ordering + quantified findings +
    security/performance axes in `auditor.md` (source: its code-review skill);
    alibi → short-declarative-reply tables in `/feature` and `/audit` (format
    from its TDD skill; open questions without anchors are decoration);
    dependency discipline in the template's `AGENTS.md` (one dep per PR,
    changelog before upgrade, stdlib-first, lockfile never by hand); the
    skill-writing doctrine in the PLAYBOOK with its mechanical half wired as
    `scripts/selftest-skills.sh` in CI (one-line description, body cap,
    mandatory "Verifiable output" section, negative fixture seen rejected);
    `/absorb` as the sweep tool (WATCH stance: steal rows, never install
    repos). Rejected: installing or vendoring the catalog (a referenced catalog
    propagates silent changes, ADR 9; 24 steer skills saturate context);
    review-speed SLAs and multi-reviewer process (team-scale ceremony at n=1).
    Roadmap: behavioral eval of skills (fixture with a planted bug via
    `claude -p`, weekly job, mechanical assertions only — honest label: form
    plus one case, not quality).
15. **2026-07-17 — agent-skills sweep, lot 1 (doubt-driven-development,
    test-driven-development, planning-and-task-breakdown; source:
    https://github.com/addyosmani/agent-skills, checked 2026-07-17; run via
    `/absorb`).** Adopted (3): bug fixes start with a reproduction test shown
    failing, green in the same commit (prove-it → `AGENTS.md` + PLAYBOOK Layer 0);
    tests assert outcomes never internal call sequences, and in test code readable
    duplication beats clever shared helpers (state-not-interactions + DAMP → same
    files); the non-trivial-decision trigger (branching / module boundary /
    type-unverifiable property / irreversible blast radius) enters `/decide` as its
    unprompted-use rule. Deferred (2, in BACKLOG with triggers): cross-model
    second-opinion review (trigger: first audit miss traced to a shared-model blind
    spot; read-only sandbox + stdin piping are load-bearing if it ever runs);
    planning material (vertical slicing, task sizing with the "and-in-the-title =
    two tasks" test, checkpoint cadence) folded into the pending `/plan` rite item.
    Rejected: adversarial reviewer framing (loses to the neutral-prompt
    anti-confabulation doctrine — reify-to-test is our arbiter, not
    finding-classification); `tasks/plan.md`+`tasks/todo.md` standing checklists
    (lose to ADR 6: plan docs are views over tests; hand-ticked checklists drift
    and lie); test-pyramid percentage quotas and small/medium/large size taxonomy
    (quota-shaped — "lowest level that can catch the bug" does the work);
    bounded 3-cycle doubt loops (single-pass audit + reify + human PR review at
    n=1). Lot adoption count: 3 (≥2) — the sweep continues to lot 2.
16. **2026-07-17 — Absorbed claims are registered in a cumulative append-only
    ledger (`docs/ABSORB/LEDGER.md`), one dated row per claim with a stable
    `C-NNN` id, source, verdict and anchor.** Trigger: the lot-1 tables lived
    only in the session log — no way to audit which claim an adoption addressed,
    trace which source it came from, or answer "do we already have a mechanism
    for this?" without re-deriving; the sweep's purpose was precisely to build
    this reference. The ledger is the entry point of the improvement pipeline:
    any incoming source is grepped against it first, and each claim resolves to
    already-addressed / new / better-than-ours (supersede by appending a row
    citing the old id) / principle-we-lacked. Rows are dated snapshots (anchors
    rot honestly, like ADR checked-on dates); `/absorb` requires the appended
    rows in its verifiable output; the selftest enforces id uniqueness and the
    closed verdict set, both seen rejecting a planted violation. Backfilled
    C-001..C-031 (the ADR 14 package + sweep lot 1). **Adopted rows carry their
    enforcement degree, honestly labeled — force / half-force / steer (force
    preferred, PLAYBOOK meta-rule; a bare "adopted" is rejected by the
    selftest):** an adoption must name how obedience is forced or at least
    where its violation becomes visible; unenforceable, unobservable obedience
    is decoration and gets rejected instead of adopted. Rejected: per-lot
    snapshot docs only (durable but not queryable across lots), PR-body-only
    records (not greppable; fails on zero-adoption lots), and adoption
    restricted to wirable-only claims (would exclude the load-bearing steer
    core — layer A's minimal-diff and no-gutting are steer by honest label).
17. **2026-07-17 — The ledger generalizes into `docs/CLAIMS.md`, the single
    source of truth for every claim the harness holds: internal guarantees and
    external evaluations, one format, one ID space.** Trigger: "what does the
    harness assure?" had no single place to ask — the answer was scattered
    across four selftest scripts, the PLAYBOOK and the ADRs, each in a
    different format, and re-derived per session. Adopted: internal guarantees
    backfilled as C-032..C-050 (source: harness, each citing its ADR and its
    executor); the enforcement mix (force / half-force / steer counts) printed
    by the selftest on every run — the measured guard against drifting into a
    prompt-and-pray skills repo; two new CI checks, both seen rejecting planted
    violations: coverage (every `scripts/selftest*.sh` gate must be indexed in
    the ledger) and executors (a force/half-force row must cite an existing
    executor file). Honest limit: existence checks, not semantic match — the
    prose-to-gate correspondence stays human (ADR 1). Rejected: two registries
    (internal vs absorbed — same question, two places to ask, formats drift
    apart) and a stored metrics section in the file (a written count drifts;
    the selftest computes it fresh each run).
18. **2026-07-17 — The strategy brief (docs/STRATEGY-BRIEF-2026-07-17.md, written
    by another AI session, evaluated via /absorb as untrusted testimony) yields
    one adoption: the `harness-candidate:` growth queue — the harness grows only
    from lines logged when a real product feature hurt, never from
    map-completion.** Ledger rows C-051..C-059. Its strongest content is the
    brake, which agrees with the standing BACKLOG ordering (dogfood OrgLab
    first; sweep behind product work). Deferred with triggers: evidence-as-force
    stop hook (first real evidence-gap incident), wired lib↛UI boundary (first
    consumer with a src/lib), LLM-in-product surface pack (next AI-in-product
    feature); kill/continue 90-day rule awaits the owner's explicit signature —
    governance is not the agent's to adopt. Already had: gitleaks pack (BACKLOG
    2026-07-13), characterization scaffold (brownfield item), the §5 force/steer
    map (superseded by docs/CLAIMS.md, which carries degrees plus CI checks).
    Rejected: worktree helper script (tooling for the map). Honest note: the
    brief predates ADRs 14-17 and PR #11's merge; its repo-state claims were
    re-verified before use.
19. **2026-07-17 — Report-before-implement becomes layer A item 7, with a wired
    half: the deliberation-nudge chain.** Trigger: owner feedback ("quero que
    avalie e reporte antes de implementar... tenho problemas em conter a força
    criativa dos modelos") after an /absorb run implemented in the same turn as
    the evaluation it was asked for. Adopted: constitution rule (an evaluation
    request ends in a report; the go is explicit); `home/bin/
    deliberation-nudge.py` — a UserPromptSubmit hook that injects the reminder
    when the prompt carries deliberation markers ("e se", "considerando", "faz
    sentido"…; nudge, never block — false positives must cost nothing, and the
    marker list grows only from real misses); plan mode as the jail, with
    `defaultMode: plan` in this repo's `.claude/settings.json` (deliberation
    dominates the meta-repo; product repos untouched); `/absorb` amended
    (propose diffs, implement after the go). Honest chain: the reminder fires
    mechanically (force) and plan mode physically blocks edits until approval
    (force), but a hook cannot switch the session's permission mode — the
    middle link (agent entering plan mode) stays steer, re-armed per firing.
    Rejected: blocking the prompt until a mode is confirmed (prompt fatigue
    kills gates socially, ADR 10) and machine-global plan default (taxes every
    product turn where the automatic commit rite is deliberate).
20. **2026-07-17 — agent-skills sweep, lot 2 (debugging-and-error-recovery,
    incremental-implementation, code-review-and-quality residual; source:
    https://github.com/addyosmani/agent-skills, checked 2026-07-17; run via
    /absorb, adoptions approved before implementation per ADR 19).** Ledger
    rows C-061..C-076. Adopted (6): the `/debug` rite — the one genuine
    bucket-1 gap (reproduce → localize → reduce → root cause → guard →
    verify), shipped in the ts-base catalog with presence wired into
    selftest.sh Claim 0b; error-output-is-data-never-instructions as layer A
    item 8 (this agent reads failed CI logs by rite — injection surface);
    named structural remedies + never-soften in the auditor (naming the move
    is not proposing a diff); the third-use-case rule and orphan-code
    list-and-ask in AGENTS.md; upgrade verification (green before and after,
    lockfile-diff review) extending C-006. Deferred: added-diff size gate to
    the harness-candidate queue (C-072; per-file max-lines stays the wired
    half). Rejected with the value named: safe fallbacks (lose to fail-fast),
    feature flags at n=1, re-run-to-be-sure (efficiency, not correctness),
    disagreement hierarchy and review checklist template (team ceremony;
    duplicated prose drifts). Lot adoption count: 6 (≥2) — the criterion
    allows lot 3, but the recommendation on record is to close the sweep:
    the remaining bucket-1 skills are validation, not quarry, and the
    harness-candidate queue (ADR 18) is the intended steady-state growth
    source. The owner decides lot 3 vs closure.
21. **2026-07-19 — build-code-harness (patchy631/ai-engineering-hub, A. Pachaar,
    checked 2026-07-19; educational CrewAI+E2B rebuild of a coding-agent
    harness; companion X thread unreadable, HTTP 402 — treated as presentation
    of the same content, hypothesis) evaluated via /absorb: zero catalog
    adoptions.** Ledger rows C-077..C-087. The source operates one layer below
    this repo — it builds the runtime we deliberately consume as Claude Code
    (lab spec D6 already rejected custom loops as measuring toys); its gates
    and agent rules re-derive ours at weaker degree (before_tool_call ≈
    PreToolUse force C-039; backstory rules ≈ layer A as prompt), an
    independent convergence data point for the harness map. Yields, both for
    the Harness Lab: the planted-bug workspace as first candidate external
    seed task (authorship-bias guard, spec §5, C-086) and E2B as trial-sandbox
    option if local isolation proves insufficient (C-079). Rejected with the
    value named: rebuilding the harness (D6), hierarchical planner/coder/tester
    crew (same-model costumes, handoff context loss; legitimate multi-agent =
    isolation-as-feature / parallelism / cross-model), embeddings memory
    (stdlib-first; file memory + native resume).
22. **2026-07-19 — The persona rejection gains its empirical anchor: Zheng,
    Pei, Logeswaran, Lee & Jurgens, "When 'A Helpful Assistant' Is Not Really
    Helpful: Personas in System Prompts Do Not Improve Performances of Large
    Language Models", Findings of EMNLP 2024 (checked 2026-07-19).** 162
    personas × 9 open models × 2410 MMLU questions: no persona statistically
    beats the no-persona control, several hurt, the effect does not improve
    with scale, and automatic best-role selection performs ≈ random. This
    turns the oldest Avoid line ("persona/tone theater", constitution +
    PLAYBOOK anti-patterns, README thesis) from doctrine-plus-field-anecdote
    into a cited, externally measured claim — ledger row C-088, the first row
    whose rejection carries external measurement rather than our judgment.
    Declared limits: MMLU factual QA, open-weight ≤72B, not agentic coding —
    the mechanism argument (force over steer) remains the primary ground.
    Design consequence for the Harness Lab formulation ablation: manipulate
    instruction-content terms only, never identity labels (the identity axis
    is measured dead); the paper's weak-but-directional mechanism results
    (term frequency ↑, prompt-question similarity ↑, perplexity ↓) are the
    citable prior for the owner's retrieval-cue hypothesis.
23. **2026-07-20 — AI-generated input is testimony, not a draft: layer A item
    9, with `/absorb` widened to fire before building anything from a foreign
    AI document.** Trigger: a live incident. The owner used Grok for a
    brainstorm, it produced the Harness Lab brief, and the brief was used as
    raw material to *write* the lab spec — so its unflagged assumption (metered
    API billing, standard eval practice) was inherited into spec D6 as a
    premise, never surfaced as "the brief's choice, is it yours?". Caught only
    by the owner's cost question (2026-07-20), not by any rite. Root cause:
    the strategy brief WAS run through `/absorb` (provenance preserved,
    C-051..C-059), but the lab brief was treated as a scaffold to build on, and
    scaffolds launder assumptions. Adopted: the distinction is testimony
    (etiquetada, evaluated claim-by-claim, authority zero until verified —
    good, the value of cross-model diversity, cf. C-019) vs. laundered premise
    (source tag lost, opinion washed into fact — bad); the rule is preserve
    provenance and epistemic status across the model boundary, not reject
    foreign input. Mechanism: extend the anchoring-law / audit-as-testimony /
    error-output-is-data family (C-063) to AI-generated decision input; the
    `/absorb` table is the friction that fluency removed (fact, opinion and
    assumption otherwise read with equal authority). Honest label: **steer with
    no wirable half** — the paste / IDE-selection channel has no gate and no
    hook can distinguish a foreign AI doc from the human's own words (same hole
    as secret-hygiene's IDE channel); the rite is the only mitigation, and
    routing through it is not forced. Freeze-exemption noted: this is layer-A
    provenance/safety steer, not quality steer, so it is admissible even under
    the proposed steer freeze (the load-bearing-steer exception, as with
    minimal-diff and no-gutting). The mix ticks to 26 steer — the honest cost,
    and exactly what the ledger exists to make visible. Rejected: a mechanical
    detector (no syntactic signature — content judgment, RATIONALE); rejecting
    cross-model input wholesale (loses the diversity value C-019 preserves).
24. **2026-07-20 — Closing the externalized-memory gap for audit and planning:
    the `/audit` reminder is wired, a minimum `/plan` rite ships, and CI
    auto-review is deferred with a cost flag.** Trigger: the owner named the
    contradiction — the harness's Principle 2 is "no check depends on me
    remembering to ask", yet `/audit` was steer executed on invocation, and the
    AI forgets as readily as the human, so "the AI will offer it" was
    insufficient. Adopted: (1) `home/bin/audit-reminder.py`, a PreToolUse(Bash)
    nudge on `gh pr create` — the natural completed-unit boundary — injecting a
    reminder to offer a fresh-context `/audit` before merge; nudge never block,
    and the agent applies judgment (offer for logic units, "N/A" for
    docs/ledger-only) so it does not over-fire (the ADR 10 social-death lesson);
    the audit runs as the read-only `auditor` subagent = fresh context AND zero
    marginal cost on a fixed plan. Honest label: **the reminder is mechanical
    (half-force); acting on it stays steer** — ± cases in `selftest-home.sh`.
    Dogfood: the hook fired live on its own ADR-writing command (which contained
    the literal string) — confirming the `additionalContext` surfaces AND
    exposing a data-vs-invocation false positive, fixed by anchoring the match
    to a command boundary, the miss reified as a negative selftest case.
    (2) A minimum `/plan` rite (`home/skills/plan/`, personal tier like
    `/decide`), the planning layer between `/kickoff` and `/feature`: one-sentence
    objective, anchored inventory, vertical slices sized to one session, live
    decided/rejected/open log, stop with decisions. v0 — the owner's reasoned
    case updated the prior "wait for pain" stance (ADR 9): planning is a
    documented process, the rite is already specced, and it has an imminent
    consumer (the lab kickoff), so building it minimal-and-provisional to be
    *used* there beats ad-hoc planning; the lab kickoff is its field test.
    Deferred: (3) CI auto-review on PR — it runs `claude -p` in Actions = metered
    API, which contradicts the fixed-plan decision (lab spec D6); trigger = the
    in-session audit proves insufficient AND a credit budget is approved. This
    is a closed, documented decision (not a loose end); wiring it now would pay
    API to review docs — theater. Freeze note: (1) and (2) are process/rite
    mechanisms (externalized-memory / layer-A family), not quality-doctrine
    steer, so admissible under the proposed steer freeze. Rejected: an "ask"
    permission-prompt on every `gh pr create` (over-fires on docs PRs → fatigue);
    firing on `git commit` (wrong granularity — many commits per unit).
25. **2026-07-20 — Owner governance signatures: the agent-skills sweep is
    closed, the steer freeze is active, and the 90-day kill/continue rule is
    armed.** All three signed by the owner on 2026-07-20 (governance is the
    owner's act, not the agent's). (1) **Sweep closed:** no lot 3 — the
    remaining bucket-1 skills were validation, not quarry (ADR 20); the
    `harness-candidate` queue (ADR 18) is now the SOLE growth source, fed only
    by real product pain. (2) **Steer freeze active:** no new quality-doctrine
    steer enters the harness until the Harness Lab produces measured FINDINGS v1
    (spec kill-date 2026-09-15) — the current steer mix is the frozen baseline
    the lab will measure down. Still admissible: force and half-force always,
    plus layer-A / provenance / safety / process-rite steer (the load-bearing
    core — how ADR 23 item 9 and ADR 24's /plan + audit-reminder entered).
    Honest label: the freeze is convention, not force — "quality-doctrine vs
    safety steer" is a semantic judgment, not mechanically detectable; the
    visibility is the selftest's per-run mix printout, and `/absorb` now defers
    non-exempt steer to a post-lab queue. Future reification noted, not built: a
    steer-count ceiling in the selftest (ratchet — adopted-steer may not rise
    above the baseline without an explicit exemption marker). Note the honest
    optic: recording these two governance rows ticks the mix to 29 steer — they
    ARE conventions (steer), self-exempt like layer-A; the freeze targets
    doctrine steer, not its own governance record. (3) **Kill/continue armed
    (supersedes C-058's deferral):** by ~2026-10-17, if the harness has not
    measurably reduced review cost or "IMPLEMENTED — NOT VERIFIED" incidents on
    a real product, the meta-repo freezes and harness work is capped as a tax on
    shipping (~≤20% of eng time). Rejected: continuing the sweep (diminishing
    returns, ADR 20); leaving the freeze and kill-rule as unrecorded steer that
    grows silently (the ledger rows make both greppable at the next /absorb).
26. **2026-07-26 — The plan-mode draft dir (`~/.claude/plans/`) joins the
    containment allowlist, so plan approval stops happening blind.** Trigger:
    plan mode writes its draft to `~/.claude/plans/<name>.md`, which the ADR 10
    hook denied from every project session — observed 2026-07-20 at the
    harness-lab kickoff and again in calendar-app, where the agent had to paste
    the plan into the chat and note the block in the file's own header. Reported
    consequence, not independently verified: `ExitPlanMode` renders that file,
    so with no file the approval screen has nothing to show and the human
    approves an artifact he does not have in front of him. This is ADR 13's
    shape exactly: a fixed dir of agent-written drafts, not project data — the
    same category as the agent memory dir already on the list, and the allowlist
    exists precisely for designed flows a blanket ban would break. Wired: the
    hook's named allowlist (plus its docstring and denial message, which
    enumerate the list in prose and would otherwise lie) and a positive
    `selftest-home.sh` case — without the assertion the new entry has no gate
    and breaks silently at the next edit. Freeze note: this is force (ADR 25
    admits force always), not quality-doctrine steer. Honest cost, the owner's
    to sign: it is the 4th entry in a list the owner closed on 2026-07-17, and
    each exception makes the next one easier to argue — the defense is that the
    list stays named, short and selftested, never a pattern. Rejected: leaving
    it blocked (durable plans do go to `docs/PLANS/` per the human's own rule,
    but the approval screen would stay empty forever — a harness feature
    degraded by another gate); routing the write around the hook via Bash (that
    uses ADR 10's honest hole to escape ADR 10).
27. **2026-07-29 — The claims ledger's completeness becomes a gate in both
    directions, and the containment allowlist can no longer outlive its own
    prose.** Source: the calendar-app session's two governance gates (commit
    `28926b0b`, `scripts/clone-budget-check.js` and
    `apps/web/src/lib/components-registry.test.ts`, checked 2026-07-29), absorbed
    per ADR 23 — foreign-session output is testimony, so it entered through
    `/absorb` and not as a scaffold. Their transplantable insight is not either
    script: it is that **a registry covering part of its territory is worse than
    no registry**, because whoever greps it searches, finds nothing, and
    concludes the thing is absent — a failed search is not proof of absence.
    Their instance: `docs/COMPONENTS.md` mapped 7 of 45 shelf files. Applying
    the same test here found the harness had built half the pattern already
    (`check_coverage` = artefact→row, `check_executors` = row→reality, ADR 17)
    with a map that only covered `scripts/selftest*.sh` — so
    `home/skills/checklist/SKILL.md`, a rite shipped since ADR 9, had no ledger
    row and no `/absorb` run would ever have found it. Wired (C-096/C-097):
    coverage widened to hooks, personal rites, repo rites, template rites and
    template scripts; executor refs now read the Where column only and verify
    path-carrying refs as exact paths (basename matching kept passing after a
    move); the containment allowlist's count is pinned at 4 and both prose copies
    — docstring and denial message — must name all four entries, which is ADR
    26's own worry ("would otherwise lie") turned into a gate; four new negative
    cases, and direction 1 was seen rejecting real content (the `/checklist`
    row), not only a planted fixture. Freeze note: all of this is force, which
    ADR 25 admits always; the doctrine that came with it travels in the
    artefacts' header comments, not as new PLAYBOOK steer. Honest limit: the
    stem fallback in `check_coverage` accepts a compound name mentioned in prose
    (C-036 anchors `deletion-guard.mjs` to the gate that proves it, not to its
    own path), so coverage proves an artefact is *mentioned*, not that its row is
    good. **The gate's own first defect, worth recording because it is the exact
    failure it exists to prevent:** as first written, coverage grepped the whole
    ledger line, so the brand-new `templates/ts-base/scripts/clone-budget-check.mjs`
    counted as indexed — the name appears in C-098's *Source* column, describing
    the calendar-app's file. It passed green while blind. Fixed by restricting
    the index to the claim and Where columns ($5, $7): provenance of someone
    else's file is not a claim about ours, and there is now a negative case
    pinning it. Rejected: extending the ghost-executor check to steer and
    rejected rows — the ledger's own contract says a row is a dated snapshot that
    "may rot honestly", and only a live force/half-force guarantee needs a live
    executor; a single-word stem fallback (`verify` appears everywhere and would
    prove nothing).
    **Second half, same absorb (C-100…C-104): the copy-paste budget ships in
    `ts-base`.** `scripts/clone-budget-check.mjs` + `.clonebudget.json` at 0,
    wired inside `verify` (so CI enforces it, not only the local hook) and
    asserted by `scripts/selftest.sh` Claim 5 in both directions — a verbatim
    8-line paste blocked and named, and a shrink allowed to pass. It converts
    AGENTS.md's existing reuse-scan convention into force rather than adding
    doctrine, which is why it is freeze-clean; at 0 in a fresh scaffold it is the
    zero-warnings rule with a named escape hatch, not the warning budget the
    PLAYBOOK forbids in greenfield. The port fixed two defects present in the
    source instance: git's stderr was inherited, so outside a work tree ~100
    lines of usage text buried the gate's own message, and the three git commands
    shared one try/catch, so `diff HEAD` failing in a repo with no commits — that
    is commit #1, the scaffold — silently voided the author-scoping. **Declared
    limit:** `vue-starter` does NOT get this gate in this change. It defines its
    own `verify` and copies only the deletion guard from `ts-base`, so nothing
    breaks; but the scanner reads `.ts`/`.tsx` only, and a Vue project's
    duplication lives partly in `.vue` template and style blocks. Shipping it
    there would gate the composables and silently miss the SFCs, which is the
    half-covered map this very ADR is about. BACKLOG'd with the trigger. Still
    deferred: the creation-moment hook (C-099 — no instance exists anywhere yet;
    `/decide` before any code).
28. **2026-07-30 — The gates written for ADR 27 were audited in fresh context and
    all four could pass while blind; 16 correctness findings fixed, every one
    reified as a negative case.** The audit was requested by the owner and run as
    a read-only subagent (PLAYBOOK admits "new session or subagent"), scoped to
    the four files ADR 27 touched, with the neutral prompt template. It reported
    16 correctness findings, 8 implementation problems, 4 architecture concerns
    and 3 leads. Triage outcome: **0 confabulated.** Three were re-verified by
    hand before any fix — one of those (the inline-comment paste) failed to
    reproduce on the first attempt because the fixture built here had nine lines
    instead of eight; the auditor's fixture was correct and mine was not, which is
    worth recording as a caution about dismissing a finding on one failed repro.
    The severe class, and the reason this ADR exists: **`check_allowlist` stayed
    green while writes to `/etc/` were allowed.** `grep -c` counts matching
    *lines*, so a fifth exemption appended to an existing line read as one; and
    retargeting an exemption (`~/Dev/organizer/` → `~/Dev/`) changed nothing the
    check looked at, because it compared counts to the code and strings to a list
    hardcoded in the test, never the code to its own prose. The fix that matters
    is not a better parse: it is **near-miss behavioural denials** — one step
    outside each entry must still be denied — the only half a refactor of the
    Python cannot dodge. Same lesson in `check_coverage`, whose substring index
    let a rite reuse another layer's directory name, a prefix satisfy a longer
    name, and a same-stem `.sh` inherit the `.mjs` row: now whole-token literal
    matching on the repo-relative path, with basenames accepted only where this
    repo ships exactly one such file — and that ambiguity set computed from the
    real repo, since in a two-file fixture every basename looks unique (found by
    the fixture itself). `check_executors` gained the rule its own error message
    already implied: a force row citing only prose is prompt-and-pray, so it must
    cite something executable (C-110 supersedes C-101, which promised force while
    anchored to a config file and a header comment). The clone detector was wrong
    about comments in both directions — a line opening and closing a block comment
    lost the code after it, taking an 8-line paste to 7 and under the window,
    while a comment opened mid-line had its prose hashed as logic — and its count
    depended on `readdirSync` order, so identical source could be red on one
    machine and green on another. Enforcement mix after: force 27 · half-force 5 ·
    steer 30 (+7 force, no new doctrine steer; ADR 25 admits force always).
    Method note, the durable one: **an audit of a gate must ask "can this pass
    while blind?", not "is this code correct?"** Every finding above is a green
    run over a broken guarantee, which is the only failure mode that matters in a
    gate and the one ordinary review does not look for. Rejected: extending the
    ghost-executor check to steer and rejected rows (the ledger's contract says a
    row is a dated snapshot that "may rot honestly"; only a live force guarantee
    needs a live executor); editing C-101 in place to fix its anchor (rows are
    append-only — "supersedes C-NNN" is the mechanism, and the gate now reads it).
    Honest limits carried forward: the clone detector does not understand comment
    markers inside string literals (a parser is a dependency this gate does not
    justify), and `vue-starter` still has no budget because `.vue` blocks are
    unscanned — both declared in place and BACKLOG'd rather than papered over.
29. **2026-08-04 - Bash containment: the hook claimed a sandbox that does not
    exist, and the denylist-first model the owner wanted turns out to be natively
    supported.** Trigger: permission fatigue had pushed 24 rules into the machine
    layer without a decision, four of them arbitrary code execution (`python3 -c`,
    `node -e`, `pnpm exec`, `npx`), because `~/.claude/settings.json` is a symlink
    into this repo (`home/bootstrap.sh:21`), so a grant made while working on
    another project lands in the cage that ships everywhere. The owner asked the
    right question: which commands are genuinely no-go, and can everything else
    run unasked. Measured before deciding, all on this machine, 2026-08-04:
    (1) a plain Bash command wrote into `$HOME`, wrote into a sibling project,
    read `~/.ssh` and reached the network, with no sandbox flag set, which
    falsified the docstring in `home/bin/write-containment.py`; (2) Claude Code
    2.1.50 exposes no Bash sandbox setting, so there is no switch to flip and
    containment must come from outside the product, a point its own help text
    concedes by recommending the bypass flags "only for sandboxes with no internet
    access"; (3) under `--permission-mode bypassPermissions`, PreToolUse hooks
    still fire (a Write outside the project root was blocked by the ADR 10 gate)
    and `deny` permission rules still fire (`git commit --no-verify` was invoked
    and refused by the permission layer, not by the model). Decided: denylist-first
    is correct as a safety net and wrong as a boundary, since destruction cannot be
    enumerated over a shell and reading key material to send it away is not
    destructive at all; but because measurement (3) holds, it needs no custom
    mechanism from us. `bypassPermissions` plus a `deny` list is the model the
    owner described, using the product's own gate, and the `bash-denylist.py` hook
    drafted for this decision is not built. Containment stays the only thing that
    bounds the unenumerable, and measurement (2) says it must be a container.
    Rejected, and this corrects the first draft of this same ADR: an interim
    posture that turns the bypass mode on now and compensates with a longer deny
    list, pending the container. It is inadequate for this harness while the shell
    is uncontained, because it removes the last remaining control on the one
    surface that has no other defense, which is where its entire effect lands. The
    order is not ergonomics now and containment later; it is containment, and only
    then a review of permissions, since a bounded blast radius is what makes broad
    permissions cheap. Recorded because the draft framed the trade as the owner's
    risk appetite, which is the wrong question: adequacy against the harness's own
    premise, that tooling and not prompting is what rejects bad output, is a
    property of the design rather than a preference. Prompt fatigue is a real cost
    and the answer to it is the container, never the removal of the checkpoint.
    Rejected: `--dangerously-skip-permissions` as a posture, since it drops the
    deny rules that measurement (3) shows are the load-bearing half; per-command
    `bwrap` or `unshare` wrapping, since a PreToolUse hook decides allow or deny
    and cannot rewrite the command, and neither tool is installed. Declared limit
    of the recommended path: a container bounds the write radius, not the
    read-and-send one, so the ADR 23 threat model of a manipulated agent stays
    partly open until network egress is addressed too. Method finding, worth more
    than the result: two of the three probes measured nothing, because the agent
    refused on constitutional grounds before invoking the tool, and a refusal
    tells you about the prisoner, not the cell. Only the probe that explicitly
    instructed the agent to attempt the call reached the gate. This sharpens the
    2026-07-10 lesson: a wired rule is not live until seen rejecting a violation
    that was actually attempted.
30. **2026-08-04 - A recommendation must declare what verified it, and the
    anchoring law loses its "about a repo" scope.** Trigger: three recommendations
    in one session were made from what seemed reasonable rather than from
    measurement. Cut the `workflow` scope, which turned out to be required for
    pushing any commit touching `.github/workflows/` over an HTTPS remote, and
    which the calendar-app used 5 hours earlier. Cut the `gist` scope, which `gh`
    documents as unremovable from its minimum set, and which closes nothing while
    `repo` can create and push a public repository. Adopt a permissive permission
    mode as an interim posture, which contradicts the harness's own premise and
    was withdrawn in ADR 29. The common shape is not carelessness about facts: it
    is that each was stated without the check that would have settled it, and two
    of the three had an adjacent measurement that did not cover the claim.
    Diagnosis, and it is the useful part: inside the repository every assertion in
    that session carried a command and its output, and the discipline was dropped
    the moment the subject moved to a GitHub account and a permission model, which
    the anchoring law appeared not to cover because it read "every claim about a
    repo". A second mechanism compounded it, that a conversation with momentum
    treats every turn as needing an actionable next step, and invents one when
    none is warranted. Adopted: the scope limit is deleted from the law, and a
    recommendation is named explicitly as a claim that carries its verification or
    an honest label. Wired as the first Stop hook in this harness
    (`home/bin/recommendation-anchor.py`), which reads `last_assistant_message`
    and blocks once when recommendation markers appear with no declaration line
    from the closed set (Verificado, Medido, Não verificado, Hipótese, and their
    English forms). The mechanism was measured before being proposed: the Stop
    event carries `last_assistant_message` and accepts `decision: "block"` with a
    `reason` fed back to the model, which is what makes any of this possible, and
    no prior hook in this harness could see the agent's own output. Honest label:
    half-force. The firing is mechanical, the truth of the declaration is not, and
    the hook cannot judge whether a measurement covers the claim it is attached
    to, which is precisely the class two of the three failures belonged to. It
    catches the pure-memory recommendation, and it makes the other class visible
    by forcing an author with nothing to declare to write that down. Rejected:
    leaving this to the reworded law alone, since steer is what already failed
    here; and a stricter gate keyed on whether the turn contained any tool call,
    which would fire on every legitimate follow-up answer and die of fatigue,
    the failure mode ADR 13 already names.
31. **2026-08-04 - The creation-moment shelf hook asks the human and informs the
    agent, because the reason field reaches neither.** Trigger: C-099, deferred
    since 2026-07-29, built on owner override, since the second half of its
    trigger (a recorded duplication the registry gate missed) never fired. The
    gap it closes is real and neither existing gate covers it: the registry test
    catches "you did not document it" after the fact, and the clone budget is
    blind to a rename, so a semantic duplicate under a different name passes both.
    The design carried in BACKLOG said to inject the inventory as
    additionalContext by analogy with deliberation-nudge, which is a
    UserPromptSubmit hook doing a plain print, while this is PreToolUse; the right
    precedent is audit-reminder.py. Five probe runs on 2026-08-04 settled the rest,
    and each answer contradicted the obvious design: permissionDecision "ask" does
    stop the write and reach the human; permissionDecisionReason NEVER reaches the
    human on a file operation, 874 characters emitted and zero seen across all
    five runs, because the IDE diff occupies that space; additionalContext DOES
    reach the agent alongside "ask", confirmed by the probe agent stating so and
    then naming `calendar` as the overlap with the requested `date-range-picker`,
    which is exactly the semantic-duplicate case. Adopted: ask with a one-line
    reason for the human, inventory plus shelf path as additionalContext for the
    agent, firing only on a file that does not exist yet, only for direct children
    of a directory it judges to be a shelf. **Corrected the same day, before
    merge:** the first version required `.claude/shelf.json` per project, which
    traded "the agent must remember to look" for "the human must remember to
    declare", the same disease renamed, as the owner said on reading it. A
    directory now qualifies on two measured signals and no setup: at least 10
    files (something worth duplicating) AND at least 10 distinct directories
    importing from it (genuinely shared). Both are needed, and the pair was
    chosen from data rather than from folder names, an earlier classification
    that measurement refuted: across the reference repo's 18 sibling directories,
    `ui` (39 files, fan-in 63) and `booking` (30, 16) are real shelves, while
    `landing` (28, 2) and `public-page` (14, 2) hold as many files but serve one
    screen, so a size rule alone fires on them; fan-in alone would catch
    `platform-admin` (6 files, fan-in 13), where nothing is worth deduplicating.
    Together the pair fires on 3 of 18 and all 3 are correct, including
    `apps/api/test` at 118 files staying silent. `.claude/shelf.json` survives as
    an override, not a prerequisite: an explicit list wins, and an empty list
    disables. The context names the shelf path and forbids searching
    elsewhere, because both runs that carried bare names sent the agent hunting
    for the source, one sweeping ~/Dev and the other walking into a sibling
    project to read its components, which Bash allows since it is uncontained
    (ADR 29). A shelf check that crosses into another repo imports its conventions
    by accident, which is worse than the duplication it was meant to prevent.
    Rejected: injection alone, which does not prevent, since the tool runs and the
    duplicate is on disk before the agent sees anything; the inventory in
    permissionDecisionReason, measured dead for file operations; deny, which
    without an escape makes a new shelf component impossible. Honest label:
    half-force. The pause and the inventory are mechanical, recognising that Btn
    is Button stays judgment, and the threshold of 10 is a starting point taken
    from one repo's distribution rather than a measured optimum.
32. **2026-08-05 - Layer 2 React ships, Next gets a documented overlay, and the
    ADR 25 steer freeze is broken here by explicit owner decision.** Trigger: a
    live-coding exercise on React or Next, two days out, against a harness whose
    only framework layer was Vue. Measured first: `ts-base` is framework-agnostic
    and already covers a React project's cage entirely, so the gap was Layer 2 and
    not the cage. The PLAYBOOK's React section already prescribed the rules
    (`rules-of-hooks`, `exhaustive-deps` as errors) but nothing was packaged, and
    `grep -ciE "server component|rsc|use client|app router"` over the PLAYBOOK
    returned 0, which is the dominant failure surface for AI-written Next in 2026,
    since the training corpus predates the App Router. Adopted:
    `templates/react-starter`, an overlay on `create-vite react-ts` in the shape of
    `vue-starter`, consumed end to end by `scripts/selftest-react.sh` in CI, which
    also plants eight violations and requires each to be rejected: any, ==,
    non-exhaustive switch, import cycle, depth, a hook behind a condition, a lying
    dependency array, React inside the pure core, and a duplicated block.
    `exhaustive-deps` is pinned to error against the plugin's own default, because
    a lying dependency array reproduces only on the second render. Next arrives as
    one extra file rather than a second template, `eslint.next.mjs`, layering
    `core-web-vitals` with every rule pinned to error: Next ships most as warnings
    and this harness has no warning level. Two things were checked rather than
    assumed before writing that file: the plugin's flat-config export shape and its
    22 rules with their default severities, inspected 2026-08-05, and the earlier
    guess that a template selftest costs 20 minutes of CI, which measurement put at
    41 seconds. Freeze note, and it is the load-bearing one: the conventions in
    `react-conventions.md` and the new PLAYBOOK Next section are **quality-doctrine
    steer**, which ADR 25 froze until the lab's FINDINGS v1. They enter by explicit
    owner decision, recorded here as an override rather than drift, exactly as the
    C-099 trigger override was. Declared limits: the Next path has no selftest job,
    so the Vite path is proven and the Next overlay is only documented; and the
    interview scenario itself is served by the machine layer, which travels to any
    session including a repo nobody may install into, rather than by a template
    nobody has time to stamp under a timer.
33. **2026-08-05 - Two posts by R. C. Martin absorbed: nine claims, zero adoptions,
    and one stale deferral closed.** Source: @unclebobmartin on X, 2026-07-26,
    checked 2026-08-05. Post one argues that since agents generate fast, the
    programmer's time reallocates to writing unit, acceptance, property, torture,
    mutation and QA tests, and that the result is still many times more productive
    and better. Post two describes agents building him a dependency-checking tool
    whose architecture he specifies and they enforce, plus a UML viewer that finds
    cycles. Already have, anchored: the reallocation premise is the feature loop
    itself (PLAYBOOK.md:416-420); cycle detection is `import-x/no-cycle` as an error
    in all three templates, recorded seen firing in C-037; the general layer map was
    already scoped out at PLAYBOOK.md:177, which says to use arch-boundary tooling
    on a large layered codebase and keep only the pure-core rule on a small app; and
    the risk implicit in "I had my agents build the tool", that a gate written by
    the agent it constrains encodes the same misunderstanding and reports green, is
    the harness's own scar (AGENT-LOG 2026-07-10, and four such gates found blind in
    the 2026-07-30 audit). Rejected: "many times more productive and the result will
    be better", unfalsifiable as stated and losing to C-093, the kill/continue rule
    that refuses this exact assumption about this repo; and the UML viewer, which
    informs without blocking and duplicates what no-cycle enforces, losing to
    force-over-steer and to the documented-but-unwired anti-pattern. Deferred with
    triggers: property-based testing (C-120), which is a practice without a consumer
    here; and mutation testing (C-121), already queued since the 2026-07-27 dogfood
    finding and scoped to an allowlist, since STRATEGY-BRIEF:211 rejects it globally.
    Closed as a side effect: C-053 deferred "executable architecture boundary, wired
    not optional" on 2026-07-17 with the trigger "wire in vue-starter when a
    consumer's src/lib exists"; that trigger fired and the work landed in both
    vue-starter and react-starter with negative tests, and nobody updated the row.
    C-123 supersedes it as adopted. The useful shape of this run: an external source
    from a famous author produced no new practice, confirmed four decisions already
    made, and its only genuinely sharp item (mutation testing measures test power
    rather than volume) was already in the queue from our own dogfooding. That is
    the ledger working as designed rather than a disappointing source.
34. **2026-08-05 - Three deferrals whose triggers had fired, built in one session:
    the evidence gate, the shelf-hook closure, and the diff-size nudge.** Trigger:
    a sweep of the ledger's 17 deferred rows found several stale, in the C-053
    pattern where a trigger fires and the row is never updated. Three were live.
    (1) **C-051, evidence as force.** The constitution's oldest rule — an "it works"
    claim carries the command output that proves it (C-047, steer since
    2026-07-11) — was deferred for a wired version because in July nobody knew a
    hook could read the agent's own output. ADR 30 proved it could. `evidence-gate.py`
    is a Stop hook that blocks a completion claim unless a verification command
    actually RAN this session, parsed from the transcript's Bash tool calls, never
    from prose: a `grep -n "vitest\|test"` mentions the tool as data and must not
    count, which was measured against a real 2282-line transcript before wiring
    (62 matches dropped to 59, the three being exactly such greps). An honest
    "IMPLEMENTED - NOT VERIFIED" is the sanctioned escape. Half-force: it proves a
    command ran, not that it passed or covered the claim. (2) **C-099 closed.** The
    shelf hook was built on 2026-08-04 (C-114/C-115) while its deferred row still
    read "deferred", the C-053 disease 24 hours later; C-129 marks it built.
    (3) **C-072, diff-size nudge.** Trigger was "first monster PR", and this very
    branch is 1354 added lines. `diff-size-check.mjs` warns past ~300 added lines
    vs the merge-base with the default branch. Deliberately warn-not-block, stated
    as a design decision rather than timidity: the per-file max-lines 300 cap is
    the blocking half already, total added diff is a fuzzy branch metric, and a
    hard block on it would punish large-but-coherent work (a template plus its
    selftest) and teach splitting by line count rather than by concern. It fails
    open with no git or no base ref, because a size hint is not worth breaking a
    push. Each of the three was seen rejecting or warning on a planted case in
    selftest before landing, and the git-mode gate built this morning caught
    evidence-gate.py shipping 100644 — the harness applying its own lesson to its
    own new files. Rejected across all three: making any of them a hard block that
    would fire on this session's own legitimate work. Enforcement mix after: force
    30, half-force 10, steer 31.
35. **2026-08-05 - Test quality gets a fresh-context audit rite (Phase 1); mutation
    is its reify arm (Phase 2, not built).** Trigger: the harness forces tests to
    PASS but nothing checks they are the right tests or have power; the owner was
    the manual hook for it ("podemos escrever um teste aqui?" on Kinous), and the
    owner sharpened it: the review of test correctness can itself be an agentic
    audit, not left to human memory. Measured first: the existing /audit is
    implementation/bug focused (`templates/ts-base/.claude/skills/audit/SKILL.md`),
    the `auditor` agent is free on the fixed plan and read-only by construction, and
    Stryker (9.6.1) supports a native `--mutate` allowlist and `--incremental`,
    which is what makes a scoped, cheap Phase 2 possible. Adopted (D, phased):
    **Phase 1 now** — a separate `/audit-tests` rite driving a read-only
    `test-auditor` agent with a test-specific lens (missing negative, wrong level,
    weak assertion, coupled-to-implementation, non-determinism, could-never-fail),
    fresh-context so the authoring session's bias is removed. Its triage differs
    from /audit by kind: missing-case findings reify by writing the red test;
    wrong-level findings name the structural move; weak-assertion findings are the
    ones only mutation can settle and stay OPEN until Phase 2, never closed on a
    green run. The authoring session RESPONDS to findings but does not judge them,
    because it is contaminated; the human decides. **Phase 2 later** — Stryker with
    the allowlist pointed only at the modules Phase 1 flagged, scoped to `src/lib`,
    wired only once Phase 1 produces real findings, which is how C-121 (mutation
    testing) lands: not as a standalone gate but as this audit's reify arm.
    Separate rite, not an extension of /audit: bug-framing and test-framing dilute
    each other. Rejected: mutation alone (blind to missing tests and wrong levels,
    silent on a module with no tests); a global mutation run (STRATEGY-BRIEF:211,
    cost); coverage-ratchet as the presence gate (the floor is as arbitrary as a
    ceiling and it actively manufactures assertion-free line-touching tests, the
    owner's refutation). Declared limit, load-bearing: neither the audit nor the
    mutant can judge whether the test's EXPECTED VALUE is the RIGHT behavior — a
    test can faithfully encode a wrong requirement, and that stays the human's, on
    the spec. Enforcement: the rite is half-force (mechanical fresh-context reminder
    and reified missing-case findings; the weak-assertion verdict is deferred and
    spec-correctness is steer); read-only is force, asserted in selftest.sh.
    Freeze note (ADR 25): this is a PROCESS rite in the externalized-memory / audit
    family, the same class as /audit (ADR 15) and audit-reminder (ADR 24), which
    the freeze admits; it is not quality-doctrine steer.
36. **2026-08-05 - The test-auditor learns that a guard fails in two directions,
    from a calendar-app session report absorbed as testimony (ADR 23).** Trigger:
    a report from the calendar-app session evaluating a claim this session had made
    (that test-level correctness cannot be forced). Absorbed, not inherited: its
    measurements are testimony, and its narrative anchored partly on the project's
    EXECUTION_PLAN, which the owner confirmed is rotted, abandoned steer with zero
    evidentiary weight — so the "green since March" framing was discounted and only
    the git/code-anchored findings counted. One adoption for this repo: the
    test-auditor's category 1 was "missing negative" (the deny direction only); it
    now requires BOTH directions of a guard, because deny (unauthorized blocked)
    and allow (authorized NOT blocked) fail independently and one test never covers
    the other. The allow direction is the silently-missing one: a locked-out holder
    produces no error, no crash, no log. This was adopted on logic plus an
    independent check, not on the report's authority: a surviving reject-everyone
    mutant IS the missing-allow signal, which is also why it strengthens the Phase 2
    mutation case (C-133). The report's own gate candidates (a per-decorator
    positive-assertion rule, a reachability matrix) are project-specific in form and
    were deferred to calendar-app's queue, not adopted into ts-base (C-134). And it
    corrected this session twice-over: the "you cannot force the right test plan"
    line was drawn too pessimistically — much of that failure was statically
    computable (a decorator demanding a key the template lacks), so the honest
    reformulation is that each "cannot force" layer has a computable half and the
    residue is prioritization under cost, not knowledge of what is right (C-135).
    Freeze note: sharpening an admitted process rite's lens (ADR 35 audit family),
    not a new quality-doctrine steer line. Source: calendar-app session report,
    checked 2026-08-05, measurements unverified from this repo by scoping.
