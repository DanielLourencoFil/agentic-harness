# TypeScript harness (ts-base)

The fixed, **mandatory** quality cage for any TypeScript project. **Author once, clone forever** —
you never rebuild this. A new TS project = copy this folder, merge the package.json snippet
below, `pnpm install`. Framework modules (Vue/React/Nest) layer **on top** (see
`~/Dev/agentic-harness/PLAYBOOK.md`).

## What it forces (tooling rejects bad output — not prompts)

- **tsconfig strict** (+ no implicit any, no unchecked index access).
- **ESLint** with `no-explicit-any` / `no-floating-promises` / `ban-ts-comment` / `complexity` /
  `max-lines(-per-function)` as **errors**, **zero warnings**.
- **Prettier** via lint-staged.
- **Husky pre-commit**: deletion guard → lint-staged → `verify` (typecheck + lint + test).
- **GitHub Actions**: re-runs `verify` (local hooks can be bypassed; CI cannot).

## How to consume

1. Copy every file here into the new project root (including `.husky/`, `.github/`, `scripts/`).
2. Merge this into `package.json`:

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
    "@eslint/js": "^9", "typescript-eslint": "^8", "eslint": "^9",
    "prettier": "^3", "vitest": "^3", "@vitest/coverage-v8": "^3",
    "husky": "^9", "lint-staged": "^16", "typescript": "^5"
  }
}
```

3. `pnpm install` (pin the versions it resolves), then `chmod +x .husky/pre-commit`.
4. `pnpm verify` must be green on an empty project before writing any feature code.

## Status

**Baseline — not yet validated in a real run.** It gets proven the first time a project
consumes it (OrgLab, Fase 0). After that it's the trusted `ts-starter`; `vue-starter` =
this + the Vue module. Later, push as a GitHub template and `degit` it.
