#!/usr/bin/env bash
# gate-selftest: prove THIS repo's own counting gates are not blind. For each gate, plant a
# KNOWN violation, run the gate, and require it to REJECT. A gate that passes a planted
# violation is blind - which is exactly how a real ratchet failed unseen: a budget check read
# 0 for its whole life because its perimeter did not include the code it was meant to count,
# and a unit test of the counter would have passed while the WIRING was broken. Only running
# the gate against a real violation catches that (ADR 65).
#
# The harness proves its OWN gates this way in scripts/selftest.sh, but selftest.sh is not
# shipped; this is the shipped equivalent, so a generated repo can see its correctness layer
# actually work. Read-only on your committed tree: fixtures live under a temp dir and are
# always removed (trap), even on failure.
set -u

FIX="src/__gate_selftest__"
cleanup() { rm -rf "$FIX"; }
trap cleanup EXIT
fail=0

# --- clones: two identical 8-line blocks must exceed the copy-paste budget ---
rm -rf "$FIX"; mkdir -p "$FIX"
for name in first second; do
  cat > "$FIX/clone-$name.ts" <<'EOF'
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
if pnpm clones > /dev/null 2>&1; then
  echo "BLIND GATE (clones): passed a planted copy-paste violation - the counting gate is not seeing this code" >&2
  fail=1
fi
rm -rf "$FIX"

# --- stranded: pure logic in a .tsx must exceed the stranded budget ---
mkdir -p "$FIX"
cat > "$FIX/setup-hub.tsx" <<'EOF'
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
if pnpm stranded > /dev/null 2>&1; then
  echo "BLIND GATE (stranded): passed pure logic planted in a .tsx - the counting gate is not seeing this code" >&2
  fail=1
fi
rm -rf "$FIX"

if [ "$fail" -ne 0 ]; then
  echo "gate-selftest FAILED: a counting gate is blind (did not reject a planted violation)." >&2
  exit 1
fi
echo "gate-selftest OK: clones and stranded each rejected a planted violation."
