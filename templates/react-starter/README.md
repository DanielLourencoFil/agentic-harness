# React harness (react-starter)

Layer 2 (React 19) on top of `ts-base`. **This template is an overlay, not a
scaffold**: the official `create-vite` generates the app, these files harden it to
the harness gate. Everything here is exercised by `scripts/selftest-react.sh` in
this repo's CI.

## What it changes vs. a stock create-vite react-ts app

- ESLint raised to `strictTypeChecked` with the ts-base validity rules pinned as
  errors (`no-explicit-any`, `eqeqeq`, `switch-exhaustiveness-check`,
  `import-x/no-cycle`, complexity/depth/size caps).
- **`react-hooks/exhaustive-deps` is an error, not a warning.** The plugin ships it
  as a warning; a lying dependency array is the most common way AI-written React
  goes subtly wrong, and the bug only reproduces on the second render.
- **Pure-core import ban**: `src/lib/**` cannot import `react` or components.
  Compute in lib, wire in hooks, render in components. Framework-free means
  testable without a renderer.
- tsconfig from `ts-base` (strict, `noUncheckedIndexedAccess`,
  `verbatimModuleSyntax`) plus the DOM/JSX bits, with `@/*` mapped to `./src/*`.
- Vitest: harness convention (`*.test.ts(x)` in `src/` and `tests/`),
  `passWithNoTests`, coverage as diagnostic.
- Plus everything ts-base brings: pre-commit hook, deletion guard, copy-paste
  budget, CI, adapters, `.claude/settings.json`.

## How to consume

1. **`git init` first** (hooks need `.git`; husky fails silently without it).
2. Scaffold: `pnpm create vite@latest <app> --template react-ts`. Move the
   generated files into the repo root.
3. Strip the demo (`src/assets`, `public/`, `src/App.css`); write a minimal
   `src/App.tsx` and `src/main.tsx`. Commit #1 is guardrails, features second.
   Note the entry point: `document.getElementById("root")!` is rejected by
   `no-non-null-assertion`, so narrow it with a real check.
4. Copy the **shared files from `../ts-base/`**: `.husky/`, `scripts/` (deletion
   guard + `clone-budget-check.mjs` + `clone-detect.mjs`), `.clonebudget.json`,
   `.prettierrc.json`, `.github/workflows/`, `.gitignore` (append to the generated
   one), `AGENTS.md` + `CLAUDE.md` + `GEMINI.md` adapters, `.claude/settings.json`.
5. Copy the **overrides from this folder**: `eslint.config.mjs`, `vitest.config.ts`,
   `tsconfig.json`, `tsconfig.app.json`, `tsconfig.base.json`. Delete the generated
   `tsconfig.node.json`.
6. Append `react-conventions.md` to the copied `AGENTS.md` (Project specifics).
7. Merge `package.snippet.json` into the generated `package.json`.
8. `pnpm install`, `chmod +x .husky/pre-commit`, then `pnpm verify` — **must be
   green on the stripped scaffold** before any feature code. Commit #1 includes the
   lockfile.

`scripts/selftest-react.sh` executes exactly these steps in CI and additionally
proves the gate **rejects**: `any`, `==`, a non-exhaustive `switch`, an import
cycle, nesting past depth 3, a hook called conditionally, a lying dependency array,
React imported inside the pure core, and a duplicated block.

## Next.js (App Router)

Next brings its own scaffold and its own linting, so the overlay is one extra file
rather than a separate template.

1. Scaffold with `pnpm create next-app@latest <app> --ts --eslint --app`.
2. Follow steps 4 to 8 above, with two changes: keep Next's `tsconfig.json`
   (it needs the `next` plugin and `moduleResolution: bundler`), and use
   `eslint.next.mjs` from this folder as your `eslint.config.mjs`.
3. Add `@next/eslint-plugin-next` to devDependencies.

`eslint.next.mjs` layers Next's `core-web-vitals` set on top of the React config
**with every rule pinned to error**. Next ships most of them as warnings and the
harness has no warning level: a rule nobody has to obey is a rule nobody obeys. If
one is wrong for a project, turn it off deliberately with a comment.

The rule worth knowing by name is `@next/next/no-async-client-component`: it is the
one server/client boundary mistake a linter can catch. The rest of that boundary
lives in `react-conventions.md`, because only the Next build can see it.

**Honest limit:** the Next path is not covered by a selftest job. The React/Vite
path is consumed end to end in CI on every push; the Next overlay is verified only
as far as the plugin's config shape, checked on 2026-08-05. Treat the Vite path as
proven and the Next path as documented.
