#!/usr/bin/env bash
# Consumes templates/ts-base EXACTLY as its README instructs, in a throwaway dir,
# and asserts the three claims the template makes:
#   1. `pnpm verify` is green on the empty scaffold;
#   2. commit #1 passes the pre-commit hook (deletion-guard → lint-staged → verify);
#   3. the deletion guard actually blocks a >80-line deletion.
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

echo "SELFTEST OK — empty-scaffold verify green, hook fires on commit #1, guard blocks."
