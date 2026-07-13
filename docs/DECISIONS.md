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
