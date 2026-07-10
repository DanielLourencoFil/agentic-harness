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
