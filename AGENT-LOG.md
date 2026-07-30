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
