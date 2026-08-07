import js from "@eslint/js";
import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";
import { createTypeScriptImportResolver } from "eslint-import-resolver-typescript";
import importX from "eslint-plugin-import-x";
import globals from "globals";
import tseslint from "typescript-eslint";

// Force layer for the Next.js path: the ts-base validity bar + the React rules,
// composed ON TOP of eslint-config-next (which brings react, react-hooks, jsx-a11y
// and the @next/next plugin). Next ships several of these as warnings and the
// harness has no warning level, so the load-bearing ones are pinned to error here.
export default defineConfig([
  globalIgnores([
    ".next/**",
    "out/**",
    "build/**",
    "coverage/**",
    "node_modules/**",
    "next-env.d.ts",
    "**/*.config.*",
  ]),

  js.configs.recommended,
  ...tseslint.configs.strictTypeChecked,
  ...nextVitals,
  ...nextTs,

  {
    // Type-aware rules need the project wired; ts/tsx only.
    files: ["**/*.{ts,tsx}"],
    languageOptions: { parserOptions: { projectService: true } },
    rules: {
      "@typescript-eslint/no-explicit-any": "error",
      "@typescript-eslint/no-floating-promises": "error",
      "@typescript-eslint/ban-ts-comment": "error",
      eqeqeq: ["error", "always"],
      "@typescript-eslint/switch-exhaustiveness-check": "error",
      complexity: ["error", 10],
      "max-depth": ["error", 3],
      "max-lines-per-function": ["error", 60],
      "max-lines": ["error", 300],
      "no-console": "error",
      // exhaustive-deps ships as warn in the plugin's preset; the playbook pins it
      // to error (a lying dependency array is the classic AI-React bug).
      "react-hooks/exhaustive-deps": "error",
      "react-hooks/rules-of-hooks": "error",
      "jsx-a11y/alt-text": "error",
    },
  },

  {
    // No circular imports (import-x parses ts/tsx, unlike the default .js-only graph).
    plugins: { "import-x": importX },
    settings: {
      "import-x/resolver-next": [createTypeScriptImportResolver()],
      "import-x/extensions": [".ts", ".tsx", ".js", ".jsx", ".mjs"],
      "import-x/parsers": { "@typescript-eslint/parser": [".ts", ".tsx"] },
    },
    rules: { "import-x/no-cycle": ["error", { maxDepth: 8 }] },
  },

  {
    // The pure core: domain logic in plain TS, the framework only renders.
    files: ["src/lib/**/*.{ts,tsx}"],
    rules: {
      "no-restricted-imports": [
        "error",
        {
          paths: [
            { name: "react", message: "src/lib is the pure core - no framework imports." },
            { name: "react-dom", message: "src/lib is the pure core - no renderer imports." },
            { name: "next", message: "src/lib is the pure core - no framework imports." },
          ],
          patterns: [
            { group: ["next/*"], message: "src/lib is the pure core - no framework imports." },
            { group: ["@/components/*", "*.tsx"], message: "src/lib is the pure core - no component imports." },
          ],
        },
      ],
    },
  },

  {
    // Plain JS (scripts, configs): typed rules would fail outside tsconfig.
    files: ["**/*.{js,mjs,cjs}"],
    ...tseslint.configs.disableTypeChecked,
  },
  {
    // Node CLI scripts: console IS their interface.
    files: ["scripts/**/*.{js,mjs,cjs}"],
    languageOptions: { globals: globals.node },
    rules: { "no-console": "off" },
  },
  {
    files: ["src/**/*.test.{ts,tsx}", "tests/**/*.test.{ts,tsx}"],
    rules: { "max-lines-per-function": "off" },
  },
]);
