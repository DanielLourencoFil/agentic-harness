import js from "@eslint/js";
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
      complexity: ["error", 10],
      "max-lines-per-function": ["error", 60],
      "max-lines": ["error", 300],
      "no-console": "error",
    },
  },
  {
    // Plain JS (scripts/, configs) — typed rules would fail on files outside tsconfig.
    files: ["**/*.{js,mjs,cjs}"],
    ...tseslint.configs.disableTypeChecked,
  },
  { ignores: ["dist/", "coverage/", "node_modules/", "**/*.config.*"] },
);
