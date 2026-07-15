# Global engineering rules (all projects, all sessions)

Values: correctness > trust > performance > dev speed. Never ship what the human doesn't
understand. Docs and code comments in **English**; conversation with Daniel in Portuguese.

## Playbook

The full engineering system lives in `~/Dev/agentic-harness/PLAYBOOK.md`.
**At any new project kickoff, read it and assemble the harness (layers + kickoff checklist)
before writing feature code.** Templates: `~/Dev/agentic-harness/templates/`.

## Session scoping

One project, one session, one cwd: engineering work on a project happens in a session
opened in that project's folder (right conventions, scoped permissions, dedicated
memory). Sessions in `~/Dev` are the cross-project desk (career, backlog, kickoffs)
only. If the session cwd is `~/Dev` but the task turns into single-project engineering,
say so and suggest reopening in the project folder before deep work starts.

## Secret hygiene

A secret seen in context is burned: stop the task, say so, require rotation before any
other work continues, and never repeat the value in any output. Secrets flow
shell→destination via command substitution (never through editor, clipboard, prompt,
or command output). Two accident-net hooks enforce the cheap half (prompt scan +
env-dump guard in `agentic-harness/home/bin/`); the IDE-selection channel has no gate, so the
flow rule is the only protection there.

## Backlog rite

`~/Dev/BACKLOG.md` is the single source of truth for cross-project pending work (a
SessionStart hook injects it). Any "do later" born in a session lands there before the
session ends; agent memory only points at it. When closing an item, mark it done there.

## Git rite (automatic — never ask)

- Commit atomically (gated by `verify`) and push work branches **without asking**.
  After any push, watch the CI run in the background; on failure, read the failed log
  (`gh run view --log-failed`) and fix — don't wait for the human to report it.
- Never: merge to the default branch (human's act), force-push, `--no-verify`, `[skip ci]`.
- In repos where the default branch auto-deploys and has no branch protection, pushing to
  it still requires confirmation.

## Enforcement over prompts

- Every commit passes `verify` (typecheck + lint + test). TS strict, no `any`,
  no `@ts-ignore`, zero warnings.
- If a rule can be a tool/test/hook, wire it; only what can't be reified goes into
  convention docs. Documented-but-unwired governance is a prayer, not a gate.

## Testing & audits

- Isolate non-determinism behind a fakeable seam; keep load-bearing logic pure and test it
  hard. Every test must fail if the logic breaks; no coverage % targets.
- The human owns the scenario checklist; negative tests before production code.
- Audits: fresh context, scoped, neutral framing (allow "none found"); every finding needs
  a concrete reproduction; a finding that won't become a red test isn't a bug.

## Avoid

Persona/tone theater · claiming tooling "forces SOLID" · coverage targets · warning budgets
in fresh projects · a Skill per principle · auto-merging unreviewed code. 100% of the work
automated, 100% of the decision human.
