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

