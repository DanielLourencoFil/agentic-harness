import js from "@eslint/js";
import vitest from "@vitest/eslint-plugin";
import { createTypeScriptImportResolver } from "eslint-import-resolver-typescript";
import importX from "eslint-plugin-import-x";
import globals from "globals";
import tseslint from "typescript-eslint";

// Force layer: objective, local constraints the AI cannot argue its way past.
// (Semantic design — SOLID, correctness — is NOT enforced here; that is review.)
export default tseslint.config(
  js.configs.recommended,
  ...tseslint.configs.strictTypeChecked,
  {
    languageOptions: { parserOptions: { projectService: true } },
    rules: {
      "@typescript-eslint/no-explicit-any": "error",
      "@typescript-eslint/no-floating-promises": "error",
      "@typescript-eslint/ban-ts-comment": "error",
      // No coerced equality: `==` declares different things equal (see docs/RATIONALE.md).
      eqeqeq: ["error", "always"],
      // No ignored cases: a switch over a union must handle every member.
      "@typescript-eslint/switch-exhaustiveness-check": "error",
      complexity: ["error", 10],
      // Shallow nesting: guard clauses over pyramids. Depth taxes both readers,
      // the human refuter and the agent's context (see docs/RATIONALE.md, ADR 7).
      "max-depth": ["error", 3],
      "max-lines-per-function": ["error", 60],
      "max-lines": ["error", 300],
      "no-console": "error",
    },
  },
  {
    // No circular imports: a cycle is circular justification between modules —
    // and undefined-initialization bugs in practice.
    plugins: { "import-x": importX },
    settings: {
      "import-x/resolver-next": [createTypeScriptImportResolver()],
      // Without these the dependency graph only parses .js — the rule goes silently
      // blind to .ts files (verified by negative test; see AGENT-LOG).
      "import-x/extensions": [".ts", ".tsx", ".js", ".mjs"],
      "import-x/parsers": { "@typescript-eslint/parser": [".ts", ".tsx"] },
    },
    rules: { "import-x/no-cycle": ["error", { maxDepth: 8 }] },
  },
  {
    // Plain JS (scripts/, configs) — typed rules would fail on files outside tsconfig.
    files: ["**/*.{js,mjs,cjs}"],
    ...tseslint.configs.disableTypeChecked,
  },
  {
    // Node CLI scripts: they run under Node (process/console are real globals) and
    // console IS their interface — `no-console` targets application code, not tooling.
    files: ["scripts/**/*.{js,mjs,cjs}"],
    languageOptions: { globals: globals.node },
    rules: { "no-console": "off" },
  },
  {
    // Test hygiene (force): a silently disabled or focused test is a hole in a green suite.
    // `.only` disables every other test; `.skip`/`.todo` must be a DECISION carrying a reason
    // (an eslint-disable comment), not silent drift - this is how a pre-registered kill test
    // for the riskiest assumption stays visible instead of a dated prose reminder nobody runs.
    files: ["**/*.test.{ts,tsx}", "tests/**/*.{ts,tsx}"],
    plugins: { vitest },
    rules: {
      "vitest/no-focused-tests": "error",
      "vitest/no-disabled-tests": "error",
    },
  },
  { ignores: ["dist/", "coverage/", "node_modules/", "**/*.config.*"] },
);
