// Mutation testing: the wired half of "every test must fail if the logic breaks"
// (constitution), which is prayer until a tool proves it. Stryker mutates the
// code and asks whether any test notices; a surviving mutant is a test that
// cannot fail on that change, i.e. a decorative test.
//
// OPT-IN and ON-DEMAND, not part of `verify`. It reruns the test suite once per
// mutant, so it is minutes where `verify` is seconds; making it a pre-commit or
// per-PR gate would tax every commit for a check that belongs on a schedule or a
// deliberate `pnpm mutants` run. The standing gate (every-PR) is deferred until a
// real project's cost data justifies the CI minutes (agentic-harness ADR 38).
//
// ALLOWLISTED to src/lib, the pure core, on purpose. Global mutation was rejected
// on cost (STRATEGY-BRIEF): mutating UI and e2e-tested code reruns a browser or a
// DB per mutant, which is the expensive case for the least reward. The pure core
// is where the load-bearing logic should live and where a fast unit suite makes
// mutation cheap — measured ~2s on a one-function scaffold.
//
// Widen `mutate` deliberately when a module outside src/lib earns it, in the same
// commit where you can say why. The break threshold is 100: on the pure core, a
// surviving mutant is a real gap, not noise to budget around.
export default {
  testRunner: "vitest",
  // Explicit under pnpm: Stryker's child process cannot auto-discover a plugin
  // in the symlinked store, so the runner must be named or it fails with
  // "Cannot find TestRunner plugin" (measured 2026-08-05).
  plugins: ["@stryker-mutator/vitest-runner"],
  mutate: ["src/lib/**/*.ts", "!src/lib/**/*.test.ts", "!src/lib/**/*.d.ts"],
  reporters: ["clear-text", "html"],
  coverageAnalysis: "perTest",
  thresholds: { high: 100, low: 100, break: 100 },
  // A run with nothing to mutate is a green run, not an error: the empty scaffold
  // and any project whose src/lib is still empty must not fail `pnpm mutants`.
  allowEmpty: true,
};
