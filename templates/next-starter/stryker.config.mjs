// Mutation testing for the Next path: the wired half of "every test must fail if the logic
// breaks", widened past ts-base's src/lib-only scope to src/components (ADR 60). The ex-3 audit
// MEASURED 16 mutants surviving in unit-tested components that Stryker's src/lib scope never
// reached, refuting ADR 38's "UI is the least reward"; a spike showed Stryker mutates a .tsx
// component through the vitest + jsdom runner in seconds, so the cost premise did not hold for
// unit-tested UI either.
//
// src/app stays OUT: Server Components and pages are integration/e2e territory, the expensive
// case ADR 38 correctly named. Component TESTS opt into jsdom per file with
// `// @vitest-environment jsdom` (see next-conventions.md). A component with no unit test shows
// as "no coverage", which is itself the signal to write one. Break at 100 on a fresh scaffold;
// in brownfield, raise the budget or ratchet as ADR 38 does for the pure core.
export default {
  testRunner: "vitest",
  plugins: ["@stryker-mutator/vitest-runner"],
  mutate: [
    "src/lib/**/*.ts",
    "src/components/**/*.{ts,tsx}",
    "!src/**/*.test.{ts,tsx}",
    "!src/**/*.d.ts",
  ],
  reporters: ["clear-text", "html"],
  coverageAnalysis: "perTest",
  thresholds: { high: 100, low: 100, break: 100 },
  allowEmpty: true,
};
