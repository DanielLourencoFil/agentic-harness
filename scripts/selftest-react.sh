#!/usr/bin/env bash
# Consumes templates/react-starter EXACTLY as its README instructs — create-vite
# react-ts scaffold + ts-base shared files + react-starter overrides — and asserts:
#   1. `pnpm verify` is green on the stripped scaffold;
#   2. commit #1 passes the pre-commit hook;
#   3. the gate REJECTS violations: any, ==, non-exhaustive switch, import cycle,
#      max-depth, a hook called conditionally, a lying dependency array, a
#      duplicated block (copy-paste budget), and React inside the pure core.
# Also a canary: create-vite is fetched fresh, so upstream drift breaks THIS job
# before it breaks a real kickoff.
set -euo pipefail

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TSB="$HARNESS_DIR/templates/ts-base"
REACT="$HARNESS_DIR/templates/react-starter"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cd "$TMP"

echo "==> Step 1-2 (README): git init, then create-vite scaffold"
git init -q -b main
git config user.email selftest@local
git config user.name selftest
pnpm create vite@latest app --template react-ts >/dev/null 2>&1
cp -r app/. . && rm -rf app

echo "==> Step 3 (README): strip the demo; minimal App"
rm -rf src/assets public src/App.css
mkdir -p src/lib tests
cat > src/App.tsx <<'EOF'
export function App() {
  return <h1>Scaffold</h1>;
}
EOF
cat > src/main.tsx <<'EOF'
import { StrictMode } from "react";
import { createRoot } from "react-dom/client";

import { App } from "./App";

const root = document.getElementById("root");
if (!root) throw new Error("Missing #root element");

createRoot(root).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
EOF

echo "==> Step 4 (README): shared files from ts-base"
cp -r "$TSB/.husky" .
mkdir -p scripts .github/workflows
cp "$TSB/scripts/deletion-guard.mjs" "$TSB/scripts/clone-budget-check.mjs" \
   "$TSB/scripts/clone-detect.mjs" scripts/
cp "$TSB/.prettierrc.json" "$TSB/.clonebudget.json" "$TSB/AGENTS.md" \
   "$TSB/CLAUDE.md" "$TSB/GEMINI.md" .
cp "$TSB/.github/workflows/ci.yml" "$TSB/.github/workflows/audit.yml" .github/workflows/
cp -r "$TSB/.claude" .
cat "$TSB/.gitignore" >> .gitignore
chmod +x .husky/pre-commit

echo "==> Step 5-6 (README): react-starter overrides + conventions appended"
cp "$REACT/eslint.config.mjs" "$REACT/vitest.config.ts" \
   "$REACT/tsconfig.json" "$REACT/tsconfig.app.json" "$REACT/tsconfig.base.json" .
rm -f tsconfig.node.json
printf '\n' >> AGENTS.md
cat "$REACT/react-conventions.md" >> AGENTS.md

echo "==> Step 7 (README): merge package.snippet.json"
node - "$REACT/package.snippet.json" <<'EOF'
const fs = require("node:fs");
const snippet = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const pkg = JSON.parse(fs.readFileSync("package.json", "utf8"));
Object.assign(pkg.scripts, snippet.scripts);
pkg["lint-staged"] = snippet["lint-staged"];
Object.assign(pkg.devDependencies, snippet.devDependencies);
fs.writeFileSync("package.json", JSON.stringify(pkg, null, 2));
EOF

echo "==> Step 8 (README): install + verify green on the stripped scaffold"
pnpm install >/dev/null 2>&1
pnpm verify

echo "==> Claim 2: commit #1 passes the hook"
git add -A
git commit -q -m "chore: scaffold + guardrails"

echo "==> Claim 3: the gate must REJECT violations (validity, hooks, pure-core)"
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
export function deep(xs: number[][][]): number {
  let total = 0;
  for (const grid of xs) {
    for (const row of grid) {
      for (const cell of row) {
        if (cell > 0) {
          total += cell;
        }
      }
    }
  }
  return total;
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
import { useState } from "react";
export const impure = useState;
EOF
# The two React failure modes the playbook names: a hook behind a condition, and
# a dependency array that lies about what the effect reads.
cat > src/Bad.tsx <<'EOF'
import { useEffect, useState } from "react";

export function Bad({ flag, id }: { flag: boolean; id: string }) {
  if (flag) {
    const [x] = useState(0);
    return <p>{x}</p>;
  }
  const [name, setName] = useState("");
  useEffect(() => {
    setName(id);
  }, []);
  return <p>{name}</p>;
}
EOF
if pnpm lint > lint.log 2>&1; then
  echo "FAIL: lint accepted violating code" >&2
  cat lint.log >&2
  exit 1
fi
for rule in "no-explicit-any" "eqeqeq" "switch-exhaustiveness-check" "import-x/no-cycle" \
            "max-depth" "react-hooks/rules-of-hooks" "react-hooks/exhaustive-deps" \
            "no-restricted-imports"; do
  grep -q "$rule" lint.log || {
    echo "FAIL: rule '$rule' did not fire on a deliberate violation (wired-but-blind)" >&2
    cat lint.log >&2
    exit 1
  }
done

echo "==> Claim 4: the copy-paste budget must reject a pasted block"
rm -f src/Bad.tsx src/lib/bad.ts src/lib/cycle-a.ts src/lib/cycle-b.ts src/lib/impure.ts
for name in first second; do
  cat > "src/lib/clone-$name.ts" <<'EOF'
export function summarize(rows: readonly number[]): string {
  const total = rows.reduce((sum, n) => sum + n, 0);
  const count = rows.length;
  const mean = count === 0 ? 0 : total / count;
  const max = rows.reduce((hi, n) => (n > hi ? n : hi), 0);
  const min = rows.reduce((lo, n) => (n < lo ? n : lo), 0);
  const spread = max - min;
  return `${String(count)} rows, mean ${mean.toFixed(2)}, spread ${String(spread)}`;
}
EOF
done
if pnpm clones > clones.log 2>&1; then
  echo "FAIL: the copy-paste budget accepted a verbatim paste" >&2
  cat clones.log >&2
  exit 1
fi
grep -q "Copy-paste budget exceeded" clones.log || { cat clones.log >&2; exit 1; }

echo "SELFTEST-REACT OK — stripped scaffold verifies green, hook fires, gate rejects all eight."
