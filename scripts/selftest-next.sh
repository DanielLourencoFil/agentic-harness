#!/usr/bin/env bash
# Consumes templates/next-starter EXACTLY as its README instructs — create-next-app
# App-Router + Tailwind scaffold + ts-base shared files + next-starter overrides — and
# asserts:
#   1. `pnpm verify` is green on the stripped scaffold;
#   2. the guardrails commit passes the pre-commit hook;
#   3. the gate REJECTS violations: any, ==, non-exhaustive switch, import cycle,
#      max-depth, a hook called conditionally, a lying dependency array, an image with
#      no alt text, and framework imports (react AND next) inside the pure core;
#   4. the copy-paste budget rejects a pasted block;
#   5. the stranded-logic budget rejects pure logic in a .tsx renderer.
# Also a canary: create-next-app is fetched fresh, so upstream drift breaks THIS job
# before it breaks a real kickoff.
set -euo pipefail

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TSB="$HARNESS_DIR/templates/ts-base"
NEXT="$HARNESS_DIR/templates/next-starter"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cd "$TMP"

echo "==> Step 1-2 (README): create-next-app scaffold (into a lowercase subdir)"
# mktemp dir names carry capitals, which npm package names forbid, so scaffold into
# `app` and move up; the README's `.` is correct for a real, lowercase project dir.
pnpm create next-app@latest app --ts --tailwind --app --eslint --src-dir \
  --import-alias "@/*" --use-pnpm --skip-install --yes >/dev/null 2>&1
cp -r app/. . && rm -rf app
# create-next-app commits its demo; reset git so commit #1 is the stripped guardrails
# state (stripping a committed demo would trip the deletion guard, not the point here).
rm -rf .git
git init -q -b main
git config user.email selftest@local
git config user.name selftest

echo "==> Step 3 (README): strip the demo; minimal app + src/lib"
mkdir -p src/lib tests
cat > src/app/page.tsx <<'EOF'
export default function Home() {
  return <main>Scaffold</main>;
}
EOF
cat > src/app/layout.tsx <<'EOF'
import type { ReactNode } from "react";

import "./globals.css";

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
EOF

echo "==> Step 4 (README): shared files from ts-base"
cp -r "$TSB/.husky" .
mkdir -p scripts .github/workflows
cp "$TSB/scripts/deletion-guard.mjs" "$TSB/scripts/clone-budget-check.mjs" \
   "$TSB/scripts/clone-detect.mjs" "$TSB/scripts/stranded-logic-check.mjs" scripts/
cp "$TSB/.prettierrc.json" "$TSB/.clonebudget.json" "$TSB/.strandedbudget.json" \
   "$TSB/AGENTS.md" "$TSB/CLAUDE.md" "$TSB/GEMINI.md" .
cp "$TSB/.github/workflows/ci.yml" "$TSB/.github/workflows/audit.yml" .github/workflows/
cp -r "$TSB/.claude" .
cat "$TSB/.gitignore" >> .gitignore
chmod +x .husky/pre-commit

echo "==> Step 5 (README): next-starter overrides + conventions appended"
cp "$NEXT/eslint.config.mjs" "$NEXT/tsconfig.json" "$NEXT/vitest.config.mts" .
printf '\n' >> AGENTS.md
cat "$NEXT/next-conventions.md" >> AGENTS.md

echo "==> Step 6 (README): merge package.snippet.json"
node - "$NEXT/package.snippet.json" <<'EOF'
const fs = require("node:fs");
const snippet = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const pkg = JSON.parse(fs.readFileSync("package.json", "utf8"));
Object.assign(pkg.scripts, snippet.scripts);
pkg["lint-staged"] = snippet["lint-staged"];
Object.assign(pkg.devDependencies, snippet.devDependencies);
fs.writeFileSync("package.json", JSON.stringify(pkg, null, 2));
EOF

echo "==> Step 7 (README): install + verify green on the stripped scaffold"
pnpm install >/dev/null 2>&1
pnpm verify

echo "==> Claim 2: the guardrails commit passes the hook"
git add -A
git commit -q -m "chore: scaffold + guardrails"

echo "==> Claim 3: the gate must REJECT violations (validity, hooks, a11y, pure-core)"
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
printf 'import { b } from "./cycle-b";\nexport const a: number = b + 1;\n' > src/lib/cycle-a.ts
printf 'import { a } from "./cycle-a";\nexport const b: number = a + 1;\n' > src/lib/cycle-b.ts
# The pure-core ban, both directions the Next path adds: react AND next.
printf 'import { useState } from "react";\nexport const impure = useState;\n' > src/lib/impure.ts
printf 'import Link from "next/link";\nexport const nav = Link;\n' > src/lib/impure-next.ts
# The two React failure modes the playbook names: a hook behind a condition, and a
# dependency array that lies about what the effect reads (a client component).
cat > src/app/Bad.tsx <<'EOF'
"use client";
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
cat > src/app/A11y.tsx <<'EOF'
export function A11y() {
  return <img src="logo.png" />;
}
EOF
if pnpm lint > lint.log 2>&1; then
  echo "FAIL: lint accepted violating code" >&2
  cat lint.log >&2
  exit 1
fi
for rule in "no-explicit-any" "eqeqeq" "switch-exhaustiveness-check" "import-x/no-cycle" \
            "max-depth" "react-hooks/rules-of-hooks" "react-hooks/exhaustive-deps" \
            "jsx-a11y/alt-text" "no-restricted-imports"; do
  grep -q "$rule" lint.log || {
    echo "FAIL: rule '$rule' did not fire on a deliberate violation (wired-but-blind)" >&2
    cat lint.log >&2
    exit 1
  }
done
# The Next-specific half of the pure-core ban: a next/* import must be named restricted.
grep -q "next/link" lint.log || {
  echo "FAIL: the pure-core ban did not reject a next/* import (Next extension blind)" >&2
  cat lint.log >&2
  exit 1
}

echo "==> Claim 4: the copy-paste budget must reject a pasted block"
rm -f src/app/Bad.tsx src/app/A11y.tsx src/lib/bad.ts src/lib/cycle-a.ts \
      src/lib/cycle-b.ts src/lib/impure.ts src/lib/impure-next.ts
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

echo "==> Claim 5: the stranded-logic budget rejects pure logic in a .tsx renderer"
rm -f src/lib/clone-first.ts src/lib/clone-second.ts
mkdir -p src/components
cat > src/components/hub.tsx <<'EOF'
function deriveItems(hasA: boolean, hasB: boolean): string[] {
  const items: string[] = [];
  if (hasA) items.push("a");
  if (hasB) items.push("b");
  return items;
}
export function Hub() {
  return <div>{deriveItems(true, false).length}</div>;
}
EOF
if pnpm stranded > stranded.log 2>&1; then
  echo "FAIL: the stranded-logic budget accepted pure logic inside a .tsx (wired-but-blind)" >&2
  cat stranded.log >&2
  exit 1
fi
grep -q "Stranded-logic budget exceeded" stranded.log || { cat stranded.log >&2; exit 1; }
grep -q "deriveItems" stranded.log || { echo "FAIL: the failure did not name the stranded function" >&2; cat stranded.log >&2; exit 1; }

echo "SELFTEST-NEXT OK — stripped scaffold verifies green, hook fires, gate rejects all nine plus the next/* pure-core ban, copy-paste and stranded .tsx budgets reject."
