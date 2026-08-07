#!/usr/bin/env bash
# Consumes templates/ts-base EXACTLY as its README instructs, in a throwaway dir,
# and asserts the claims the template makes:
#   0. AGENTS.md is canonical and the vendor adapters (CLAUDE.md/GEMINI.md/.claude) cohere;
#   1. `pnpm verify` is green on the empty scaffold;
#   2. commit #1 passes the pre-commit hook (deletion-guard → lint-staged → verify);
#   3. the deletion guard actually blocks a >80-line deletion;
#   4. the gate REJECTS violating code — a rule never seen saying "no" is decoration
#      (lesson of 2026-07-10: import-x/no-cycle shipped wired-but-blind; see AGENT-LOG);
#   5. the copy-paste budget blocks a verbatim paste, names the file the author just
#      wrote, and PASSES when the count falls (the asymmetry is the point, ADR 27).
# Wired into this repo's CI: the claims are gates, not prose.
set -euo pipefail

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cd "$TMP"

echo "==> Step 1 (README): git init BEFORE install — husky's prepare needs .git"
git init -q -b main
git config user.email selftest@local
git config user.name selftest

echo "==> Step 2 (README): copy every template file (dotfiles included)"
cp -r "$HARNESS_DIR/templates/ts-base/." .

echo "==> Step 3 (README): merge the package.json snippet (canonical: package.snippet.json)"
node -e '
  const fs = require("node:fs");
  const snippet = JSON.parse(fs.readFileSync("package.snippet.json", "utf8"));
  fs.writeFileSync(
    "package.json",
    JSON.stringify({ name: "ts-base-selftest", private: true, ...snippet }, null, 2),
  );
'
rm package.snippet.json README.md
chmod +x .husky/pre-push

echo "==> Claim 0: canonical AGENTS.md + adapters are present and coherent"
test -f AGENTS.md || { echo "FAIL: AGENTS.md missing" >&2; exit 1; }
grep -q "@AGENTS.md" CLAUDE.md || { echo "FAIL: CLAUDE.md is not an @AGENTS.md adapter" >&2; exit 1; }
grep -q "AGENTS.md" GEMINI.md || { echo "FAIL: GEMINI.md does not point to AGENTS.md" >&2; exit 1; }
node -e 'JSON.parse(require("node:fs").readFileSync(".claude/settings.json","utf8"))' \
  || { echo "FAIL: .claude/settings.json is not valid JSON" >&2; exit 1; }

echo "==> Claim 0b: the packaged rites are present and the auditor stays read-only"
for f in .claude/agents/auditor.md .claude/agents/test-auditor.md .claude/skills/feature/SKILL.md \
  .claude/skills/audit/SKILL.md .claude/skills/audit-tests/SKILL.md .claude/skills/debug/SKILL.md; do
  test -f "$f" || { echo "FAIL: $f missing (rites-as-skills claim)" >&2; exit 1; }
  head -1 "$f" | grep -qx -- '---' || { echo "FAIL: $f lacks frontmatter" >&2; exit 1; }
done
for agent in auditor test-auditor; do
  grep -q '^tools: Read, Grep, Glob$' ".claude/agents/$agent.md" \
    || { echo "FAIL: $agent must stay read-only (tools: Read, Grep, Glob)" >&2; exit 1; }
done

echo "==> Step 4 (README): pnpm install + chmod hook"
pnpm install
chmod +x .husky/pre-commit

echo "==> Claim 1: verify must be green on the EMPTY scaffold"
pnpm verify

echo "==> Claim 2: commit #1 'chore: scaffold + guardrails' must pass the hook"
git add -A
git commit -m "chore: scaffold + guardrails"

echo "==> Claim 3: deletion guard must block a >80-line deletion"
seq 1 100 > big.txt
git add big.txt
git commit -q -m "chore: seed file for guard test" --no-verify # bypass: not under test here
git rm -q big.txt
if git commit -m "test: should be blocked" 2>guard.log; then
  echo "FAIL: deletion guard did NOT block a 100-line deletion" >&2
  exit 1
fi
grep -q "Deletion guard" guard.log || { cat guard.log >&2; exit 1; }

echo "==> Claim 4: the gate must REJECT violating code (negative tests of the gate itself)"
mkdir -p src
cat > src/violations.ts <<'EOF'
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
cat > src/cycle-a.ts <<'EOF'
import { b } from "./cycle-b";
export const a: number = b + 1;
EOF
cat > src/cycle-b.ts <<'EOF'
import { a } from "./cycle-a";
export const b: number = a + 1;
EOF
if pnpm lint > lint.log 2>&1; then
  echo "FAIL: lint accepted code that violates four rules at once" >&2
  cat lint.log >&2
  exit 1
fi
for rule in "no-explicit-any" "eqeqeq" "switch-exhaustiveness-check" "import-x/no-cycle" "max-depth"; do
  grep -q "$rule" lint.log || {
    echo "FAIL: rule '$rule' did not fire on a deliberate violation (wired-but-blind)" >&2
    cat lint.log >&2
    exit 1
  }
done

# Clear Claim 4's violations so the next check sees only the test-hygiene rules fire, isolated.
rm -f src/violations.ts src/cycle-a.ts src/cycle-b.ts
echo "==> Claim 4b: test-hygiene rules reject .only and a bare .skip (the kill-test gate, ADR 58)"
mkdir -p src/lib
cat > src/lib/hygiene.test.ts <<'EOF'
import { describe, it, test, expect } from "vitest";

describe.only("focused", () => {
  it("runs", () => {
    expect(1).toBe(1);
  });
});

test.skip("a silently disabled kill test", () => {
  expect(1).toBe(2);
});
EOF
if pnpm lint > hygiene.log 2>&1; then
  echo "FAIL: lint accepted .only and a bare .skip — a kill test could hide in a green suite" >&2
  cat hygiene.log >&2
  exit 1
fi
for rule in "vitest/no-focused-tests" "vitest/no-disabled-tests"; do
  grep -q "$rule" hygiene.log || {
    echo "FAIL: rule '$rule' did not fire on a deliberate test-hygiene violation (wired-but-blind)" >&2
    cat hygiene.log >&2
    exit 1
  }
done
rm -f src/lib/hygiene.test.ts

echo "==> Claim 5: the copy-paste budget must block a pasted block and pass when it shrinks"
rm -f src/violations.ts src/cycle-a.ts src/cycle-b.ts
# Eight significant lines, which is the window: shorter and the gate is blind by
# design, so a fixture under it would prove nothing.
for name in first second; do
  cat > "src/clone-$name.ts" <<'EOF'
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
  echo "FAIL: the copy-paste budget accepted a verbatim paste (wired-but-blind)" >&2
  cat clones.log >&2
  exit 1
fi
grep -q "Copy-paste budget exceeded" clones.log || { cat clones.log >&2; exit 1; }
grep -q "clone-first.ts" clones.log || {
  echo "FAIL: the failure did not name the cloned file the author just wrote" >&2
  cat clones.log >&2
  exit 1
}
# The filenames alone prove nothing: the fallback branch prints the same list
# under "Could not tell which are new". Without this line the assertion above
# passed with touchedFiles() returning an empty set, so C-104's only mechanical
# evidence was vacuous (audit 2026-07-30).
grep -q "Clones involving files you touched" clones.log || {
  echo "FAIL: the failure output did not scope to the author's files (C-104)" >&2
  cat clones.log >&2
  exit 1
}
# A block that opens AND closes a comment before real code is still a clone.
# Dropping such a line whole took an 8-line paste down to 7 and under the window.
rm -f src/clone-first.ts src/clone-second.ts
for name in third fourth; do
  cat > "src/clone-$name.ts" <<'EOF'
/* seed */ const base = 42;
const total = rows.reduce((sum, n) => sum + n, base);
const count = rows.length;
const mean = count === 0 ? 0 : total / count;
const high = rows.reduce((hi, n) => (n > hi ? n : hi), 0);
const low = rows.reduce((lo, n) => (n < lo ? n : lo), 0);
const spread = high - low;
const label = `${String(count)} rows, spread ${String(spread)}`;
EOF
done
if pnpm clones > inline.log 2>&1; then
  echo "FAIL: a paste whose first line carries an inline block comment was missed" >&2
  cat inline.log >&2
  exit 1
fi
# Asymmetry, both halves. Equal-to-budget passes; strictly under passes AND says
# so — that branch was unreachable in a scaffold whose budget ships at 0, so the
# ratchet direction C-102 names had never been exercised.
pnpm clones --update > /dev/null 2>&1 || { echo "FAIL: --update must succeed" >&2; exit 1; }
pnpm clones > equal.log 2>&1 || { echo "FAIL: at-budget must pass" >&2; cat equal.log >&2; exit 1; }
rm src/clone-fourth.ts
pnpm clones > under.log 2>&1 || { echo "FAIL: under-budget must pass, never fail" >&2; cat under.log >&2; exit 1; }
grep -q "ratchet it down" under.log || {
  echo "FAIL: a shrink did not prompt the ratchet — the direction C-102 claims" >&2
  cat under.log >&2
  exit 1
}
rm -f src/clone-third.ts
node scripts/clone-budget-check.mjs --update > /dev/null

echo "==> Claim 6: the diff-size nudge warns past budget and stays silent under it (C-072)"
# Warn-not-block: it must print AND exit 0, and be silent when there is no base
# ref to compare against (fail open, since a size hint is not worth an error).
seq 1 400 | sed 's/^/const x/;s/$/ = 0;/' > src/big.ts
git add src/big.ts
git commit -q -m "test: large branch" --no-verify  # committed: the nudge measures pushed work
# No origin/main in this throwaway repo, so point the base at the initial commit.
BASE="$(git rev-list --max-parents=0 HEAD | head -1)"
warn="$(DIFF_SIZE_BASE=$BASE node scripts/diff-size-check.mjs 2>&1)"; code=$?
[ "$code" -eq 0 ] || { echo "FAIL: the diff-size nudge blocked (must warn, never block)" >&2; exit 1; }
grep -q "Diff-size nudge" <<<"$warn" || { echo "FAIL: past budget, the nudge said nothing" >&2; echo "$warn" >&2; exit 1; }
silent="$(DIFF_SIZE_BASE=$BASE DIFF_SIZE_BUDGET=99999 node scripts/diff-size-check.mjs 2>&1)"
test -z "$silent" || { echo "FAIL: under budget, the nudge still fired" >&2; echo "$silent" >&2; exit 1; }
nogit="$(DIFF_SIZE_BASE=does-not-exist node scripts/diff-size-check.mjs 2>&1)"; code=$?
[ "$code" -eq 0 ] && [ -z "$nogit" ] || { echo "FAIL: a missing base ref must fail open and silent" >&2; exit 1; }
git rm -q src/big.ts; git commit -q -m "test: cleanup" --no-verify

echo "==> Claim 7: mutation testing survives a weak test and passes a strong one (ADR 38)"
# The wired half of "every test must fail if the logic breaks": Stryker mutates
# src/lib and breaks (exit != 0) if any mutant survives. Seen rejecting a real
# weak test, not just asserted. Empty src/lib must pass (allowEmpty), so the
# scaffold is not held hostage to mutation before any pure logic exists.
mkdir -p src/lib
mutants_empty="$(pnpm mutants > mut-empty.log 2>&1; echo $?)"
[ "$mutants_empty" -eq 0 ] || { echo "FAIL: mutants must pass on an empty src/lib (allowEmpty)" >&2; cat mut-empty.log >&2; exit 1; }

cat > src/lib/eligible.ts <<'EOF'
export function eligible(age: number): boolean {
  return age >= 18;
}
EOF
# WEAK: never pins the boundary, so the `>=`->`>` mutant survives.
cat > src/lib/eligible.test.ts <<'EOF'
import { expect, test } from "vitest";

import { eligible } from "./eligible";

test("eligible", () => {
  expect(eligible(20)).toBe(true);
  expect(eligible(10)).toBe(false);
});
EOF
if pnpm mutants > mut-weak.log 2>&1; then
  echo "FAIL: mutation testing PASSED a weak test that never pins the boundary (wired-but-blind)" >&2
  cat mut-weak.log >&2
  exit 1
fi
grep -qi "survived" mut-weak.log || { echo "FAIL: a mutant survived but the report did not say so" >&2; cat mut-weak.log >&2; exit 1; }

# STRONG: pins the boundary (18) and one below (17), killing every mutant.
cat > src/lib/eligible.test.ts <<'EOF'
import { expect, test } from "vitest";

import { eligible } from "./eligible";

test("eligible pins the boundary", () => {
  expect(eligible(18)).toBe(true);
  expect(eligible(17)).toBe(false);
  expect(eligible(0)).toBe(false);
});
EOF
pnpm mutants > mut-strong.log 2>&1 || { echo "FAIL: a strong test that kills every mutant was still rejected" >&2; cat mut-strong.log >&2; exit 1; }
rm -f src/lib/eligible.ts src/lib/eligible.test.ts

echo "==> Claim 8: the stranded-logic budget rejects pure logic in a .tsx renderer (ADR 40)"
# The wired half of "components render, lib decides": a pure function in a .tsx
# file is counted, and the count may only rise past the budget once. Seen
# rejecting a real stranded function, and passing when it moves to src/lib.
mkdir -p src/components src/lib
cat > src/components/setup-hub.tsx <<'EOF'
import { useState } from "react";

function deriveSetupItems(hasHours: boolean, hasInfo: boolean): string[] {
  const items: string[] = [];
  if (!hasHours) items.push("hours");
  if (hasInfo) items.push("info");
  return items.filter((i) => i.length > 0);
}

export function SetupHub() {
  const [n] = useState(0);
  return <div>{deriveSetupItems(false, true).length + n}</div>;
}
EOF
if pnpm stranded > stranded.log 2>&1; then
  echo "FAIL: the stranded-logic budget accepted pure logic inside a .tsx (wired-but-blind)" >&2
  cat stranded.log >&2
  exit 1
fi
grep -q "Stranded-logic budget exceeded" stranded.log || { cat stranded.log >&2; exit 1; }
grep -q "deriveSetupItems" stranded.log || { echo "FAIL: the failure did not name the stranded function" >&2; cat stranded.log >&2; exit 1; }
# A false positive of a KNOWN impure kind must be skipped: a canvas exporter is I/O.
cat > src/components/image-tools.tsx <<'EOF'
export function exportCrop(canvas: HTMLCanvasElement): string {
  const ctx = canvas.getContext("2d");
  if (ctx) ctx.fillRect(0, 0, 1, 1);
  return canvas.toDataURL("image/png");
}
EOF
# Move the real stranded function to src/lib; the canvas one stays but is impure,
# so the count returns to 0 and the budget passes.
cat > src/lib/setup.ts <<'EOF'
export function deriveSetupItems(hasHours: boolean, hasInfo: boolean): string[] {
  const items: string[] = [];
  if (!hasHours) items.push("hours");
  if (hasInfo) items.push("info");
  return items.filter((i) => i.length > 0);
}
EOF
cat > src/components/setup-hub.tsx <<'EOF'
import { useState } from "react";

import { deriveSetupItems } from "@/lib/setup";

export function SetupHub() {
  const [n] = useState(0);
  return <div>{deriveSetupItems(false, true).length + n}</div>;
}
EOF
pnpm stranded > stranded-ok.log 2>&1 || { echo "FAIL: after moving to src/lib (impure canvas fn skipped), the budget still failed" >&2; cat stranded-ok.log >&2; exit 1; }
rm -f src/components/setup-hub.tsx src/components/image-tools.tsx src/lib/setup.ts

# Regression (ultrareview, ADR 44): expression-body arrow one-liners are NOT
# stranded logic. readBody once ran past a brace-free arrow to the next `{...}`,
# inflating a 1-line body past the `< 4` filter and flagging trivial helpers.
mkdir -p src/components
cat > src/components/arrows.tsx <<'EOF'
const isPositive = (n: number) => n > 0;
const isNegative = (n: number) => n < 0;
const isZero = (n: number) => n === 0;

export function Arrows() {
  return null;
}
EOF
pnpm stranded > arrows.log 2>&1 \
  || { echo "FAIL: trivial arrow one-liners were flagged as stranded (readBody swallowed siblings)" >&2; cat arrows.log >&2; exit 1; }
rm -f src/components/arrows.tsx

# The blocking CI job must ship, or a future edit drops the standing gate silently.
grep -q "^  mutation:" .github/workflows/ci.yml \
  || { echo "FAIL: ci.yml ships no mutation job — the standing gate is gone (ADR 39)" >&2; exit 1; }
grep -q "pnpm mutants:ci" .github/workflows/ci.yml \
  || { echo "FAIL: the mutation job does not run the incremental script" >&2; exit 1; }
grep -q "stryker-incremental.json" .github/workflows/ci.yml \
  || { echo "FAIL: the mutation job does not cache the incremental baseline (cost would not track the diff)" >&2; exit 1; }
grep -q "\"mutants:ci\": \"stryker run --incremental\"" package.json \
  || { echo "FAIL: the mutants:ci script is missing or not incremental" >&2; exit 1; }

echo "SELFTEST OK — empty-scaffold verify green, hook fires on commit #1, guard blocks, gate rejects, clone + stranded budgets hold, diff-size nudge warns, mutation kills a weak test."
