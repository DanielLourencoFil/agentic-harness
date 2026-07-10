import js from "@eslint/js";
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
  { ignores: ["dist/", "coverage/", "node_modules/", "**/*.config.*"] },
);
