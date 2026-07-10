#!/usr/bin/env bash
# Consumes templates/vue-starter EXACTLY as its README instructs — create-vue
# scaffold + ts-base shared files + vue-starter overrides — and asserts:
#   1. `pnpm verify` is green on the stripped scaffold;
#   2. commit #1 passes the pre-commit hook;
#   3. the gate REJECTS violations: any, ==, non-exhaustive switch, import cycle,
#      v-html in a component, and a framework import inside the pure core.
# Also a canary: create-vue is fetched fresh, so upstream drift breaks THIS job
# before it breaks a real kickoff.
set -euo pipefail

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TSB="$HARNESS_DIR/templates/ts-base"
VUE="$HARNESS_DIR/templates/vue-starter"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cd "$TMP"

echo "==> Step 1-2 (README): git init, then create-vue scaffold"
git init -q -b main
git config user.email selftest@local
git config user.name selftest
pnpm create vue@latest app --ts --pinia --vitest --eslint >/dev/null 2>&1
cp -r app/. . && rm -rf app

echo "==> Step 3 (README): strip the demo and oxlint config; minimal App"
rm -rf src/components src/stores src/assets .oxlintrc.json
mkdir -p src/assets src/lib tests
printf 'body { font-family: system-ui, sans-serif; }\n' > src/assets/main.css
cat > src/App.vue <<'EOF'
<script setup lang="ts"></script>

<template>
  <main>
    <h1>Scaffold</h1>
  </main>
</template>
EOF
cat > src/main.ts <<'EOF'
import "./assets/main.css";

import { createApp } from "vue";
import { createPinia } from "pinia";
import App from "./App.vue";

const app = createApp(App);

app.use(createPinia());

app.mount("#app");
EOF

echo "==> Step 4 (README): shared files from ts-base"
cp -r "$TSB/.husky" .
mkdir -p scripts .github/workflows
cp "$TSB/scripts/deletion-guard.mjs" scripts/
cp "$TSB/.prettierrc.json" "$TSB/.gitignore" "$TSB/AGENTS.md" "$TSB/CLAUDE.md" "$TSB/GEMINI.md" .
cp "$TSB/.github/workflows/ci.yml" "$TSB/.github/workflows/audit.yml" .github/workflows/
cp -r "$TSB/.claude" .
echo "dist-ssr/" >> .gitignore
chmod +x .husky/pre-commit

echo "==> Step 5-6 (README): vue-starter overrides + conventions appended"
cp "$VUE/eslint.config.ts" "$VUE/vitest.config.ts" "$VUE/tsconfig.app.json" "$VUE/tsconfig.vitest.json" .
printf '\n' >> AGENTS.md
cat "$VUE/vue-conventions.md" >> AGENTS.md

echo "==> Step 7 (README): merge package.snippet.json (drop oxlint)"
node - "$VUE/package.snippet.json" <<'EOF'
const fs = require("node:fs");
const snippet = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const pkg = JSON.parse(fs.readFileSync("package.json", "utf8"));
for (const s of snippet.removeScripts) delete pkg.scripts[s];
for (const d of snippet.removeDevDependencies) delete pkg.devDependencies[d];
Object.assign(pkg.scripts, snippet.scripts);
pkg["lint-staged"] = snippet["lint-staged"];
Object.assign(pkg.devDependencies, snippet.devDependencies);
fs.writeFileSync("package.json", JSON.stringify(pkg, null, 2));
EOF

echo "==> Step 8 (README): install + verify green on the stripped scaffold"
pnpm install >/dev/null
pnpm verify

echo "==> Claim 2: commit #1 passes the hook"
git add -A
git commit -q -m "chore: scaffold + guardrails"

echo "==> Claim 3: the gate must REJECT violations (validity, vue, pure-core)"
cat > src/lib/bad.ts <<'EOF'
type Kind = "a" | "b";
export function label(k: Kind): string {
  switch (k) {
    case "a":
      return "A";
  }
  return "?";
}
export function loose(x: any): boolean {
  return (x as unknown) == ("1" as unknown);
}
EOF
cat > src/lib/cycle-a.ts <<'EOF'
import { b } from "./cycle-b";
export const a: number = b + 1;
EOF
cat > src/lib/cycle-b.ts <<'EOF'
import { a } from "./cycle-a";
export const b: number = a + 1;
EOF
cat > src/lib/impure.ts <<'EOF'
import { ref } from "vue";
export const impure = ref(0);
EOF
cat > src/RawHtml.vue <<'EOF'
<script setup lang="ts">
const html = "<b>hi</b>";
</script>

<template>
  <div v-html="html"></div>
</template>
EOF
if pnpm lint > lint.log 2>&1; then
  echo "FAIL: lint accepted violating code" >&2
  cat lint.log >&2
  exit 1
fi
for rule in "no-explicit-any" "eqeqeq" "switch-exhaustiveness-check" "import-x/no-cycle" "vue/no-v-html" "no-restricted-imports"; do
  grep -q "$rule" lint.log || {
    echo "FAIL: rule '$rule' did not fire on a deliberate violation (wired-but-blind)" >&2
    cat lint.log >&2
    exit 1
  }
done

echo "SELFTEST-VUE OK — stripped scaffold verifies green, hook fires, gate rejects all six."
