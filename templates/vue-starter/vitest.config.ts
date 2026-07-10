import { fileURLToPath } from "node:url";
import { mergeConfig, defineConfig, configDefaults } from "vitest/config";
import viteConfig from "./vite.config";

export default mergeConfig(
  viteConfig,
  defineConfig({
    test: {
      environment: "jsdom",
      include: ["tests/**/*.test.ts", "src/**/*.test.ts"],
      exclude: [...configDefaults.exclude, "e2e/**"],
      root: fileURLToPath(new URL("./", import.meta.url)),
      // The empty scaffold must verify green (vitest exits 1 on zero test files).
      // Inert as soon as the first real test lands; the feature routine ships
      // tests with every commit.
      passWithNoTests: true,
      // Coverage as a DIAGNOSTIC only — no % threshold (a target breeds trivial tests).
      coverage: { provider: "v8", reporter: ["text", "json-summary"] },
    },
  }),
);
