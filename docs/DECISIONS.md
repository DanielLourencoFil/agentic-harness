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
