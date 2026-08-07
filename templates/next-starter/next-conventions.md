## Next.js conventions (this project)

- **Server Components by default; `"use client"` only for state, effects or browser
  APIs.** A component that does not need the client stays a Server Component.
- **The pure core is `src/lib` and imports no framework** (enforced by lint). Business
  logic lives there, tested without a renderer or a request; components render it, route
  handlers (`src/app/**/route.ts`) serve it. One pure core, two consumers.
- **`next/image` over `<img>`** (Next's `no-img-element` is a failure here via
  `--max-warnings 0`); `next/link` over `<a>` for internal navigation.
- **Data at the boundary, not in components**: fetch and mutate in Server Components or
  route handlers behind a typed, fakeable seam (e.g. a repository interface), so the
  logic stays unit-testable. Validate external input with Zod at the trust boundary.
- **Async Server Components are integration-tested, not unit-tested**: keep the
  unit-tested logic pure in `src/lib`, which the node-env Vitest suite covers without a
  browser.
- **Component tests opt into jsdom per file** with `// @vitest-environment jsdom` at the top
  (the suite is node-env by default); render with `@testing-library/react`. Components ARE
  mutation-tested (`src/components` is in the Stryker scope, ADR 60), so a component test that
  only checks "it renders" leaves the mutant that swaps its behaviour alive: assert the
  behaviour, not the presence.
