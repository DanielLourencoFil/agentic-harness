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
