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
