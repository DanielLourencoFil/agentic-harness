#!/usr/bin/env bash
# Pipe-tests the home/ layer hooks in isolation (no Claude required) and asserts
# they are actually wired in home/claude/settings.json — a hook that is right but
# unreferenced is decoration (same lesson as the template selftest: a gate must
# be seen saying "no"). Covers, per ADR 10 and the secret-hygiene pack:
#   1. write-containment denies writes whose REAL path escapes the project root
#      (plain outside, `../`, symlink) and allows root/memory/plans/scratchpad;
#   1b. that allowlist stays 4 entries long and both prose copies (docstring,
#      denial message) still name all four — an exemption may not outlive the
#      sentence that justifies it, and the list may not grow quietly (ADR 13/26);
#   2. secret-scan blocks prompts carrying secret-shaped values;
#   3. env-dump-guard denies commands that would dump secrets into context;
#   4. deliberation-nudge reminds on deliberation markers (nudge, never block)
#      and stays silent on plain work prompts (ADR 19);
#   5. recommendation-anchor blocks an answer that recommends without declaring
#      what verified it, accepts an honest "não verificado", stays silent on
#      plain work, and never blocks twice on one turn (ADR 30).
set -euo pipefail

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$HARNESS_DIR/home/bin"
SETTINGS="$HARNESS_DIR/home/claude/settings.json"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

ROOT="$TMP/proj"
FAKEHOME="$TMP/home"
mkdir -p "$ROOT" "$TMP/outside" "$FAKEHOME/.claude/projects/some-proj/memory" \
  "$FAKEHOME/.claude/plans" "$FAKEHOME/Dev/organizer"
ln -s "$TMP/outside" "$ROOT/escape-link"

containment() { # $1 = payload json; stdout = hook output
  printf '%s' "$1" | env HOME="$FAKEHOME" CLAUDE_PROJECT_DIR="$ROOT" \
    python3 "$BIN/write-containment.py"
}
expect_deny() { # $1 = case name; $2 = hook output
  grep -q '"permissionDecision": "deny"' <<<"$2" \
    || { echo "FAIL: $1 was NOT denied" >&2; exit 1; }
}
expect_allow() { # $1 = case name; $2 = hook output
  if grep -q 'permissionDecision' <<<"$2"; then
    echo "FAIL: $1 was denied but must pass" >&2; exit 1
  fi
}

echo "==> write-containment: a write outside the project root must be seen blocked (ADR 10)"
expect_deny  "write outside root" \
  "$(containment '{"tool_name":"Write","cwd":"'"$ROOT"'","tool_input":{"file_path":"'"$TMP"'/outside/x.txt"}}')"
expect_deny  "write escaping via ../" \
  "$(containment '{"tool_name":"Write","cwd":"'"$ROOT"'","tool_input":{"file_path":"'"$ROOT"'/../outside/y.txt"}}')"
expect_deny  "write through an in-root symlink pointing outside" \
  "$(containment '{"tool_name":"Write","cwd":"'"$ROOT"'","tool_input":{"file_path":"'"$ROOT"'/escape-link/z.txt"}}')"
expect_deny  "notebook write outside root" \
  "$(containment '{"tool_name":"NotebookEdit","cwd":"'"$ROOT"'","tool_input":{"notebook_path":"'"$TMP"'/outside/n.ipynb"}}')"
expect_allow "write inside root" \
  "$(containment '{"tool_name":"Write","cwd":"'"$ROOT"'","tool_input":{"file_path":"'"$ROOT"'/src/ok.ts"}}')"
expect_allow "write to agent memory (named allowlist)" \
  "$(containment '{"tool_name":"Write","cwd":"'"$ROOT"'","tool_input":{"file_path":"'"$FAKEHOME"'/.claude/projects/some-proj/memory/note.md"}}')"
expect_allow "write to the plan-mode draft dir (ADR 26)" \
  "$(containment '{"tool_name":"Write","cwd":"'"$ROOT"'","tool_input":{"file_path":"'"$FAKEHOME"'/.claude/plans/draft.md"}}')"
expect_allow "write to session scratchpad (named allowlist)" \
  "$(containment '{"tool_name":"Write","cwd":"'"$ROOT"'","tool_input":{"file_path":"/tmp/claude-selftest/scratchpad/tmp.txt"}}')"
expect_allow "write to the cross-project data repo (backlog rite, ADR 13)" \
  "$(containment '{"tool_name":"Write","cwd":"'"$ROOT"'","tool_input":{"file_path":"'"$FAKEHOME"'/Dev/organizer/BACKLOG.md"}}')"

# Near-miss denials: one step outside each allowlist entry must still be denied.
# This is the load-bearing half of the allowlist check, and the only half a
# refactor of the Python cannot dodge — a widened target (~/Dev/organizer/ ->
# ~/Dev/) or a brand-new exemption changes BEHAVIOUR, whatever the source looks
# like. Audit 2026-07-30 found both slipping past a source-shape check alone.
echo "==> write-containment: one step outside each allowlist entry must still be denied"
expect_deny  "a sibling project under ~/Dev (the organizer entry must not widen)" \
  "$(containment '{"tool_name":"Write","cwd":"'"$ROOT"'","tool_input":{"file_path":"'"$FAKEHOME"'/Dev/other-project/steal.md"}}')"
expect_deny  "another ~/.claude subdir (memory and plans must not widen)" \
  "$(containment '{"tool_name":"Write","cwd":"'"$ROOT"'","tool_input":{"file_path":"'"$FAKEHOME"'/.claude/other/x.md"}}')"
expect_deny  "a /tmp dir that is not a session scratchpad" \
  "$(containment '{"tool_name":"Write","cwd":"'"$ROOT"'","tool_input":{"file_path":"/tmp/notclaude/x.txt"}}')"
expect_deny  "a system path (no exemption may be added quietly)" \
  "$(containment '{"tool_name":"Write","cwd":"'"$ROOT"'","tool_input":{"file_path":"/etc/cron.d/pwn"}}')"

check_allowlist() { # $1 = write-containment.py — the named list must stay named and short
  local f="$1" ok=0 n docstring reason entry
  # The allowlist lives three times in that file: the code that builds it, the
  # module docstring, and the denial message the human reads. ADR 26 added the
  # 4th entry and had to hand-fix both prose copies, which "would otherwise
  # lie". A list kept in three places rots in two of them.
  #
  # Occurrences, not lines: `grep -c` counts matching LINES, so two conditions
  # written on one line read as one exemption. Audit 2026-07-30 planted exactly
  # that and the whole selftest stayed green while writes to /etc/ were allowed.
  n="$(grep -oE 'or (under\(real, |real\.startswith\()' "$f" | wc -l)"
  if [ "$n" -ne 4 ]; then
    echo "  the allowlist has $n exemptions, expected 4"
    echo "  (the owner closed this list on 2026-07-17; ADR 13/26. Adding one is his"
    echo "   signed act: bump this count, both prose copies, and add an allow-case.)"
    ok=1
  fi
  docstring="$(awk '/"""/{n++; if(n==2) exit} n' "$f")"
  # Bounded at the closing paren of the reason expression. Running to EOF let a
  # trailing comment mentioning the four paths satisfy the check while the real
  # message named none of them (audit 2026-07-30).
  reason="$(awk '/permissionDecisionReason/{p=1} p && /^ *\),?$/{exit} p' "$f")"
  for entry in '~/.claude/projects/' '~/.claude/plans/' '/tmp/claude-*' '~/Dev/organizer/'; do
    grep -qF -- "$entry" <<<"$docstring" \
      || { echo "  docstring does not name the allowlist entry $entry"; ok=1; }
    grep -qF -- "$entry" <<<"$reason" \
      || { echo "  the denial message does not name the allowlist entry $entry"; ok=1; }
  done
  return "$ok"
}

echo "==> write-containment: the allowlist stays short and both prose copies name it (ADR 13/26)"
if ! out="$(check_allowlist "$BIN/write-containment.py")"; then
  echo "FAIL: the containment allowlist and its prose disagree" >&2; echo "$out" >&2; exit 1
fi

mutate() { # $1 = sed script; $2 = output path — a fixture that did not change is a dead test
  sed "$1" "$BIN/write-containment.py" > "$2"
  if cmp -s "$BIN/write-containment.py" "$2"; then
    echo "FAIL: fixture unchanged — the sed anchor no longer matches the source," >&2
    echo "      so this negative case proves nothing. Re-anchor it: $1" >&2
    exit 1
  fi
}

echo "==> Negative cases: a grown allowlist (new line OR same line) and a lying prose copy must be rejected"
mutate 's|^    or under(real, organizer)$|    or under(real, organizer)\n    or under(real, anywhere)|' "$TMP/grown.py"
out="$(check_allowlist "$TMP/grown.py" || true)"
grep -q "expected 4" <<<"$out" \
  || { echo "FAIL: a 5th exemption on a new line landed without the gate saying no" >&2; exit 1; }
mutate 's|^    or under(real, plans_dir)$|    or under(real, plans_dir) or real.startswith("/etc/")|' "$TMP/inline.py"
out="$(check_allowlist "$TMP/inline.py" || true)"
grep -q "expected 4" <<<"$out" \
  || { echo "FAIL: a 5th exemption appended to an EXISTING line was invisible (audit 2026-07-30)" >&2; exit 1; }
mutate 's|rascunho do plan mode (~/.claude/plans/)|rascunho do plan mode|' "$TMP/lying.py"
out="$(check_allowlist "$TMP/lying.py" || true)"
grep -q "denial message does not name" <<<"$out" \
  || { echo "FAIL: the denial message dropped an entry and the gate did not notice" >&2; exit 1; }
mutate 's|^"""write-containment.*$|"""write-containment: PreToolUse gate.\n\nSee the code.\n"""\n_unused = """|' "$TMP/mute.py"
out="$(check_allowlist "$TMP/mute.py" || true)"
grep -q "docstring does not name" <<<"$out" \
  || { echo "FAIL: a gutted docstring passed the prose check" >&2; exit 1; }

echo "==> secret-scan: secret-shaped prompts must be blocked, benign ones must pass"
fake_key="sk-AAAAAAAAAAAAAAAAAAAA" # fixture, not a credential
out="$(printf '{"prompt":"use %s please"}' "$fake_key" | python3 "$BIN/secret-scan.py")"
grep -q '"decision": "block"' <<<"$out" || { echo "FAIL: sk- key not blocked" >&2; exit 1; }
out="$(printf '{"prompt":"connect to postgres://user:hunter2@db.local/x"}' | python3 "$BIN/secret-scan.py")"
grep -q '"decision": "block"' <<<"$out" || { echo "FAIL: DB URL with password not blocked" >&2; exit 1; }
out="$(printf '{"prompt":"refactor the parser, please"}' | python3 "$BIN/secret-scan.py")"
test -z "$out" || { echo "FAIL: benign prompt was blocked" >&2; exit 1; }

echo "==> env-dump-guard: dumping commands must be denied, working ones must pass"
out="$(printf '{"tool_input":{"command":"printenv"}}' | python3 "$BIN/env-dump-guard.py")"
grep -q '"permissionDecision": "deny"' <<<"$out" || { echo "FAIL: printenv not denied" >&2; exit 1; }
out="$(printf '{"tool_input":{"command":"cat .env"}}' | python3 "$BIN/env-dump-guard.py")"
grep -q '"permissionDecision": "deny"' <<<"$out" || { echo "FAIL: cat .env not denied" >&2; exit 1; }
out="$(printf '{"tool_input":{"command":"railway variables --set \\"KEY=$(true)\\""}}' | python3 "$BIN/env-dump-guard.py")"
test -z "$out" || { echo "FAIL: railway --set (the sanctioned flow) was denied" >&2; exit 1; }
out="$(printf '{"tool_input":{"command":"echo hello"}}' | python3 "$BIN/env-dump-guard.py")"
test -z "$out" || { echo "FAIL: harmless command was denied" >&2; exit 1; }

echo "==> deliberation-nudge: markers must nudge, plain work prompts must pass silent"
out="$(printf '{"prompt":"considerando o ledger, isso faz sentido?"}' | python3 "$BIN/deliberation-nudge.py")"
grep -q "deliberation-nudge" <<<"$out" || { echo "FAIL: deliberation marker did not nudge" >&2; exit 1; }
out="$(printf '{"prompt":"e se movermos o gate para o CI?"}' | python3 "$BIN/deliberation-nudge.py")"
grep -q "deliberation-nudge" <<<"$out" || { echo "FAIL: 'e se' marker did not nudge" >&2; exit 1; }
out="$(printf '{"prompt":"quero que analise essa repo"}' | python3 "$BIN/deliberation-nudge.py")"
grep -q "deliberation-nudge" <<<"$out" || { echo "FAIL: 'analise' marker did not nudge (the 2026-07-19 real miss)" >&2; exit 1; }
out="$(printf '{"prompt":"implementa o item 3 do plano aprovado"}' | python3 "$BIN/deliberation-nudge.py")"
test -z "$out" || { echo "FAIL: explicit go prompt was nudged" >&2; exit 1; }
out="$(printf '{"prompt":"corrige o teste vermelho no CI e faz push"}' | python3 "$BIN/deliberation-nudge.py")"
test -z "$out" || { echo "FAIL: plain work prompt was nudged" >&2; exit 1; }

echo "==> audit-reminder: a real gh pr create must nudge, everything else silent"
out="$(printf '{"tool_input":{"command":"gh pr create --title x --body y"}}' | python3 "$BIN/audit-reminder.py")"
grep -q "audit-reminder" <<<"$out" || { echo "FAIL: gh pr create did not nudge" >&2; exit 1; }
out="$(printf '{"tool_input":{"command":"git push && gh pr create --title x"}}' | python3 "$BIN/audit-reminder.py")"
grep -q "audit-reminder" <<<"$out" || { echo "FAIL: push && gh pr create did not nudge" >&2; exit 1; }
out="$(printf '{"tool_input":{"command":"gh pr view 12"}}' | python3 "$BIN/audit-reminder.py")"
test -z "$out" || { echo "FAIL: gh pr view was nudged (over-fire)" >&2; exit 1; }
out="$(printf '{"tool_input":{"command":"git commit -m wip"}}' | python3 "$BIN/audit-reminder.py")"
test -z "$out" || { echo "FAIL: git commit was nudged (over-fire on the wrong boundary)" >&2; exit 1; }
out="$(printf '{"tool_input":{"command":"echo mentioning gh pr create in prose"}}' | python3 "$BIN/audit-reminder.py")"
test -z "$out" || { echo "FAIL: 'gh pr create' as command DATA was nudged (the 2026-07-20 false positive)" >&2; exit 1; }

echo "==> recommendation-anchor: a recommendation without a declared source must be blocked"
anchor() { # $1 = last_assistant_message; $2 = stop_hook_active (optional)
  python3 -c 'import json,sys; print(json.dumps({"last_assistant_message": sys.argv[1], "stop_hook_active": sys.argv[2] == "1"}))' \
    "$1" "${2:-0}" | python3 "$BIN/recommendation-anchor.py"
}
out="$(anchor "Recomendo cortar o scope gist, e depois revês os outros.")"
grep -q '"decision": "block"' <<<"$out" \
  || { echo "FAIL: a bare recommendation was not blocked" >&2; echo "$out" >&2; exit 1; }
grep -q "recommendation-anchor" <<<"$out" \
  || { echo "FAIL: the block gave no actionable reason" >&2; exit 1; }
out="$(anchor "I recommend cutting that scope.")"
grep -q '"decision": "block"' <<<"$out" \
  || { echo "FAIL: the English marker set did not fire" >&2; exit 1; }
# Declared evidence is compliance, in either direction.
out="$(anchor "Recomendo cortar o scope gist.

Verificado: gh auth status mostra 'gist' nos scopes e gh gist list devolve 0 usos.")"
test -z "$out" || { echo "FAIL: a recommendation declaring Verificado was blocked" >&2; echo "$out" >&2; exit 1; }
out="$(anchor "Sugiro trocar por um PAT.

Não verificado: falta confirmar se o gh aceita um PAT sem o scope minimo.")"
test -z "$out" || { echo "FAIL: an honestly-labelled unverified recommendation was blocked" >&2; exit 1; }
# Plain work must pass silent, and a second pass must never loop.
out="$(anchor "Corrigi o docstring e os selftests estao verdes.")"
test -z "$out" || { echo "FAIL: a plain answer with no recommendation was blocked" >&2; exit 1; }
out="$(anchor "Recomendo cortar o scope gist." 1)"
test -z "$out" || { echo "FAIL: blocked twice on the same turn (stop_hook_active ignored)" >&2; exit 1; }

echo "==> wiring: settings.json must be valid and reference every hook script"
python3 -c 'import json; json.load(open("'"$SETTINGS"'"))' \
  || { echo "FAIL: home/claude/settings.json is not valid JSON" >&2; exit 1; }
for script in secret-scan.py env-dump-guard.py write-containment.py deliberation-nudge.py audit-reminder.py recommendation-anchor.py; do
  grep -q "$script" "$SETTINGS" || { echo "FAIL: $script not wired in settings.json" >&2; exit 1; }
  test -x "$BIN/$script" || { echo "FAIL: $BIN/$script missing or not executable" >&2; exit 1; }
done
grep -q '"Write|Edit|MultiEdit|NotebookEdit"' "$SETTINGS" \
  || { echo "FAIL: containment matcher must cover Write/Edit/NotebookEdit" >&2; exit 1; }

echo "SELFTEST-HOME OK — containment blocks escapes (plain, ../, symlink), allowlist holds, secret gates fire, deliberation + audit nudges fire and stay silent correctly, wiring intact."
