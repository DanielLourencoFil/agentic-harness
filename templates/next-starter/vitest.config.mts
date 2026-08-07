import { fileURLToPath } from "node:url";

import { defineConfig } from "vitest/config";

export default defineConfig({
  // The @/* alias mirrors tsconfig paths so tests import the pure core the same
  // way the app does.
  resolve: {
    alias: { "@": fileURLToPath(new URL("./src", import.meta.url)) },
  },
  test: {
    include: ["src/**/*.test.{ts,tsx}", "tests/**/*.test.{ts,tsx}"],
    // Green on an empty scaffold, inert once the first real test lands.
    passWithNoTests: true,
    environment: "node",
    coverage: { reporter: ["text", "html"] },
  },
});
