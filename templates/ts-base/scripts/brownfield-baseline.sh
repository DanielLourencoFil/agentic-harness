#!/usr/bin/env bash
# Brownfield baseline: run EVERY harness gate once against the untouched repo and
# classify each by its result. Read-only - nothing here changes your code. This is the
# operational half of the brownfield rite's "snapshot current violation counts"
# (PLAYBOOK BROWNFIELD step 3): a gate that PASSES today is wirable as blocking now
# (zero-cost-day-1); a gate that FAILS becomes a ratchet whose count may only fall.
#
# The gate list here is the FULL set the harness ships (types, lint, clones, stranded,
# mutation), so no gate is silently left out of the baseline - a gate never snapshotted
# is a gate that never gets a ratchet, i.e. permanently ungated in brownfield. Classify
# by RUNNING, never from memory: which bucket a gate falls in is repo-specific.
#
# Mutation runs Stryker over the whole repo and may take minutes on a large codebase;
# it is deliberately last. This script never fails the build: the report is the product.
set -u

zero_cost=0
ratchet=0

run_gate() {
  local name="$1"; shift
  local log="baseline-${name}.log"
  if "$@" > "$log" 2>&1; then
    printf '  %-10s  zero-cost-day-1  (passes now: wire it as blocking today)\n' "$name"
    zero_cost=$((zero_cost + 1))
  elif grep -qiE 'missing script|cannot find module|no such file|command ".*" not found' "$log"; then
    printf '  %-10s  not-configured   (wire this gate first: %s)\n' "$name" "$*"
  else
    printf '  %-10s  RATCHET          (fails now: record the count in %s as a ceiling that may only fall)\n' "$name" "$log"
    ratchet=$((ratchet + 1))
  fi
}

echo "Brownfield baseline - read-only. Nothing here changes your code."
echo "Run once on the untouched repo. Each gate's result IS its day-1 classification."
echo
run_gate types    pnpm typecheck
run_gate lint     pnpm lint
run_gate clones   pnpm clones
run_gate stranded pnpm stranded
run_gate mutation pnpm mutants
echo
echo "Summary: ${zero_cost} gate(s) zero-cost-day-1, ${ratchet} gate(s) to baseline + ratchet."
echo "Next (PLAYBOOK BROWNFIELD step 2-3): wire the zero-cost gates as blocking now;"
echo "record each RATCHET count as a CI ceiling that may only fall. The diff stays greenfield."
