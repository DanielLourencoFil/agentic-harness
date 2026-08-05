import js from "@eslint/js";
import { createTypeScriptImportResolver } from "eslint-import-resolver-typescript";
import importX from "eslint-plugin-import-x";
import reactHooks from "eslint-plugin-react-hooks";
import globals from "globals";
import tseslint from "typescript-eslint";

// Force layer: objective, local constraints the AI cannot argue its way past.
// (Semantic design — SOLID, correctness — is NOT enforced here; that is review.)
export default tseslint.config(
  { ignores: ["dist/", "coverage/", "node_modules/", "**/*.config.*"] },

  js.configs.recommended,
  ...tseslint.configs.strictTypeChecked,

  {
    languageOptions: {
      parserOptions: { projectService: true },
      globals: globals.browser,
    },
    rules: {
      // Layer 1 (ts-base): identical set, so a React project is held to the same
      // validity bar as any other TypeScript project in the harness.
      "@typescript-eslint/no-explicit-any": "error",
      "@typescript-eslint/no-floating-promises": "error",
      "@typescript-eslint/ban-ts-comment": "error",
      // No coerced equality: `==` declares different things equal (docs/RATIONALE.md).
      eqeqeq: ["error", "always"],
      // No ignored cases: a switch over a union must handle every member.
      "@typescript-eslint/switch-exhaustiveness-check": "error",
      complexity: ["error", 10],
      // Shallow nesting: guard clauses over pyramids. Depth taxes both readers,
      // the human refuter and the agent's context (agentic-harness ADR 7).
      "max-depth": ["error", 3],
      "max-lines-per-function": ["error", 60],
      "max-lines": ["error", 300],
      "no-console": "error",
    },
  },

  {
    // Layer 2 (React). `exhaustive-deps` is a warning in the plugin's own preset;
    // the playbook pins it to error, because a lying dependency array is the most
    // common way AI-written React goes subtly wrong: the effect keeps a stale
    // closure and the bug reproduces only on the second render.
    name: "harness/react-hooks",
    plugins: { "react-hooks": reactHooks },
    rules: {
      "react-hooks/rules-of-hooks": "error",
      "react-hooks/exhaustive-deps": "error",
    },
  },

  {
    // No circular imports: a cycle is circular justification between modules,
    // and undefined-initialization bugs in practice.
    plugins: { "import-x": importX },
    settings: {
      "import-x/resolver-next": [createTypeScriptImportResolver()],
      // Without these the dependency graph only parses .js — the rule goes silently
      // blind to .ts/.tsx (verified by negative test; see agentic-harness AGENT-LOG).
      "import-x/extensions": [".ts", ".tsx", ".js", ".jsx", ".mjs"],
      "import-x/parsers": { "@typescript-eslint/parser": [".ts", ".tsx"] },
    },
    rules: { "import-x/no-cycle": ["error", { maxDepth: 8 }] },
  },

  {
    // The pure core: domain logic in plain TS, React only renders. Framework-free
    // means testable without a renderer, which is what keeps the tests fast and
    // the logic reusable when the UI is rewritten.
    name: "harness/pure-core",
    files: ["src/lib/**/*.{ts,tsx}"],
    rules: {
      "no-restricted-imports": [
        "error",
        {
          paths: [
            { name: "react", message: "src/lib is the pure core — no framework imports." },
            { name: "react-dom", message: "src/lib is the pure core — no renderer imports." },
          ],
          patterns: [
            {
              group: ["@/components/*", "*.tsx"],
              message: "src/lib is the pure core — no component imports.",
            },
          ],
        },
      ],
    },
  },

  {
    // Plain JS (scripts, configs): typed rules would fail on files outside tsconfig.
    files: ["**/*.{js,mjs,cjs}"],
    ...tseslint.configs.disableTypeChecked,
  },
  {
    // Node CLI scripts: console IS their interface — `no-console` targets app code.
    files: ["scripts/**/*.{js,mjs,cjs}"],
    languageOptions: { globals: globals.node },
    rules: { "no-console": "off" },
  },
  {
    // Test files legitimately exceed function-length limits (describe blocks).
    files: ["src/**/*.test.{ts,tsx}", "tests/**/*.test.{ts,tsx}"],
    rules: { "max-lines-per-function": "off" },
  },
);
