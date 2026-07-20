#!/usr/bin/env bash
# Pipe-tests the home/ layer hooks in isolation (no Claude required) and asserts
# they are actually wired in home/claude/settings.json — a hook that is right but
# unreferenced is decoration (same lesson as the template selftest: a gate must
# be seen saying "no"). Covers, per ADR 10 and the secret-hygiene pack:
#   1. write-containment denies writes whose REAL path escapes the project root
#      (plain outside, `../`, symlink) and allows root/memory/scratchpad;
#   2. secret-scan blocks prompts carrying secret-shaped values;
#   3. env-dump-guard denies commands that would dump secrets into context;
#   4. deliberation-nudge reminds on deliberation markers (nudge, never block)
#      and stays silent on plain work prompts (ADR 19).
set -euo pipefail

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$HARNESS_DIR/home/bin"
SETTINGS="$HARNESS_DIR/home/claude/settings.json"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

ROOT="$TMP/proj"
FAKEHOME="$TMP/home"
mkdir -p "$ROOT" "$TMP/outside" "$FAKEHOME/.claude/projects/some-proj/memory" \
  "$FAKEHOME/Dev/organizer"
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
expect_allow "write to session scratchpad (named allowlist)" \
  "$(containment '{"tool_name":"Write","cwd":"'"$ROOT"'","tool_input":{"file_path":"/tmp/claude-selftest/scratchpad/tmp.txt"}}')"
expect_allow "write to the cross-project data repo (backlog rite, ADR 13)" \
  "$(containment '{"tool_name":"Write","cwd":"'"$ROOT"'","tool_input":{"file_path":"'"$FAKEHOME"'/Dev/organizer/BACKLOG.md"}}')"

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

echo "==> wiring: settings.json must be valid and reference every hook script"
python3 -c 'import json; json.load(open("'"$SETTINGS"'"))' \
  || { echo "FAIL: home/claude/settings.json is not valid JSON" >&2; exit 1; }
for script in secret-scan.py env-dump-guard.py write-containment.py deliberation-nudge.py; do
  grep -q "$script" "$SETTINGS" || { echo "FAIL: $script not wired in settings.json" >&2; exit 1; }
  test -x "$BIN/$script" || { echo "FAIL: $BIN/$script missing or not executable" >&2; exit 1; }
done
grep -q '"Write|Edit|MultiEdit|NotebookEdit"' "$SETTINGS" \
  || { echo "FAIL: containment matcher must cover Write/Edit/NotebookEdit" >&2; exit 1; }

echo "SELFTEST-HOME OK — containment blocks escapes (plain, ../, symlink), allowlist holds, secret gates fire, nudge fires and stays silent correctly, wiring intact."
