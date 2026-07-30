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

echo "==> Claim 0: canonical AGENTS.md + adapters are present and coherent"
test -f AGENTS.md || { echo "FAIL: AGENTS.md missing" >&2; exit 1; }
grep -q "@AGENTS.md" CLAUDE.md || { echo "FAIL: CLAUDE.md is not an @AGENTS.md adapter" >&2; exit 1; }
grep -q "AGENTS.md" GEMINI.md || { echo "FAIL: GEMINI.md does not point to AGENTS.md" >&2; exit 1; }
node -e 'JSON.parse(require("node:fs").readFileSync(".claude/settings.json","utf8"))' \
  || { echo "FAIL: .claude/settings.json is not valid JSON" >&2; exit 1; }

echo "==> Claim 0b: the packaged rites are present and the auditor stays read-only"
for f in .claude/agents/auditor.md .claude/skills/feature/SKILL.md .claude/skills/audit/SKILL.md \
  .claude/skills/debug/SKILL.md; do
  test -f "$f" || { echo "FAIL: $f missing (rites-as-skills claim)" >&2; exit 1; }
  head -1 "$f" | grep -qx -- '---' || { echo "FAIL: $f lacks frontmatter" >&2; exit 1; }
done
grep -q '^tools: Read, Grep, Glob$' .claude/agents/auditor.md \
  || { echo "FAIL: auditor must stay read-only (tools: Read, Grep, Glob)" >&2; exit 1; }

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

echo "==> Claim 5: the copy-paste budget must block a pasted block and pass when it shrinks"
rm -f src/violations.ts src/cycle-a.ts src/cycle-b.ts
mkdir -p src
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

echo "SELFTEST OK — empty-scaffold verify green, hook fires on commit #1, guard blocks, gate rejects, clone budget holds both directions."
