import nextPlugin from "@next/eslint-plugin-next";

import base from "./eslint.config.mjs";

// Layer 2 overlay for Next.js (App Router), on top of the React config.
// Consume this file as `eslint.config.mjs` in a Next project, keeping the React
// one beside it as `eslint.config.react.mjs`, or merge the block below by hand.
//
// Every rule is pinned to error on purpose. Next ships most of core-web-vitals at
// `warn`, and the harness has no warning level: a rule nobody has to obey is a
// rule nobody obeys (zero-warnings, ts-base README). If one of these is wrong for
// a project, turn it OFF deliberately with a comment, which is a decision someone
// made rather than a line everybody scrolls past.
const asErrors = Object.fromEntries(
  Object.keys(nextPlugin.configs["core-web-vitals"].rules).map((rule) => [rule, "error"]),
);

export default [
  ...base,
  {
    name: "harness/next",
    plugins: { "@next/next": nextPlugin },
    rules: {
      ...asErrors,
      // The RSC boundary rule worth naming: a client component cannot be async.
      // It is the one server/client mistake a linter can catch, and the rest of
      // that boundary lives in react-conventions.md because only the Next build
      // can see it.
      "@next/next/no-async-client-component": "error",
    },
  },
  {
    // `window`/`document` are legitimate inside client components.
    name: "harness/next-globals",
    languageOptions: { globals: { window: "readonly", document: "readonly" } },
  },
];
