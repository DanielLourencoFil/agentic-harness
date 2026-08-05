## Project specifics — React

Only what the linter cannot catch. Everything mechanical is already an error in
`eslint.config.mjs`.

### Effects

- **Derived state is computed during render, never in an effect.** If a value can
  be calculated from props or state, calculate it. An effect that sets state from
  other state renders twice, can loop, and is the single most common defect in
  AI-written React ("You Might Not Need an Effect").
- **Effects are for synchronising with something outside React**: a subscription, a
  browser API, a non-React widget. Not for reacting to a prop change.
- **Event logic belongs in the handler**, not in an effect watching the state the
  handler set. The user clicked; you know it there.
- Expensive derivations get `useMemo` only when measured, never by reflex.
- Every remaining effect carries a one-line comment naming the external system it
  syncs with. If the line cannot be written, it is derived state in disguise.

### Server state

- Data from the network is **not** component state. It is cache, and it belongs in
  a query library (TanStack Query, or the framework's own loader), which owns
  staleness, retries and deduplication.
- `useEffect` + `fetch` + `setState` is forbidden: it re-fetches on every mount,
  races on fast navigation, and has no cancellation. Three defects, one line.

### Components

- Keys are **stable identity from the data**, never the array index. An index key
  makes React reuse the wrong DOM node the moment the list reorders or filters.
- State lives as close to its use as possible; lift only when genuinely shared.
- Business rules live in `src/lib` as plain functions, framework-free. Components
  render, hooks wire, `lib` decides. The lint config forbids `src/lib` from
  importing React, so this stays true rather than aspirational.

### Next.js (App Router), when the project uses it

- **Components are Server Components by default.** `"use client"` is a boundary in
  the tree, not a decoration on a file. Everything below it ships to the browser.
- **Push the boundary down, never up.** A page marked `"use client"` because one
  button needs `onClick` sends the entire subtree to the client. Extract the
  interactive leaf and mark that.
- **Fetch on the server and pass data down.** A client component fetching in an
  effect what the server already had is a waterfall the framework existed to
  remove.
- `"use client"` does **not** mean "browser only": those components still render on
  the server for the first paint. Code that touches `window` at module scope breaks
  the build, not just the browser.
- `async` components are a server feature. A client component cannot be `async`.
- Route handlers and server actions are **trust boundaries**: validate input there
  with a schema, exactly as an API endpoint would. Being colocated with the UI does
  not make the caller trustworthy.

### Testing

- Test behaviour through the rendered result, not implementation details: query by
  role and by accessible name, never by class name or component internals.
- The pure core in `src/lib` is tested directly, without a renderer, and that is
  where the load-bearing logic should be so the fast tests cover the risk.
