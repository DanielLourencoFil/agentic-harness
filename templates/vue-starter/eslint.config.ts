import { globalIgnores } from "eslint/config";
import { defineConfigWithVueTs, vueTsConfigs } from "@vue/eslint-config-typescript";
import { createTypeScriptImportResolver } from "eslint-import-resolver-typescript";
import importX from "eslint-plugin-import-x";
import pluginVue from "eslint-plugin-vue";
import pluginVueA11y from "eslint-plugin-vuejs-accessibility";
import pluginVitest from "@vitest/eslint-plugin";

// Force layer: objective, local constraints the AI cannot argue its way past.
// (Semantic design — SOLID, correctness — is NOT enforced here; that is review.)
export default defineConfigWithVueTs(
  {
    name: "app/files-to-lint",
    files: ["**/*.{vue,ts,mts,tsx}"],
  },

  globalIgnores(["**/dist/**", "**/dist-ssr/**", "**/coverage/**"]),

  ...pluginVue.configs["flat/strongly-recommended"],
  ...pluginVueA11y.configs["flat/recommended"],
  vueTsConfigs.strictTypeChecked,

  {
    name: "app/harness-rules",
    rules: {
      "@typescript-eslint/no-explicit-any": "error",
      "@typescript-eslint/no-floating-promises": "error",
      "@typescript-eslint/ban-ts-comment": "error",
      // No coerced equality: `==` declares different things equal (docs/RATIONALE.md).
      eqeqeq: ["error", "always"],
      // No ignored cases: a switch over a union must handle every member.
      "@typescript-eslint/switch-exhaustiveness-check": "error",
      complexity: ["error", 10],
      "max-lines-per-function": ["error", 60],
      "max-lines": ["error", 300],
      "no-console": "error",
      // Playbook Layer 2 (Vue): danger rules pinned to error even if the preset relaxes them.
      "vue/no-mutating-props": "error",
      "vue/require-v-for-key": "error",
      "vue/no-use-v-if-with-v-for": "error",
      "vue/no-side-effects-in-computed-properties": "error",
      "vue/require-explicit-emits": "error",
      "vue/no-v-html": "error",
      "vue/multi-word-component-names": "error",
    },
  },

  {
    // No circular imports among TS modules (cycles through .vue files are outside
    // this graph — the pure-core ban below keeps src/lib clear of that blind spot).
    name: "app/no-cycles",
    plugins: { "import-x": importX },
    settings: {
      "import-x/resolver-next": [createTypeScriptImportResolver()],
      // Without these the dependency graph only parses .js — the rule goes silently
      // blind to .ts files (verified by negative test; see agentic-harness AGENT-LOG).
      "import-x/extensions": [".ts", ".tsx", ".js", ".mjs"],
      "import-x/parsers": { "@typescript-eslint/parser": [".ts", ".tsx"] },
    },
    rules: { "import-x/no-cycle": ["error", { maxDepth: 8 }] },
  },

  {
    // The pure core: metrics/domain logic in plain TS — Vue only renders.
    // Framework-free means testable without mocks.
    name: "app/pure-core",
    files: ["src/lib/**/*.ts"],
    rules: {
      "no-restricted-imports": [
        "error",
        {
          paths: [
            { name: "vue", message: "src/lib is the pure core — no framework imports." },
            { name: "pinia", message: "src/lib is the pure core — no store imports." },
          ],
          patterns: [
            {
              group: ["*.vue", "@/components/*", "@/stores/*"],
              message: "src/lib is the pure core — no UI/store imports.",
            },
          ],
        },
      ],
    },
  },

  {
    // Node CLI scripts: console IS their interface — `no-console` targets app code.
    name: "app/cli-scripts",
    files: ["scripts/**/*.{js,mjs,cjs}"],
    rules: { "no-console": "off" },
  },

  {
    ...pluginVitest.configs.recommended,
    files: ["src/**/*.test.ts", "tests/**/*.test.ts"],
  },
  {
    // Test files legitimately exceed function-length limits (describe blocks).
    name: "app/test-overrides",
    files: ["src/**/*.test.ts", "tests/**/*.test.ts"],
    rules: {
      "max-lines-per-function": "off",
    },
  },
);
