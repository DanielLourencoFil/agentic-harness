# Vue harness (vue-starter)

Layer 2 (Vue 3) on top of `ts-base` — extracted from the first real consumption
(OrgLab kickoff, 2026-07-09). **This template is an overlay, not a scaffold**: the
official `create-vue` generates the app; these files harden it to the harness gate.
Everything here is exercised by `scripts/selftest-vue.sh` in this repo's CI.

## What it changes vs. a stock create-vue app

- **oxlint removed** — a second linter running `--fix` inside the gate is a gate that
  mutates code; the gate must be one tool that reads and judges.
- ESLint raised to `flat/strongly-recommended` + `vueTsConfigs.strictTypeChecked`,
  playbook danger rules pinned as **errors** (`no-mutating-props`, `no-v-html`,
  `require-explicit-emits`, …), a11y plugin, and the ts-base validity rules
  (`eqeqeq`, `switch-exhaustiveness-check`, `import-x/no-cycle`).
- **Pure-core import ban**: `src/lib/**` cannot import `vue`, `pinia`, components or
  stores — compute in lib, wire in stores/composables, render in components.
- Vitest: harness test convention (`*.test.ts` in `src/` and `tests/`),
  `passWithNoTests`, coverage as diagnostic.
- Plus everything ts-base brings (hook, deletion guard, CI, adapters, settings).

## How to consume

1. **`git init` first** (hooks need `.git`; husky fails silently without it).
2. Scaffold: `pnpm create vue@latest <app> -- --ts --pinia --vitest --eslint`
   (router only if the app needs routes). Move the generated files into the repo root.
3. Strip the demo (`src/components`, `src/stores`, demo assets) and `.oxlintrc.json`;
   write a minimal `App.vue` + `main.ts`. Commit #1 is guardrails, features second.
4. Copy the **shared files from `../ts-base/`**: `.husky/`, `scripts/deletion-guard.mjs`,
   `.prettierrc.json`, `.github/workflows/`, `.gitignore` (append `dist-ssr/`),
   `AGENTS.md` + `CLAUDE.md` + `GEMINI.md` adapters, `.claude/settings.json`.
5. Copy the **overrides from this folder**: `eslint.config.ts`, `vitest.config.ts`,
   `tsconfig.app.json`, `tsconfig.vitest.json`.
6. Append `vue-conventions.md` to the copied `AGENTS.md` (Project specifics section).
7. Merge `package.snippet.json` into the generated `package.json` — it replaces the
   lint/test scripts (dropping oxlint), adds `verify`/`prepare`/lint-staged, and adds
   the harness devDependencies. Remove `oxlint` and `eslint-plugin-oxlint` from
   devDependencies.
8. `pnpm install`, `chmod +x .husky/pre-commit`, then `pnpm verify` — **must be green
   on the stripped scaffold** before any feature code. Commit #1 includes the lockfile.

`scripts/selftest-vue.sh` executes exactly these steps in CI and additionally proves
the gate **rejects**: `any`, `==`, a non-exhaustive `switch`, an import cycle, and
`v-html` in a component.

## Honest limits

- `import-x/no-cycle` walks `.ts`/`.tsx` modules; cycles that pass *through `.vue`
  files* are not in its graph. The pure-core ban keeps `src/lib` out of that blind
  spot — which is where cycles would hurt most.
- The gate cannot see the Vue-specific semantic anti-pattern that matters most
  (deriving state in a `watch` instead of `computed`); that stays a convention with
  a mandatory one-line justification per `watch` — see `vue-conventions.md`.
