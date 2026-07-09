import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    include: ["tests/**/*.test.ts", "src/**/*.test.ts"],
    // Coverage as a DIAGNOSTIC only — no % threshold (a target breeds trivial tests).
    coverage: { provider: "v8", reporter: ["text", "json-summary"] },
  },
});
