#!/usr/bin/env bash
# Form gate for every SKILL.md in this repo (ADR 14): a skill whose shape is
# wrong steers nothing. Per file it asserts:
#   1. frontmatter present, with exactly one single-line `description:` (no
#      block scalars — the description is the trigger surface, it must scan);
#   2. body under MAX_LINES (a skill is a rite card, not an essay — the
#      lesson of the 400-line skills surveyed 2026-07-17: nobody re-reads them);
#   3. a mandatory "## Verifiable output" section — an instruction that does
#      not demand an artifact is decoration (skill-writing doctrine, ADR 14).
# Then the ledger's two directions (ADR 17, widened 2026-07-29): every shipped
# artefact carries a row (check_coverage) and every row's cited executor still
# exists (check_executors) — an incomplete registry is worse than none.
# Ends with the negative cases: a planted malformed skill, unindexed artefacts
# and ghost executors must all be seen rejected — a gate never seen saying "no"
# is decoration (the no-cycle lesson, AGENT-LOG).
set -euo pipefail

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAX_LINES=150
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

check_skill() { # $1 = SKILL.md path; prints reasons; non-zero exit on violation
  local f="$1" ok=0 n_desc lines
  if ! head -1 "$f" | grep -qx -- '---'; then
    echo "  no frontmatter"; ok=1
  fi
  n_desc="$(grep -c '^description: ' "$f" || true)"
  if [ "$n_desc" -ne 1 ]; then
    echo "  needs exactly one 'description:' line (found $n_desc)"; ok=1
  fi
  if grep -qE '^description: *[>|]' "$f"; then
    echo "  description must be a single line (block scalar found)"; ok=1
  fi
  lines="$(wc -l < "$f")"
  if [ "$lines" -gt "$MAX_LINES" ]; then
    echo "  body over cap ($lines > $MAX_LINES lines)"; ok=1
  fi
  if ! grep -qx '## Verifiable output' "$f"; then
    echo "  missing mandatory '## Verifiable output' section"; ok=1
  fi
  return "$ok"
}

echo "==> Form gate: every SKILL.md in the repo must pass"
fail=0
while IFS= read -r f; do
  if out="$(check_skill "$f")"; then
    echo "OK   ${f#"$HARNESS_DIR"/}"
  else
    echo "FAIL ${f#"$HARNESS_DIR"/}"
    echo "$out"
    fail=1
  fi
done < <(find "$HARNESS_DIR/.claude/skills" "$HARNESS_DIR/home/skills" \
  "$HARNESS_DIR/templates" -name SKILL.md | sort)
if [ "$fail" -ne 0 ]; then
  echo "FAIL: skills above violate the form gate (ADR 14)" >&2
  exit 1
fi

echo "==> Negative case: a malformed skill must be seen rejected"
cat > "$TMP/SKILL.md" <<'EOF'
# bad fixture: no frontmatter, no description, no verifiable output
Do good things. Did you consider the edge cases?
EOF
if check_skill "$TMP/SKILL.md" > "$TMP/reasons.log"; then
  echo "FAIL: the form gate accepted a malformed skill (wired-but-blind)" >&2
  exit 1
fi
grep -q "no frontmatter" "$TMP/reasons.log" \
  || { echo "FAIL: rejection reasons not reported" >&2; cat "$TMP/reasons.log" >&2; exit 1; }

check_ledger() { # $1 = ledger path; prints reasons; non-zero exit on violation
  local f="$1" ok=0 dups bad
  dups="$(awk -F'|' '/^\| C-/ {gsub(/ /,"",$2); print $2}' "$f" | sort | uniq -d)"
  if [ -n "$dups" ]; then
    echo "  duplicate claim ids: $dups"; ok=1
  fi
  bad="$(awk -F'|' '/^\| C-/ {v=$6; sub(/^ +/,"",v);
    if (v !~ /^(adopted \((force|half-force|steer)|rejected|already have|deferred)/) print $2}' "$f")"
  if [ -n "$bad" ]; then
    echo "  verdict outside the closed set (adopted needs its force degree) on:$bad"; ok=1
  fi
  return "$ok"
}

echo "==> Absorb ledger: ids unique, verdicts from the closed set (ADR 16)"
LEDGER="$HARNESS_DIR/docs/CLAIMS.md"
test -f "$LEDGER" || { echo "FAIL: docs/CLAIMS.md missing" >&2; exit 1; }
if ! out="$(check_ledger "$LEDGER")"; then
  echo "FAIL: ledger violates its contract" >&2; echo "$out" >&2; exit 1
fi

echo "==> Negative case: a corrupt ledger must be seen rejected"
cat > "$TMP/ledger.md" <<'EOF'
| C-001 | 2026-07-17 | src | claim one | adopted | somewhere |
| C-001 | 2026-07-17 | src | claim two | maybe later | somewhere |
EOF
if check_ledger "$TMP/ledger.md" >/dev/null; then
  echo "FAIL: the ledger check accepted duplicate ids, a rogue verdict, and a degree-less adopted" >&2
  exit 1
fi

# Every enforcing artefact this repo ships must be indexed in the ledger. The
# families below are all things the harness claims to do: a selftest gate, a
# machine-layer hook, a personal rite, a repo rite, a template rite and the
# scripts a template drops into a project.
#
# Why completeness is a gate and not a habit: an artefact with no row is worse
# than an artefact with no ledger, because the next /absorb greps this file,
# finds nothing, and concludes the harness lacks the thing it already ships. A
# map covering part of its territory manufactures failed searches, and a failed
# search is not proof of absence. Instance that taught it (calendar-app,
# 2026-07-29): docs/COMPONENTS.md covered 7 of 45 shelf files. Instance here:
# home/skills/checklist/SKILL.md shipped unindexed until this glob list existed.
ARTEFACT_GLOBS=(
  "scripts/selftest*.sh"
  "home/bin/*.py"
  "home/skills/*/SKILL.md"
  ".claude/skills/*/SKILL.md"
  "templates/*/.claude/skills/*/SKILL.md"
  "templates/*/.claude/agents/*.md"
  "templates/*/scripts/*"
)

coverage_needle() { # $1 = artefact path → the string some ledger row must carry
  case "$1" in
    # SKILL.md is the same basename for every rite, so the rite IS its directory.
    */SKILL.md) printf 'skills/%s' "$(basename "$(dirname "$1")")" ;;
    *)          basename "$1" ;;
  esac
}

check_coverage() { # $1 = ledger; $2 = repo root — every shipped artefact indexed
  local f="$1" root="$2" ok=0 glob a needle stem
  for glob in "${ARTEFACT_GLOBS[@]}"; do
    for a in "$root"/$glob; do
      [ -e "$a" ] || continue
      needle="$(coverage_needle "$a")"
      grep -q -- "$needle" "$f" && continue
      # Fallback: a row may legitimately anchor an artefact to the gate that
      # proves it instead of to its own path — C-036 does that for
      # deletion-guard.mjs. Only a compound (hyphenated) stem counts as
      # evidence; a single word like "verify" appears everywhere and proves
      # nothing.
      stem="${needle%.*}"
      if [[ "$stem" == *-* ]] && grep -q -- "$stem" "$f"; then continue; fi
      echo "  artefact not indexed in the claims ledger: ${a#"$root"/}"; ok=1
    done
  done
  return "$ok"
}

check_executors() { # $1 = ledger — force/half-force rows must cite an existing executor
  local f="$1" ok=0 line id where refs r
  while IFS= read -r line; do
    id="$(awk -F'|' '{gsub(/ /,"",$2); print $2}' <<<"$line")"
    # The Where column ($7) only. The claim column is prose and names files it
    # never anchors ("AGENTS.md is canonical; CLAUDE.md/GEMINI.md are one-line
    # adapters", C-033), which a whole-line scan reads as paths and then has to
    # resolve by basename to avoid failing on them.
    where="$(awk -F'|' '{print $7}' <<<"$line")"
    refs="$(grep -oE '[A-Za-z0-9._/-]+\.(sh|py|yml|json|mjs|md)' <<<"$where" | sort -u || true)"
    if [ -z "$refs" ]; then
      echo "  force-degree row $id cites no executor file"; ok=1; continue
    fi
    while IFS= read -r r; do
      case "$r" in
        # A ref that carries a path is checked as that exact path: basename
        # matching keeps passing after the file has moved, which is the rot.
        */*)
          [ -e "$HARNESS_DIR/$r" ] \
            || { echo "  row $id cites a ghost executor: $r"; ok=1; } ;;
        *)
          [ -n "$(find "$HARNESS_DIR/scripts" "$HARNESS_DIR/home/bin" "$HARNESS_DIR/.github" \
                -name "$r" 2>/dev/null | head -1)" ] \
            || { echo "  row $id cites a ghost executor: $r"; ok=1; } ;;
      esac
    done <<<"$refs"
  done < <(grep -E '^\| C-[0-9]+ .*\| *adopted \((force|half-force)' "$f")
  return "$ok"
}

echo "==> Claims coverage: every shipped artefact indexed; force rows cite real executors (ADR 17)"
if ! out="$(check_coverage "$LEDGER" "$HARNESS_DIR")"; then
  echo "FAIL: unindexed artefact — a guarantee the ledger does not know about" >&2; echo "$out" >&2; exit 1
fi
if ! out="$(check_executors "$LEDGER")"; then
  echo "FAIL: force-degree claim without a living executor (prompt-and-pray)" >&2; echo "$out" >&2; exit 1
fi

echo "==> Negative cases: unindexed artefacts (two families) and ghost executors must be seen rejected"
mkdir -p "$TMP/root/scripts" "$TMP/root/home/skills/ghost-rite"
: > "$TMP/root/scripts/selftest-ghost.sh"
: > "$TMP/root/home/skills/ghost-rite/SKILL.md"
out="$(check_coverage "$LEDGER" "$TMP/root" || true)"
grep -q "selftest-ghost.sh" <<<"$out" \
  || { echo "FAIL: coverage check accepted an unindexed gate" >&2; exit 1; }
grep -q "ghost-rite" <<<"$out" \
  || { echo "FAIL: coverage check accepted an unindexed rite — the family it was blind to until 2026-07-29" >&2; exit 1; }
printf '| C-900 | 2026-07-17 | src | fake gate | adopted (force) | ghost-gate.sh |\n' > "$TMP/ghost.md"
if check_executors "$TMP/ghost.md" >/dev/null; then
  echo "FAIL: executor check accepted a ghost executor" >&2; exit 1
fi
printf '| C-901 | 2026-07-17 | src | moved gate | adopted (force) | `scripts/gone/selftest.sh` |\n' > "$TMP/moved.md"
if check_executors "$TMP/moved.md" >/dev/null; then
  echo "FAIL: executor check accepted a path that no longer exists (basename matching hid the move)" >&2; exit 1
fi

echo "==> Enforcement mix (adopted claims)"
awk -F'|' '/^\| C-/ {v=$6; sub(/^ +/,"",v);
  if (v ~ /^adopted \(force/) f++;
  else if (v ~ /^adopted \(half-force/) h++;
  else if (v ~ /^adopted \(steer/) s++}
  END {printf "    force: %d · half-force: %d · steer: %d\n", f+0, h+0, s+0}' "$LEDGER"

echo "SELFTEST-SKILLS OK — form gate green, ledger contract + coverage + executors hold, every gate seen rejecting a planted violation."
