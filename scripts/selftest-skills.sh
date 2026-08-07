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
  local f="$1" ok=0 dups bad malformed shape
  dups="$(awk -F'|' '/^\| C-/ {gsub(/ /,"",$2); print $2}' "$f" | sort | uniq -d)"
  if [ -n "$dups" ]; then
    echo "  duplicate claim ids: $dups"; ok=1
  fi
  # Ids are C-NNN and nothing else. Nothing enforced the format before, so an
  # inserted `C-100a` was accepted here AND skipped by check_executors, whose
  # filter needs digits then a space — a row that no gate ever looked at
  # (audit 2026-07-30).
  malformed="$(awk -F'|' '/^\| C-/ {gsub(/ /,"",$2);
    if ($2 !~ /^C-[0-9][0-9][0-9]$/) print " " $2}' "$f")"
  if [ -n "$malformed" ]; then
    echo "  claim id is not C-NNN on:$malformed"; ok=1
  fi
  # Every check here reads columns positionally, so a stray `|` inside a cell
  # shifts the verdict and Where of that row and every check silently reads the
  # wrong field. Flagged as a lead by audit 2026-07-30 (no such row existed);
  # this is the guard that keeps it that way.
  shape="$(awk -F'|' '/^\| C-/ {if (NF != 8) print " " $2 " has " NF-2 " cells, expected 6"}' "$f")"
  if [ -n "$shape" ]; then
    echo '  row shape broken (a pipe inside a cell shifts every column):'"$shape"; ok=1
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
printf '| C-100a | 2026-07-30 | src | inserted row | adopted (force) | ghost-gate.sh |\n' > "$TMP/badid.md"
out="$(check_ledger "$TMP/badid.md" || true)"
grep -q "not C-NNN" <<<"$out" \
  || { echo "FAIL: a non-numeric id was accepted, and no other gate looks at that row" >&2; exit 1; }
printf '| C-112 | 2026-07-30 | src | a claim naming the "Write|Edit" matcher | adopted (force) | selftest.sh |\n' > "$TMP/shape.md"
out="$(check_ledger "$TMP/shape.md" || true)"
grep -q "row shape broken" <<<"$out" \
  || { echo "FAIL: a pipe inside a cell shifted every column and no gate noticed" >&2; exit 1; }

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
  # Added 2026-07-30: the audit found the comment above promised "every
  # enforcing artefact" while the list watched none of these — the hook chain,
  # the lint cage, the CI workflow, the budget file, the permission baselines.
  "templates/*/.husky/*"
  "templates/*/eslint.config.*"
  "templates/*/.clonebudget.json"
  ".github/workflows/*.yml"
  "home/claude/settings.json"
  ".claude/settings.json"
)

artefact_paths() { # $1 = repo root — every shipped artefact, one per line
  local root="$1" glob a
  for glob in "${ARTEFACT_GLOBS[@]}"; do
    for a in "$root"/$glob; do
      [ -e "$a" ] && printf '%s\n' "${a#"$root"/}"
    done
  done
}

# Basenames this repo ships more than once. Computed from the REAL repo, never
# from the root under test: in a two-file fixture directory every basename looks
# unique, which let a planted `home/skills/ghost-rite/SKILL.md` be anchored by
# any other rite's row. An ambiguity set is only meaningful against the whole
# shipped set.
AMBIGUOUS_BASENAMES=""

check_coverage() { # $1 = ledger; $2 = repo root — every shipped artefact indexed
  local f="$1" root="$2" ok=0 a base index ambiguous
  # Only the claim ($5) and Where ($7) columns count as an index. The Source
  # column ($3) names external material — C-098 cites the calendar-app's own
  # `clone-budget-check.js` — and letting provenance stand in for a claim marks
  # our artefact indexed because someone else's file has a similar name. That is
  # not hypothetical: it is the first thing this gate got wrong, on 2026-07-29,
  # and it passed green while blind, which is the failure mode it exists to stop.
  index="$(awk -F'|' '/^\| C-/ {print $5 "|" $7}' "$f")"
  # Basenames shared by two or more shipped artefacts. Matching those would let
  # one row cover a file it never meant: SKILL.md is eight rites, settings.json
  # is two permission baselines. For these the full repo-relative path is the
  # only acceptable anchor.
  ambiguous="$AMBIGUOUS_BASENAMES"
  while IFS= read -r a; do
    [ -n "$a" ] || continue
    # Whole-token, literal match. Substring matching made `skills/feat` satisfy
    # the row for `skills/feature`, and a hyphenated-stem fallback made a new
    # `clone-budget-check.sh` inherit the row of the `.mjs` (audit 2026-07-30).
    grep -qwF -- "$a" <<<"$index" && continue
    base="$(basename "$a")"
    if ! grep -qxF -- "$base" <<<"$ambiguous" && grep -qwF -- "$base" <<<"$index"; then
      continue
    fi
    echo "  artefact not indexed in the claims ledger: $a"; ok=1
  done < <(artefact_paths "$root")
  return "$ok"
}

# A file that can be executed by a gate. A force claim satisfied by a `.md` is
# prompt-and-pray wearing the word "force" — which is what the failure message
# below accuses others of (audit 2026-07-30). Prose may anchor a HALF-force row,
# where the semantic half is admittedly a rite, never a force one.
EXECUTABLE_EXT='sh|py|mjs|cjs|js|ts|yml|yaml'
ANCHOR_EXT="$EXECUTABLE_EXT|json|toml|md"

check_executors() { # $1 = ledger — force/half-force rows must cite an existing executor
  local f="$1" ok=0 line id degree where refs r found_exec superseded
  # Rows are append-only, so a row whose anchor turned out wrong is corrected by
  # appending one that says "supersedes C-NNN" (the ledger's own rule; C-093 does
  # this to C-058). The superseded row keeps its text as the dated snapshot it
  # is, and stops being held to the executor contract — the replacement carries
  # that now.
  superseded="$(grep -oE 'supersedes C-[0-9]{3}' "$f" | grep -oE 'C-[0-9]{3}' | sort -u)"
  while IFS='|' read -r _ id degree where; do
    id="${id// /}"
    grep -qxF -- "$id" <<<"$superseded" && continue
    refs="$(grep -oE "[A-Za-z0-9._/~-]+\.($ANCHOR_EXT)" <<<"$where" | sort -u || true)"
    if [ -z "$refs" ]; then
      echo "  force-degree row $id cites no executor file"; ok=1; continue
    fi
    found_exec=0
    while IFS= read -r r; do
      case "$r" in
        # A home path is machine-dependent and unverifiable from the repo. The
        # old char class simply dropped the `~`, so `~/.claude/settings.json`
        # was silently validated against the repo's own `.claude/settings.json`.
        '~'*)
          echo "  row $id anchors a home path ($r) — use the repo-relative path"; ok=1; continue ;;
        # A ref that carries a path is checked as that exact path: basename
        # matching keeps passing after the file has moved, which is the rot.
        */*)
          [ -e "$HARNESS_DIR/$r" ] \
            || { echo "  row $id cites a ghost executor: $r"; ok=1; continue; } ;;
        *)
          # Repo-wide: restricting the search to scripts/, home/bin/ and .github/
          # reported a real file at the repo root as a ghost.
          [ -n "$(find "$HARNESS_DIR" -name .git -prune -o -name "$r" -print 2>/dev/null | head -1)" ] \
            || { echo "  row $id cites a ghost executor: $r"; ok=1; continue; } ;;
      esac
      [[ "$r" =~ \.($EXECUTABLE_EXT)$ ]] && found_exec=1
    done <<<"$refs"
    if [ "$found_exec" -eq 0 ] && [[ "$degree" == *"(force"* ]]; then
      echo "  row $id is force but cites no executable gate, only prose/config"; ok=1
    fi
    # Verdict read from its own column. Matching the whole line made a *rejected*
    # row executor-checked whenever its claim text happened to contain
    # "adopted (force)" (audit 2026-07-30).
  done < <(awk -F'|' '/^\| C-/ {v=$6; sub(/^ +/,"",v);
    if (v ~ /^adopted \((force|half-force)/) print "|" $2 "|" $6 "|" $7}' "$f")
  return "$ok"
}

AMBIGUOUS_BASENAMES="$(artefact_paths "$HARNESS_DIR" | xargs -r -n1 basename | sort | uniq -d)"

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
# An artefact named ONLY in a row's Source column is not indexed: provenance of
# somebody else's file is not a claim about ours. This case exists because the
# gate got it wrong on 2026-07-29 and passed green while blind.
mkdir -p "$TMP/root-src/templates/x/scripts"
: > "$TMP/root-src/templates/x/scripts/borrowed-tool.mjs"
printf '| C-902 | 2026-07-29 | external repo `scripts/borrowed-tool.mjs` (checked today) | a claim we did not adopt | rejected: n/a | ADR n |\n' \
  > "$TMP/source-only.md"
out="$(check_coverage "$TMP/source-only.md" "$TMP/root-src" || true)"
grep -q "borrowed-tool.mjs" <<<"$out" \
  || { echo "FAIL: a Source-column mention passed as an index (provenance is not a claim)" >&2; exit 1; }
printf '| C-900 | 2026-07-17 | src | fake gate | adopted (force) | ghost-gate.sh |\n' > "$TMP/ghost.md"
if check_executors "$TMP/ghost.md" >/dev/null; then
  echo "FAIL: executor check accepted a ghost executor" >&2; exit 1
fi
printf '| C-901 | 2026-07-17 | src | moved gate | adopted (force) | `scripts/gone/selftest.sh` |\n' > "$TMP/moved.md"
if check_executors "$TMP/moved.md" >/dev/null; then
  echo "FAIL: executor check accepted a path that no longer exists (basename matching hid the move)" >&2; exit 1
fi

# Everything below was found by the fresh-context audit of 2026-07-30. Each case
# passes green against the code as it shipped the day before; that is the point.
echo "==> Negative cases: name collisions must not stand in for an index (audit 2026-07-30)"
mkdir -p "$TMP/collide/home/skills/audit" "$TMP/collide/.claude/skills/feat" \
  "$TMP/collide/templates/x/scripts"
: > "$TMP/collide/home/skills/audit/SKILL.md"
: > "$TMP/collide/.claude/skills/feat/SKILL.md"
: > "$TMP/collide/templates/x/scripts/clone-budget-check.sh"
out="$(check_coverage "$LEDGER" "$TMP/collide" || true)"
grep -q "home/skills/audit/SKILL.md" <<<"$out" \
  || { echo "FAIL: a rite reusing another layer's directory name inherited its row" >&2; exit 1; }
grep -q ".claude/skills/feat/SKILL.md" <<<"$out" \
  || { echo "FAIL: a rite whose name is a PREFIX of an indexed one passed (substring match)" >&2; exit 1; }
grep -q "clone-budget-check.sh" <<<"$out" \
  || { echo "FAIL: same stem, different extension inherited the .mjs row (stem fallback)" >&2; exit 1; }

echo "==> Negative cases: a force row must cite something executable (audit 2026-07-30)"
printf '| C-903 | 2026-07-30 | src | doc-only force claim | adopted (force) | `docs/DECISIONS.md` ADR 27 |\n' > "$TMP/prose.md"
out="$(check_executors "$TMP/prose.md" || true)"
grep -q "cites no executable gate" <<<"$out" \
  || { echo "FAIL: prose satisfied a force claim — that IS prompt-and-pray" >&2; exit 1; }
printf '| C-904 | 2026-07-30 | src | home-path anchor | adopted (force) | `~/.claude/settings.json` |\n' > "$TMP/home.md"
out="$(check_executors "$TMP/home.md" || true)"
grep -q "anchors a home path" <<<"$out" \
  || { echo "FAIL: a ~/ anchor was validated against the repo's own copy" >&2; exit 1; }
printf '| C-905 | 2026-07-30 | src | ghost with an unlisted extension | adopted (force) | `scripts/selftest.sh` + `templates/vue-starter/ghost.ts` |\n' > "$TMP/ext.md"
out="$(check_executors "$TMP/ext.md" || true)"
grep -q "ghost.ts" <<<"$out" \
  || { echo "FAIL: a ghost with an unlisted extension was invisible beside a real file" >&2; exit 1; }
# The mirror case: the check must not fire on rows it has no business reading.
printf '| C-906 | 2026-07-30 | src | prose mentioning adopted (force) elsewhere | rejected: n/a | ghost-gate.sh |\n' > "$TMP/rejected.md"
if ! check_executors "$TMP/rejected.md" >/dev/null; then
  echo "FAIL: a REJECTED row was executor-checked because its claim text said 'adopted (force)'" >&2; exit 1
fi
# A superseded row keeps its snapshot text and stops being held to the contract.
printf '| C-907 | 2026-07-30 | src | wrong anchor | adopted (force) | `docs/DECISIONS.md` |\n| C-908 | 2026-07-30 | src (supersedes C-907) | corrected | adopted (force) | `scripts/selftest.sh` |\n' > "$TMP/sup.md"
if ! check_executors "$TMP/sup.md" >/dev/null; then
  echo "FAIL: a row explicitly superseded by a later one was still held to the executor contract" >&2; exit 1
fi

# Docs rot because nobody forces them to match reality. The verify script is the
# one claim that drifts on every new gate (clones, stranded, mutation each broke
# it), so it gets a gate: every step the template's verify actually runs must be
# named in the docs that enumerate it. A step added and undocumented fails CI —
# the harness's own thesis (wire what you can) applied to its own docs (ADR 41).
check_verify_docs() { # $1 = harness dir
  local dir="$1" ok=0 verify steps step doc line
  verify="$(grep '"verify"' "$dir/templates/ts-base/package.snippet.json")"
  # The step names are the words after each `pnpm`, minus `verify` itself.
  steps="$(grep -oE 'pnpm [a-z:]+' <<<"$verify" | sed 's/pnpm //' | grep -vx verify)"
  # Docs that ENUMERATE the verify contents in script-name form. A doc that only
  # says "run verify" is not on this list; these two spell the steps out.
  for doc in "PLAYBOOK.md" "templates/ts-base/README.md"; do
    line="$(grep -iE 'verify.*(typecheck|=)' "$dir/$doc" | head -1)"
    while IFS= read -r step; do
      [ -n "$step" ] || continue
      grep -qw -- "$step" <<<"$line" \
        || { echo "  $doc names the verify steps but omits '$step' (docs rot: a gate the docs do not know verify runs)"; ok=1; }
    done <<<"$steps"
  done
  return "$ok"
}

echo "==> Docs-match-reality: every verify step the template runs is named in the docs (ADR 41)"
if ! out="$(check_verify_docs "$HARNESS_DIR")"; then
  echo "FAIL: a verify step drifted out of the docs — the rot the harness exists to prevent" >&2
  echo "$out" >&2; exit 1
fi
echo "==> Negative case: a verify step missing from a doc must be seen rejected"
mkdir -p "$TMP/rot/templates/ts-base"
cp "$HARNESS_DIR/templates/ts-base/package.snippet.json" "$TMP/rot/templates/ts-base/"
# A doc that names typecheck/lint but omits a real step (stranded) must fail.
printf '`verify` = typecheck + lint + test\n' > "$TMP/rot/PLAYBOOK.md"
printf 'verify (typecheck + lint + test)\n' > "$TMP/rot/templates/ts-base/README.md"
out="$(check_verify_docs "$TMP/rot" || true)"
grep -q "omits" <<<"$out" \
  || { echo "FAIL: a verify step missing from the docs was not caught (the check is blind)" >&2; exit 1; }

echo "==> Enforcement mix (adopted claims)"
awk -F'|' '/^\| C-/ {v=$6; sub(/^ +/,"",v);
  if (v ~ /^adopted \(force/) f++;
  else if (v ~ /^adopted \(half-force/) h++;
  else if (v ~ /^adopted \(steer/) s++}
  END {printf "    force: %d · half-force: %d · steer: %d\n", f+0, h+0, s+0}' "$LEDGER"

echo "SELFTEST-SKILLS OK — form gate green, ledger contract + coverage + executors hold, every gate seen rejecting a planted violation."
