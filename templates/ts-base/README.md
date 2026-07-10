# TypeScript harness (ts-base)

The fixed, **mandatory** quality cage for any TypeScript project. **Author once, clone forever** —
you never rebuild this. A new TS project = copy this folder, merge the package.json snippet
below, `pnpm install`. Framework modules (Vue/React/Nest) layer **on top** (see
`~/Dev/agentic-harness/PLAYBOOK.md`).

## What it forces (tooling rejects bad output — not prompts)

- **tsconfig strict** (+ no implicit any, no unchecked index access). Ships a consumable
  `tsconfig.json` extending `tsconfig.base.json`.
- **ESLint** with `no-explicit-any` / `no-floating-promises` / `ban-ts-comment` / `complexity` /
  `max-lines(-per-function)` as **errors**, **zero warnings**. Node CLI scripts (`scripts/**`)
  get Node globals and may use `console` — it's their interface.
- **Prettier** via lint-staged.
- **Husky pre-commit**: deletion guard → lint-staged → `verify` (typecheck + lint + test).
- **GitHub Actions**: `verify` on **every push and every PR** (never PR-only), with
  `concurrency: cancel-in-progress`, a job timeout, dependabot skip — plus a weekly
  `pnpm audit --prod --audit-level=high` workflow.
- **Vendor-neutral conventions**: `AGENTS.md` is canonical ([agents.md](https://agents.md/)
  standard); `CLAUDE.md`/`GEMINI.md` are one-line adapters (never edit them);
  `.claude/settings.json` ships the agent-permission baseline (deny `.env` reads,
  `--no-verify`, force-push, pushing to main).

## How to consume

1. **`git init` first** (or clone your empty repo). Husky's `prepare` needs `.git` and fails
   **silently** otherwise (prints ".git can't be found" but exits 0 — hooks never install).
2. Copy every file here into the new project root (including dotfiles: `.husky/`, `.github/`,
   `.claude/`, `.gitignore`, `tsconfig.json`; drop this README and `package.snippet.json`
   after merging). Fill the "Project specifics" section of `AGENTS.md` at kickoff.
3. Merge `package.snippet.json` into your `package.json` (canonical copy — the selftest
   consumes it, so it cannot drift):

```json
{
  "type": "module",
  "scripts": {
    "typecheck": "tsc --noEmit",
    "lint": "eslint .",
    "test": "vitest run",
    "verify": "pnpm typecheck && pnpm lint && pnpm test",
    "prepare": "husky"
  },
  "lint-staged": { "*.{ts,tsx,json,md,css}": "prettier --write" },
  "devDependencies": {
    "@eslint/js": "^9", "typescript-eslint": "^8", "eslint": "^9", "globals": "^16",
    "eslint-plugin-import-x": "^4", "eslint-import-resolver-typescript": "^4",
    "prettier": "^3", "vitest": "^4", "@vitest/coverage-v8": "^4",
    "husky": "^9", "lint-staged": "^17", "typescript": "^5"
  }
}
```

4. `pnpm install` (pin the versions it resolves), then `chmod +x .husky/pre-commit`.
5. `pnpm verify` must be green on the empty project before writing any feature code.
   (This holds by construction: `tsconfig.json` always has ≥1 input, scripts lint clean,
   and vitest has `passWithNoTests` — inert once your first real test lands.)
6. Commit #1 = "chore: scaffold + guardrails" — **include `pnpm-lock.yaml`** (CI installs
   with `--frozen-lockfile` and fails without it).

## Evolution

These claims are **enforced, not stated**: `scripts/selftest.sh` (run by this repo's CI on
every push) consumes the template exactly as above and fails if the empty-scaffold verify,
the commit #1 hook, or the deletion guard ever regress. Consuming projects still feed
fixes back here. Next extraction: `vue-starter` = this + the Vue framework module (see
`PLAYBOOK.md`, Layer 2). Later: publish starters as GitHub template repos (`degit`).
