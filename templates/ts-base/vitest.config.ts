import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    include: ["tests/**/*.test.ts", "src/**/*.test.ts"],
    // The empty scaffold must verify green (vitest exits 1 on zero test files).
    // Inert as soon as the first real test lands (the feature routine ships tests
    // with every commit); remove it if you prefer "no tests = red" afterwards.
    passWithNoTests: true,
    // Coverage as a DIAGNOSTIC only — no % threshold (a target breeds trivial tests).
    coverage: { provider: "v8", reporter: ["text", "json-summary"] },
  },
});
