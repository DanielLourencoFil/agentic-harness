#!/usr/bin/env bash
# Brownfield baseline: run EVERY harness gate once against the untouched repo and
# classify each by its result. Read-only - nothing here changes your code. This is the
# operational half of the brownfield rite's "snapshot current violation counts"
# (PLAYBOOK BROWNFIELD step 3): a gate that PASSES today is wirable as blocking now
# (zero-cost-day-1); a gate that FAILS becomes a ratchet whose count may only fall.
#
# The gate list here is the FULL set the harness ships (types, lint, clones, stranded,
# mutation), so no gate is silently left out of the baseline - a gate never snapshotted
# is a gate that never gets a ratchet, i.e. permanently ungated in brownfield.
#
# A real brownfield repo names its gates differently (or lacks some). Map each gate to
# THIS repo's real command - or mark it absent - in an optional .harness/gates.sh, which
# this script sources over the ts-base defaults below (ADR 62). One GATE_<name> per line:
#   GATE_types="pnpm type-check"   # present under another name
#   GATE_stranded=""               # absent: this repo has no stranded gate yet
# With no such file, the ts-base defaults apply and the ts-base selftest is unchanged.
#
# A partially-adopted repo has gates already WIRED as a ratchet, sitting at a pinned
# ceiling: they PASS but are not clean (they carry debt). List them in RATCHETED_GATES so
# the baseline reads them "already-ratcheted", not "zero-cost-day-1 wire it today" - a
# passing ratchet is not a clean gate, and calling it zero-cost false-cleans the repo (ADR 63):
#   RATCHETED_GATES="lint clones"  # already wired here, at their ceilings
#
# Mutation runs Stryker over the whole repo and may take minutes on a large codebase;
# it is deliberately last. This script never fails the build: the report is the product.
set -u

# ts-base defaults; overridden per-repo by .harness/gates.sh (empty string = absent).
GATE_types="pnpm typecheck"
GATE_lint="pnpm lint"
GATE_clones="pnpm clones"
GATE_stranded="pnpm stranded"
GATE_mutation="pnpm mutants"
# Gates already wired as a ratchet in THIS repo (space-separated); a virgin repo has none.
RATCHETED_GATES=""
if [ -f .harness/gates.sh ]; then
  # shellcheck disable=SC1091
  . .harness/gates.sh
fi

zero_cost=0
already=0
ratchet=0
absent=0
notconf=0

is_ratcheted() { case " $RATCHETED_GATES " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }

run_gate() {
  local name="$1"
  local var="GATE_${name}"
  local cmd="${!var-}"
  local log="baseline-${name}.log"
  if [ -z "$cmd" ]; then
    printf '  %-10s  absent            (this repo has no %s gate - a candidate to add later)\n' "$name" "$name"
    absent=$((absent + 1))
    return
  fi
  if $cmd > "$log" 2>&1; then
    if is_ratcheted "$name"; then
      printf '  %-10s  already-ratcheted (wired at its pinned ceiling via `%s`: carries debt, not clean - keep it falling)\n' "$name" "$cmd"
      already=$((already + 1))
    else
      printf '  %-10s  zero-cost-day-1   (passes clean now via `%s`: wire it as blocking today)\n' "$name" "$cmd"
      zero_cost=$((zero_cost + 1))
    fi
  elif grep -qiE 'missing script|cannot find module|no such file|command ".*" not found' "$log"; then
    printf '  %-10s  not-configured    (`%s` did not resolve: fix the command in .harness/gates.sh)\n' "$name" "$cmd"
    notconf=$((notconf + 1))
  else
    printf '  %-10s  RATCHET           (fails now via `%s`: record the count in %s as a ceiling that may only fall)\n' "$name" "$cmd" "$log"
    ratchet=$((ratchet + 1))
  fi
}

echo "Brownfield baseline - read-only. Nothing here changes your code."
echo "Run once on the untouched repo. Each gate's result IS its day-1 classification."
echo
run_gate types
run_gate lint
run_gate clones
run_gate stranded
run_gate mutation
echo
echo "Summary: ${zero_cost} zero-cost-day-1, ${already} already-ratcheted, ${ratchet} to ratchet, ${absent} absent, ${notconf} not-configured."
echo "Next (PLAYBOOK BROWNFIELD step 2-3): wire the zero-cost gates as blocking now; record each"
echo "RATCHET count as a CI ceiling that may only fall; confirm each already-ratcheted gate's ceiling"
echo "can still only fall (it is debt, not clean); treat 'absent' as a gate to add later. The diff stays greenfield."
