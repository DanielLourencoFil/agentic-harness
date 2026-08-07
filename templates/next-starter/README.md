# Next.js harness (next-starter)

Layer 2 (Next.js 16, App Router) on top of `ts-base`. **This template is an overlay,
not a scaffold**: the official `create-next-app` generates the app, these files harden
it to the harness gate. Everything here is exercised by `scripts/selftest-next.sh` in
this repo's CI.

## What it changes vs. a stock create-next-app app

- ESLint composed ON TOP of `eslint-config-next`: `strictTypeChecked` + the ts-base
  validity rules pinned as errors (`no-explicit-any`, `eqeqeq`,
  `switch-exhaustiveness-check`, `import-x/no-cycle`, complexity/depth/size caps), plus
  `--max-warnings 0` so Next's core-web-vitals warnings become failures (the harness has
  no warning level; a rule nobody has to obey is a rule nobody obeys).
- **`react-hooks/exhaustive-deps` pinned to error** (the plugin ships it as a warning):
  a lying dependency array is the most common way AI-written React goes subtly wrong,
  and the bug only reproduces on the second render.
- **`jsx-a11y/alt-text` pinned to error** — parity with the React and Vue paths.
- **Pure-core import ban**: `src/lib/**` cannot import `react`, `react-dom` or `next`.
  Compute in `lib`, wire in hooks/route handlers, render in components. Framework-free
  means testable without a renderer or a request.
- tsconfig extends Next's own with the ts-base strictness
  (`noUncheckedIndexedAccess`, `noImplicitOverride`, `verbatimModuleSyntax`,
  `noFallthroughCasesInSwitch`), keeping the `next` plugin, the `.next/types` includes
  and `jsx: react-jsx`. **`typecheck` runs `next typegen` before `tsc --noEmit`**: real Next
  code uses generated types (`LayoutProps`/`PageProps`) that a fresh clone or CI lacks until
  typegen writes them to `.next/types`, so a bare `tsc` would fail there.
- Vitest via `vitest.config.mts` (`.mts` so the ESM config loads clean without
  `"type": "module"`, which Next does not set); node env, `passWithNoTests`, coverage as
  diagnostic; tests target the pure core.
- Plus everything ts-base brings: pre-commit hook, deletion guard, copy-paste + stranded
  budgets, CI, adapters, `.claude/settings.json`.

## How to consume

1. **`git init` first** (hooks need `.git`; husky fails silently without it).
2. Scaffold at the repo root:
   `pnpm create next-app@latest . --ts --tailwind --app --eslint --src-dir --import-alias "@/*" --use-pnpm`
3. Strip the demo: write a minimal `src/app/page.tsx` and `src/app/layout.tsx`;
   `mkdir -p src/lib tests`. Commit #1 is guardrails, features second.
4. Copy the **shared files from `../ts-base/`**: `.husky/`, `scripts/` (deletion guard +
   `clone-budget-check.mjs` + `clone-detect.mjs` + `stranded-logic-check.mjs`),
   `.clonebudget.json`, `.strandedbudget.json`, `.prettierrc.json`, `.github/workflows/`,
   `AGENTS.md` + `CLAUDE.md` + `GEMINI.md` adapters, `.claude/`, and append its
   `.gitignore` to the generated one. `chmod +x .husky/pre-commit`.
5. Copy the **overrides from this folder**: `eslint.config.mjs`, `tsconfig.json`,
   `vitest.config.mts` (they overwrite the create-next-app versions). Append
   `next-conventions.md` to `AGENTS.md`.
6. Merge `package.snippet.json` into `package.json` (scripts, lint-staged,
   devDependencies).
7. `pnpm install`, then `pnpm verify` — green on the stripped scaffold before any
   feature code.

Verified end-to-end by `scripts/selftest-next.sh`: it runs exactly these steps, asserts
`pnpm verify` is green, then plants violations (validity, hooks, a11y, pure-core, a clone,
stranded `.tsx` logic) and asserts the gate rejects each.
