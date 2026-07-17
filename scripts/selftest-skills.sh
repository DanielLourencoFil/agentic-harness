#!/usr/bin/env bash
# Form gate for every SKILL.md in this repo (ADR 14): a skill whose shape is
# wrong steers nothing. Per file it asserts:
#   1. frontmatter present, with exactly one single-line `description:` (no
#      block scalars — the description is the trigger surface, it must scan);
#   2. body under MAX_LINES (a skill is a rite card, not an essay — the
#      lesson of the 400-line skills surveyed 2026-07-17: nobody re-reads them);
#   3. a mandatory "## Verifiable output" section — an instruction that does
#      not demand an artifact is decoration (skill-writing doctrine, ADR 14).
# Ends with the negative case: a planted malformed skill must be seen rejected —
# a gate never seen saying "no" is decoration (the no-cycle lesson, AGENT-LOG).
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

echo "SELFTEST-SKILLS OK — all repo skills pass the form gate; the gate rejects a planted violation."
