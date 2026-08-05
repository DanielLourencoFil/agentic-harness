import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    // Harness convention: tests live beside the code they cover, or in tests/.
    include: ["src/**/*.test.{ts,tsx}", "tests/**/*.test.{ts,tsx}"],
    // Green on an empty scaffold, inert once the first real test lands.
    passWithNoTests: true,
    environment: "node",
    coverage: { reporter: ["text", "html"] },
  },
});
