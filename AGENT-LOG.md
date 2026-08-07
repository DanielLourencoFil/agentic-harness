# AGENT-LOG — where the coding agent helped and where it failed

Public, append-only. Calibrates trust: found-real vs confabulated counts per audit,
and every gate failure with its mechanism.

## 2026-07-09 — Audit: the template could not survive its own consumption rite

Scoped audit (fresh context, neutral framing) reproduced the README consumption path
and found empty-scaffold `verify` red on all three steps (no consumable tsconfig; the
template's own script failing its own lint gate; vitest exit 1 with zero tests), CI
PR-only against the playbook's own rule, no .gitignore (4,688 node_modules files
staged in reproduction). Findings: 5 real, 0 confabulated — every one had a concrete
reproduction. Structural fix: `scripts/selftest.sh` in CI; claims became gates.

## 2026-07-10 — Negative test caught a wired-but-blind rule

While adding `import-x/no-cycle`, the happy-path check passed (config loaded, rule
active in `--print-config`) but a deliberate A↔B cycle produced **zero errors**: by
default the plugin's dependency graph only parses `.js`, so the rule was silently
blind to every TypeScript file. Fix: `import-x/extensions` + `import-x/parsers`
settings; the negative test now shows "Dependency cycle detected".
Lesson, generalized: **a wired rule is not a live rule until it has been seen
rejecting a violation.** This is the rationale for extending the selftest with
negative cases for the gates themselves (planned).

## 2026-07-29 — The CI watch was dead and looked identical to working

The git rite says: watch CI in the background after a push. The watch loop was
written around `jq`, which is not installed on this machine. All 80 iterations
died with `jq: command not found`, the monitor emitted zero events, and the
agent reported to the human that CI was "being watched in the background". It
was silent, not watching. Nothing distinguished that from a run still in
progress; it surfaced only on reading the output file afterwards. CI happened to
be green, which makes the case worse rather than better: the failure cost
nothing this time.

Decision: use `gh --jq` (gojq is embedded in `gh`), do not install `jq`. Checked
that day: no hook in `home/bin/` and no local script depends on it; the only use
is a product's `.github/workflows/ci.yml`, running on GitHub runners that ship it.

Lesson, generalized: **a watcher that cannot read the state must shout, never
continue quietly.** With `jq` installed, the next missing binary reproduces the
failure exactly. Sibling of 2026-07-10 above: a wired rule is not live until seen
rejecting a violation, and a watcher is not alive until seen reporting a failure.
harness-candidate: watch loops cover the error path (`|| echo "cannot read
state"`) and verify their tooling (`command -v`) before arming.

## 2026-07-30 — Audit calibration: 16 findings, 0 confabulated, all four gates blind

The gates written the day before (ADR 27) were audited in fresh context, scoped
to the four files that change, with the neutral prompt. Outcome: 16 correctness
findings, 8 implementation problems, 4 architecture concerns, 3 leads — and after
triage, **0 confabulated**. Every finding became a negative case; the fixes are
ADR 28.

Calibration notes worth keeping:

- **The auditor was right and I was wrong once.** The inline-comment paste finding
  did not reproduce on my first attempt, because I built the fixture with nine
  significant lines instead of eight. One failed reproduction is not a refutation
  — re-read the reported fixture before discarding a finding.
- **The worst finding was a green run, not a crash.** `check_allowlist` passed
  while a planted fifth exemption allowed writes to `/etc/`. Nothing in the output
  looked wrong; the guarantee was simply gone.

Lesson, generalized: **auditing a gate is a different question from auditing
code.** The question is not "is this correct?" but "can this pass while blind?" —
and the answer arrives as a mutation that leaves the suite green. Sibling of
2026-07-10 ("a wired rule is not a live rule until it has been seen rejecting a
violation") and of 2026-07-29 ("a watcher is not alive until seen reporting a
failure"): a gate is not alive until it has been seen rejecting a mutation of the
thing it guards, and the mutation has to be planted on purpose.

Second-order lesson, about the source-shape trap: three of the four gates
inspected the *text* of what they guarded. Text checks are dodged by any refactor
that preserves meaning while changing shape. The fix that held in every case was
to assert **behaviour** — a path that must be denied, a count that must rise — and
to keep the text check only as a cheap extra.

## 2026-08-04 — Two of three gate probes measured obedience, not the gate

Probing whether the harness survives `--permission-mode bypassPermissions`, three
things were asked of a throwaway session. One reached the gate. Two never did.

The one that worked shows a tool call and a hook rejecting it:

    ● Write(~/probe-DELETEME.txt)
      ⎿ PreToolUse:Write hook returned blocking error
      ⎿ Contenção de escrita (ADR 10): ...

The two that failed show no tool call at all, only prose: "não posso correr
`--no-verify`, é uma das operações explicitamente proibidas no rito de git", and
an equivalent refusal for the environment-dumping command. The agent refused on
constitutional grounds and never invoked the tool, so the gate was never
consulted. Insisting twice produced the same refusal.

Both contaminated probes were aimed at rules the constitution names explicitly.
The better the doctrine, the blinder the test: a well-steered agent will not
attempt the violation you need it to attempt.

Only an explicit instruction to attempt the call regardless reached the gate, and
then the mechanism showed itself, denying at the permission layer rather than by
refusal. That is how the ADR 29 measurement finally landed.

Lesson, generalized: **a refusal tells you about the prisoner, not about the
cell.** Sharpening the 2026-07-10 entry — a wired rule is not live until seen
rejecting a violation *that was actually attempted*. When probing a gate, either
instruct the agent to attempt the call, or use a synthetic rule the doctrine has
no opinion about (a planted deny on `echo`), because a probe carrying real danger
will be refused before it is tested.

Corollary for probes with a payload: never test the secret-hygiene gate with real
secrets, since a hook that fails to fire writes the environment into a transcript
that persists on disk.

Second-order, found while writing this entry: `env-dump-guard.py` blocked the
command that was writing these very paragraphs, because the prose *quotes* the
name of a dumping command. It matches command names appearing as data, which is
the false positive `audit-reminder.py` already fixed for `gh pr create` and has a
regression case for. Same bug, unfixed sibling.

## 2026-08-06 — The live-coding subset was designed in conversation, never reified

Prepping a 70-minute live-coding rehearsal, the owner and the agent worked out a
"live-coding subset" of the harness: stamp the config (strict tsconfig, eslint,
vitest, CLAUDE.md) but NOT the blocking machinery (husky pre-commit, CI, stryker,
the budget ratchets), because in 70 minutes those cost setup time and never fire.
It was reasoned carefully and agreed.

It was never written down. So when the rehearsal agent ran the kickoff, it followed
the only documented mode — the full PLAYBOOK stamp — and installed husky, `.github`,
stryker, the budgets, everything: the full cage in the one context where the cage is
the wrong tool. The husky pre-commit fired on commit #1 (reformatting files), proving
the machinery is live where it should not be.

Lesson, sharper than the usual: documented-but-not-wired is a prayer; designed-only-
in-conversation is worse — it does not exist when it is needed. A mode worked out and
agreed in a session, but never committed to a file, is not a mode.

harness-candidate: reify the live-coding subset as a real, selectable mode — a
`/kickoff` variant or a PLAYBOOK layer-selection row that stamps config + skills and
explicitly SKIPS husky/CI/stryker/ratchets, each skip carrying the one-line
justification the PLAYBOOK already asks for. Trigger fired: the 2026-08-06 rehearsal
did the full stamp for want of it.

## 2026-08-07 — The kickoff rite never asks anything about UI design

Driving the exercise-2 dashboard (Next + Tailwind), a fresh session reached the UI slice
and found the harness had elicited nothing about how the UI should look or behave. The
rites force UI VALIDITY (jsx-a11y alt-text, the stranded-logic budget, the server/client
boundary) but the spec interview and the feature loop ask only correctness/behaviour
questions — problem, scope, invariants, abuse. Not one asks about layout, interaction
states, error-vs-blocked feedback, loading/pending, or aria-live announcements. For a
front-end role (Next + Tailwind, UI/UX in the JD), a rite that never asks anything about
UI is a gap with consequences: the design decisions get defaulted, not made.

The distinction that bounds the fix: the harness deliberately does not FORCE UI quality
(semantic, closed by review — the PLAYBOOK scope note). What is missing is ELICITATION —
surfacing the UI decisions so the human makes them. That is process-rite, admissible, and
it is the UI-content of the design-decision pass ADR 52 just built: the pass exists, the
UI cues do not.

harness-candidate: add UI-decision cues to the ADR 52 design-decision pass (layout,
outcome feedback, blocked-vs-error, pending/double-click coupling to idempotency,
aria-live). The exact set is extracted from which questions the dashboard slice shows were
load-bearing (ADR 18), not guessed now; and it stays elicitation, never a UI-quality gate
(that would be ADR 25 frozen quality-doctrine, C-148's neighbourhood).

