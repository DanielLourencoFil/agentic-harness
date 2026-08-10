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
#   4b. decision-nudge fires the /decide rite on the DECISION's shape — a stack or
#      deploy commitment — and stays silent on the routine package.json edits
#      (version bump, script tweak) that would otherwise kill it socially (ADR 68);
#   5. recommendation-anchor blocks an answer that recommends without declaring
#      what verified it, accepts an honest "não verificado", stays silent on
#      plain work, and never blocks twice on one turn (ADR 30);
#   6. shelf-inventory asks on a NEW file in a configured shelf and hands the
#      agent the entries plus the shelf path, and stays silent on an existing
#      file, outside the shelf, in a nested dir, below minEntries, and with no
#      config at all (ADR 31).
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

echo "==> decision-nudge: a stack/deploy commitment must nudge, routine edits stay silent"
decision() { # $1 = payload json; stdout = hook output, stderr captured for the crash check
  printf '%s' "$1" | python3 "$BIN/decision-nudge.py" 2>"$TMP/dn.err"
}
# stderr is checked on EVERY case, fires or silent. Without it the silence
# assertions are satisfied by a hook that crashes on every input: a traceback
# goes to stderr and stdout stays empty, so `test -z` passes while the gate is
# dead. Found by the fresh-context audit of 2026-08-10 (ADR 69).
dn_no_crash() { # $1 = case name
  if [ -s "$TMP/dn.err" ]; then
    echo "FAIL: $1 wrote to stderr - a crashing hook passes every silence assertion" >&2
    cat "$TMP/dn.err" >&2; exit 1
  fi
}
dn_fires() {
  grep -q "decision-nudge" <<<"$2" || { echo "FAIL: $1 did not nudge" >&2; exit 1; }
  dn_no_crash "$1"
}
dn_silent() {
  test -z "$2" || { echo "FAIL: $1 was nudged (over-fire)" >&2; echo "$2" >&2; exit 1; }
  dn_no_crash "$1"
}
dn_fires "a new Dockerfile" \
  "$(decision '{"tool_name":"Write","tool_input":{"file_path":"/p/Dockerfile","content":"FROM node:22"}}')"
dn_fires "a terraform file" \
  "$(decision '{"tool_name":"Write","tool_input":{"file_path":"/p/infra/main.tf","content":"x"}}')"
dn_fires "a compose file (legacy name)" \
  "$(decision '{"tool_name":"Edit","tool_input":{"file_path":"/p/docker-compose.yml","new_string":"x"}}')"
# The SAME artefact under its current name. Compose V2's documented default file
# is compose.yaml, and a Dockerfile is routinely prefixed per environment. A
# marker that only knows the legacy spelling is a naming gap, not a scope
# question (audit 2026-08-10).
dn_fires "a compose file under the Compose V2 default name" \
  "$(decision '{"tool_name":"Write","tool_input":{"file_path":"/p/compose.yaml","content":"services:"}}')"
dn_fires "an environment-prefixed Dockerfile" \
  "$(decision '{"tool_name":"Write","tool_input":{"file_path":"/p/dev.Dockerfile","content":"FROM node:22"}}')"
dn_fires "a workspace manifest (repo shape)" \
  "$(decision '{"tool_name":"Write","tool_input":{"file_path":"/p/pnpm-workspace.yaml","content":"packages:"}}')"
dn_fires "a dependency added to package.json" \
  "$(decision '{"tool_name":"Edit","tool_input":{"file_path":"/p/package.json","new_string":"    \"zod\": \"^3.23.0\","}}')"
# Dependency specs that do not start with a digit. workspace:* is the canonical
# pnpm form, in the very repo family this hook watches via pnpm-workspace.yaml,
# and it was invisible to the shipped regex (audit 2026-08-10).
dn_fires "a workspace protocol dependency (pnpm monorepo)" \
  "$(decision '{"tool_name":"Edit","tool_input":{"file_path":"/p/package.json","new_string":"    \"@app/core\": \"workspace:*\","}}')"
dn_fires "a range spec that does not start with a digit" \
  "$(decision '{"tool_name":"Edit","tool_input":{"file_path":"/p/package.json","new_string":"    \"react\": \">=18.0.0\","}}')"
# Authoring a WHOLE manifest is the stack decision itself, so Write always fires
# and the dependency gate applies to Edit only. Pinned because the shipped hook
# reached the same outcome by accident - every real package.json contains the
# literal "dependencies", so content-scanning fired even on a version bump.
dn_fires "a whole-file Write of package.json (authoring the manifest)" \
  "$(decision '{"tool_name":"Write","tool_input":{"file_path":"/p/package.json","content":"{\"name\":\"x\",\"version\":\"1.0.1\"}"}}')"
# The load-bearing pair: package.json is edited constantly. If a release bump or a
# script tweak nudges, the reader learns to ignore the hook and it dies socially
# (the ADR 10 lesson) — which is also why migrations are not watched in v1.
dn_silent "a version bump in package.json" \
  "$(decision '{"tool_name":"Edit","tool_input":{"file_path":"/p/package.json","new_string":"  \"version\": \"1.0.1\","}}')"
dn_silent "a script tweak in package.json" \
  "$(decision '{"tool_name":"Edit","tool_input":{"file_path":"/p/package.json","new_string":"    \"test\": \"vitest run\","}}')"
dn_silent "an ordinary source edit" \
  "$(decision '{"tool_name":"Edit","tool_input":{"file_path":"/p/src/foo.ts","new_string":"const a = 1"}}')"
dn_silent "a docs edit" \
  "$(decision '{"tool_name":"Write","tool_input":{"file_path":"/p/docs/NOTES.md","content":"prose"}}')"
dn_silent "a vendored manifest under node_modules" \
  "$(decision '{"tool_name":"Write","tool_input":{"file_path":"/p/node_modules/x/package.json","content":"{\"dependencies\":{}}"}}')"
# Metadata whose value is semver-shaped must not read as a dependency.
dn_silent "a package.json field whose value merely looks like a version" \
  "$(decision '{"tool_name":"Edit","tool_input":{"file_path":"/p/package.json","new_string":"  \"packageManager\": \"pnpm@9.1.0\","}}')"
# Malformed input must be silent AND quiet: a hook is fed whatever the tool
# layer sends, and a traceback on every call is noise the reader learns to skip.
dn_silent "stdin that is not JSON"            "$(decision 'hello')"
dn_silent "a payload with no tool_input"      "$(decision '{}')"
dn_silent "a tool_input that is not an object" "$(decision '{"tool_input":"oops"}')"
dn_silent "a file_path that is not a string"  "$(decision '{"tool_input":{"file_path":5}}')"

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

echo "==> shelf-inventory: auto-detects a shelf by size AND fan-in, no config"
SHELF_ROOT="$TMP/shelfproj"
mkdir -p "$SHELF_ROOT/src/components/ui" "$SHELF_ROOT/src/components/landing" "$SHELF_ROOT/src/lib"
for n in alert badge button calendar card dialog input popover select toast; do
  : > "$SHELF_ROOT/src/components/ui/$n.tsx"
  : > "$SHELF_ROOT/src/components/landing/hero-$n.tsx"
done
# 12 distinct directories import from ui; only 2 import from landing. Same file
# count, opposite verdict: that pair is the whole point of the two signals.
for i in $(seq 1 12); do
  mkdir -p "$SHELF_ROOT/src/app/page$i"
  printf 'import { Button } from "@/components/ui/button";\n' > "$SHELF_ROOT/src/app/page$i/page.tsx"
done
for i in 1 2; do
  printf 'import { Hero } from "@/components/landing/hero-alert";\n' >> "$SHELF_ROOT/src/app/page$i/page.tsx"
done

shelf() { # $1 = absolute target path; stdout = hook output
  printf '{"tool_name":"Write","cwd":"%s","tool_input":{"file_path":"%s"}}' "$SHELF_ROOT" "$1" \
    | env CLAUDE_PROJECT_DIR="$SHELF_ROOT" python3 "$BIN/shelf-inventory.py"
}

out="$(shelf "$SHELF_ROOT/src/components/ui/date-range-picker.tsx")"
grep -q '"permissionDecision": "ask"' <<<"$out" \
  || { echo "FAIL: a new file on an auto-detected shelf did not stop for the human" >&2; echo "$out" >&2; exit 1; }
grep -q '"additionalContext"' <<<"$out" \
  || { echo "FAIL: the agent got no inventory — the only channel that reaches it (5 probe runs, ADR 31)" >&2; exit 1; }
grep -q 'calendar' <<<"$out" \
  || { echo "FAIL: the inventory does not name the existing entries" >&2; exit 1; }
grep -q 'components/ui' <<<"$out" \
  || { echo "FAIL: the context omits the shelf path, which sends the agent hunting" >&2; exit 1; }
grep -q 'never another project' <<<"$out" \
  || { echo "FAIL: the context does not forbid leaving the project (observed twice: ~/Dev sweep, sibling repo)" >&2; exit 1; }

# Same size, different fan-in: a directory serving one screen is not a shelf.
out="$(shelf "$SHELF_ROOT/src/components/landing/hero-new.tsx")"
test -z "$out" || { echo "FAIL: fired on a same-sized directory with fan-in 2 (landing, 28 files, ADR 31)" >&2; exit 1; }
# Shared but tiny: nothing to duplicate yet.
out="$(shelf "$SHELF_ROOT/src/lib/helper.ts")"
test -z "$out" || { echo "FAIL: fired below MIN_ENTRIES, where the shelf has nothing to duplicate" >&2; exit 1; }
out="$(shelf "$SHELF_ROOT/src/components/ui/button.tsx")"
test -z "$out" || { echo "FAIL: fired on an EXISTING file (edit, not creation)" >&2; exit 1; }
out="$(shelf "$SHELF_ROOT/src/components/ui/nested/deep.tsx")"
test -z "$out" || { echo "FAIL: fired on a nested dir, which is its own concern" >&2; exit 1; }
# Explicit config wins in both directions.
mkdir -p "$SHELF_ROOT/.claude"
printf '{"shelves":[]}\n' > "$SHELF_ROOT/.claude/shelf.json"
out="$(shelf "$SHELF_ROOT/src/components/ui/another.tsx")"
test -z "$out" || { echo "FAIL: an empty shelves list must disable the hook entirely" >&2; exit 1; }
printf '{"shelves":[{"path":"src/components/landing"}]}\n' > "$SHELF_ROOT/.claude/shelf.json"
out="$(shelf "$SHELF_ROOT/src/components/landing/hero-new.tsx")"
grep -q '"permissionDecision": "ask"' <<<"$out" \
  || { echo "FAIL: an explicitly declared shelf was not honoured over auto-detection" >&2; exit 1; }
out="$(shelf "$SHELF_ROOT/src/components/ui/another.tsx")"
test -z "$out" || { echo "FAIL: config listed only landing, so ui must stop being a shelf" >&2; exit 1; }
rm -rf "$SHELF_ROOT/.claude"

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
# A qualifier between the keyword and the colon is still a declaration. The
# first regex rejected "Medido em 5 corridas:" and blocked its own author.
out="$(anchor "Recomendo cortar.

**Medido em 5 corridas:** o ask parou a escrita em todas.")"
test -z "$out" || { echo "FAIL: a qualified declaration was rejected" >&2; exit 1; }
out="$(anchor "Recomendo cortar o scope gist." 1)"
test -z "$out" || { echo "FAIL: blocked twice on the same turn (stop_hook_active ignored)" >&2; exit 1; }

echo "==> evidence-gate: a completion claim needs a verification command that RAN"
FAKE_T="$TMP/transcript.jsonl"
tool_line() { # $1 = command -> one transcript line shaped like a real Bash tool_use
  python3 -c 'import json,sys; print(json.dumps({"message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":sys.argv[1]}}]}}))' "$1"
}
evidence() { # $1 = message; $2 = transcript path; $3 = stop_hook_active
  python3 -c 'import json,sys; print(json.dumps({"last_assistant_message":sys.argv[1],"transcript_path":sys.argv[2],"stop_hook_active":sys.argv[3]=="1"}))' \
    "$1" "$2" "${3:-0}" | python3 "$BIN/evidence-gate.py"
}

: > "$FAKE_T"
out="$(evidence "Está feito, o hook novo funciona." "$FAKE_T")"
grep -q '"decision": "block"' <<<"$out" \
  || { echo "FAIL: a completion claim with an empty transcript was not blocked" >&2; exit 1; }
grep -q "evidence-gate" <<<"$out" || { echo "FAIL: the block gave no actionable reason" >&2; exit 1; }

# A verification command that RAN is evidence.
tool_line "bash scripts/selftest-home.sh" > "$FAKE_T"
out="$(evidence "Está feito, o hook novo funciona." "$FAKE_T")"
test -z "$out" || { echo "FAIL: blocked although a selftest ran this session" >&2; echo "$out" >&2; exit 1; }

# The same tool name as DATA inside a command is not evidence. This is the
# env-dump-guard mistake, and it was measured on a real transcript before wiring.
tool_line 'grep -n "vitest\|test" .github/workflows/ci.yml' > "$FAKE_T"
out="$(evidence "Está feito, tudo verde." "$FAKE_T")"
grep -q '"decision": "block"' <<<"$out" \
  || { echo "FAIL: a grep MENTIONING vitest counted as having run it" >&2; exit 1; }

# `cd x && pnpm verify` is a real run; the prefix is navigation.
tool_line "cd apps/web && pnpm verify" > "$FAKE_T"
out="$(evidence "Concluído." "$FAKE_T")"
test -z "$out" || { echo "FAIL: a cd-prefixed verify was not recognised" >&2; exit 1; }

# Labelling the absence honestly is the sanctioned path, not an evasion.
: > "$FAKE_T"
out="$(evidence "IMPLEMENTED - NOT VERIFIED: corre \`pnpm verify\` para confirmar." "$FAKE_T")"
test -z "$out" || { echo "FAIL: an honestly downgraded claim was blocked" >&2; exit 1; }
out="$(evidence "Está feito. Não verificado: falta correr o selftest." "$FAKE_T")"
test -z "$out" || { echo "FAIL: a claim carrying an honest label was blocked" >&2; exit 1; }

# Plain work passes silent, and a second pass never loops.
out="$(evidence "Escrevi o ficheiro e adicionei os comentários." "$FAKE_T")"
test -z "$out" || { echo "FAIL: an answer claiming nothing was blocked" >&2; exit 1; }
out="$(evidence "Está feito, funciona." "$FAKE_T" 1)"
test -z "$out" || { echo "FAIL: blocked twice on the same turn (stop_hook_active ignored)" >&2; exit 1; }

echo "==> wiring: settings.json must be valid and reference every hook script"
# ---------------------------------------------------------------------------
# skill-activation: a git-tracked skill missing its ~/.claude link is auto-linked
# (force); an untracked dir in home/skills is warned, never auto-activated
# (half-force). CI cannot see a real ~/.claude, so this planted repo is the only
# place the behaviour is exercised (ADR 43).
echo "==> skill-activation: tracked skill auto-links; untracked only warns; idempotent"
SA_REPO="$TMP/sa-repo"; SA_HOME="$TMP/sa-home"
mkdir -p "$SA_REPO/home/skills/tracked-rite" "$SA_REPO/home/skills/foreign-drop" \
  "$SA_REPO/home/skills/sidecar-draft" "$SA_HOME/.claude/skills"
: > "$SA_REPO/home/skills/tracked-rite/SKILL.md"
: > "$SA_REPO/home/skills/foreign-drop/SKILL.md"
# sidecar-draft: a sibling file is committed but SKILL.md itself is NOT - it must
# read as untracked (the ADR 43 invariant is that SKILL.md passed the commit gate).
: > "$SA_REPO/home/skills/sidecar-draft/README.md"
: > "$SA_REPO/home/skills/sidecar-draft/SKILL.md"
git -C "$SA_REPO" init -q
git -C "$SA_REPO" config user.email selftest@local
git -C "$SA_REPO" config user.name selftest
git -C "$SA_REPO" config commit.gpgsign false
git -C "$SA_REPO" add home/skills/tracked-rite/SKILL.md   # foreign-drop stays untracked
git -C "$SA_REPO" add home/skills/sidecar-draft/README.md # its SKILL.md stays untracked
git -C "$SA_REPO" commit -q -m seed
skill_activation() {
  env HOME="$SA_HOME" AGENTIC_HARNESS_DIR="$SA_REPO" python3 "$BIN/skill-activation.py"
}
out="$(skill_activation)"
link="$SA_HOME/.claude/skills/tracked-rite"
if ! { [ -L "$link" ] && [ "$(readlink -f "$link")" = "$(readlink -f "$SA_REPO/home/skills/tracked-rite")" ]; }; then
  echo "FAIL: tracked skill was not auto-linked" >&2; echo "$out" >&2; exit 1
fi
grep -q "tracked-rite" <<<"$out" || { echo "FAIL: activation not reported" >&2; exit 1; }
grep -q "foreign-drop" <<<"$out" || { echo "FAIL: untracked drop not warned" >&2; exit 1; }
if [ -e "$SA_HOME/.claude/skills/foreign-drop" ]; then
  echo "FAIL: untracked drop was auto-activated (the foreign-skill risk)" >&2; exit 1
fi
# Sidecar-tracked case (ultrareview finding, ADR 44): SKILL.md itself is
# uncommitted, so the dir must read as untracked - warned, never linked, even
# though a sibling (README) IS tracked. Otherwise "tracked = vetted" is a lie.
grep -q "sidecar-draft" <<<"$out" || { echo "FAIL: sidecar-tracked dir (SKILL.md uncommitted) not warned" >&2; exit 1; }
if [ -e "$SA_HOME/.claude/skills/sidecar-draft" ]; then
  echo "FAIL: a dir with only a sibling tracked was auto-activated - tracked=vetted broke" >&2; exit 1
fi
# Vet properly (commit the SKILL.md itself): only then must each AUTO-LINK. The
# sidecar's tracked README was never enough.
git -C "$SA_REPO" add home/skills/foreign-drop/SKILL.md home/skills/sidecar-draft/SKILL.md
git -C "$SA_REPO" commit -q -m "vet the drop and the sidecar"
skill_activation >/dev/null
if [ ! -L "$SA_HOME/.claude/skills/foreign-drop" ] || [ ! -L "$SA_HOME/.claude/skills/sidecar-draft" ]; then
  echo "FAIL: a now-tracked skill was not activated on the next run" >&2; exit 1
fi
# Idempotent: everything tracked and linked -> silent.
out3="$(skill_activation)"
[ -z "$out3" ] || { echo "FAIL: not silent when all tracked and linked" >&2; echo "$out3" >&2; exit 1; }

# ---------------------------------------------------------------------------
# backlog-inject: the cross-project BACKLOG is injected ONLY at the desk
# (cwd == ~/Dev). In any project subfolder it stays silent, so the index and its
# career PII never leak into a project or a screen-shared interview (ADR 45).
echo "==> backlog-inject: injects at the ~/Dev desk, silent in a project subfolder"
mkdir -p "$FAKEHOME/Dev/proj-x"
printf '# BACKLOG\nSENTINEL-BACKLOG-LINE\n' > "$FAKEHOME/Dev/BACKLOG.md"
backlog_inject() { printf '%s' "$1" | env HOME="$FAKEHOME" python3 "$BIN/backlog-inject.py"; }
out="$(backlog_inject '{"cwd":"'"$FAKEHOME"'/Dev"}')"
grep -q "SENTINEL-BACKLOG-LINE" <<<"$out" || { echo "FAIL: backlog not injected at the desk" >&2; echo "$out" >&2; exit 1; }
out="$(backlog_inject '{"cwd":"'"$FAKEHOME"'/Dev/proj-x"}')"
[ -z "$out" ] || { echo "FAIL: backlog injected in a project session (the PII leak)" >&2; echo "$out" >&2; exit 1; }

# ---------------------------------------------------------------------------
# push-guard: a git push that REACHES the default branch is denied by resolving
# the actual target (not string-matching), closing the forms that slipped the
# project blocklist; a clear work-branch push passes silently (ADR 46).
echo "==> push-guard: denies pushes reaching the default branch, allows work branches"
PG="$TMP/pg-repo"; mkdir -p "$PG"
git -C "$PG" init -q -b main
git -C "$PG" config user.email selftest@local; git -C "$PG" config user.name selftest
git -C "$PG" config commit.gpgsign false
git -C "$PG" commit -q --allow-empty -m seed
push_guard() { ( cd "$PG" && printf '%s' "$1" | python3 "$BIN/push-guard.py" ); }
pg_deny() { grep -q '"permissionDecision": "deny"' <<<"$2" || { echo "FAIL: $1 was NOT denied" >&2; echo "$2" >&2; exit 1; }; }
pg_allow() { if grep -q 'permissionDecision' <<<"$2"; then echo "FAIL: $1 was gated but must pass" >&2; echo "$2" >&2; exit 1; fi; }
# The exact forms the blocklist missed, all reaching a default branch -> deny:
pg_deny "push origin main"          "$(push_guard '{"tool_name":"Bash","tool_input":{"command":"git push origin main"}}')"
pg_deny "push -u origin main"       "$(push_guard '{"tool_name":"Bash","tool_input":{"command":"git push -u origin main"}}')"
pg_deny "push origin +main"         "$(push_guard '{"tool_name":"Bash","tool_input":{"command":"git push origin +main"}}')"
pg_deny "push origin HEAD:main"     "$(push_guard '{"tool_name":"Bash","tool_input":{"command":"git push origin HEAD:main"}}')"
pg_deny "push origin feature:master" "$(push_guard '{"tool_name":"Bash","tool_input":{"command":"git push origin feature:master"}}')"
pg_deny "bare push on main"         "$(push_guard '{"tool_name":"Bash","tool_input":{"command":"git push"}}')"
pg_deny "push origin (on main)"     "$(push_guard '{"tool_name":"Bash","tool_input":{"command":"git push origin"}}')"
pg_deny "push origin HEAD (on main)" "$(push_guard '{"tool_name":"Bash","tool_input":{"command":"git push origin HEAD"}}')"
# Work-branch pushes must pass silently (the git rite is preserved):
git -C "$PG" checkout -q -b feat/x
pg_allow "bare push on work branch" "$(push_guard '{"tool_name":"Bash","tool_input":{"command":"git push"}}')"
pg_allow "push origin work branch"  "$(push_guard '{"tool_name":"Bash","tool_input":{"command":"git push origin feat/x"}}')"
pg_allow "push -u origin work"      "$(push_guard '{"tool_name":"Bash","tool_input":{"command":"git push -u origin feat/x"}}')"
pg_allow "not a git push"           "$(push_guard '{"tool_name":"Bash","tool_input":{"command":"git status"}}')"

# COMPOUND COMMANDS (ADR 70). Every case above is a push ALONE on the command
# line. The shipped guard read only the FIRST `git push` occurrence anywhere in
# the string, so a mention before the real invocation moved the analysis onto
# the mention's trailing tokens and the real push to the default branch was
# allowed. Found 2026-08-10 while writing a demo whose own prose tripped the
# guard: the same false-positive/false-negative pair audit-reminder fixed for
# itself on 2026-07-20 (see its docstring). These are the shapes an agent
# composes without any adversarial intent - a status echo before a push.
echo "==> push-guard: a decoy mention must not hide a real push to the default branch"
pg_deny "quoted mention, then the real push" \
  "$(push_guard '{"tool_name":"Bash","tool_input":{"command":"echo '"'"'a git push'"'"' && git push origin main"}}')"
pg_deny "unquoted mention, then the real push" \
  "$(push_guard '{"tool_name":"Bash","tool_input":{"command":"echo git push && git push origin main"}}')"
pg_deny "shell comment, then the real push on the next line" \
  "$(push_guard '{"tool_name":"Bash","tool_input":{"command":"true # git push aqui\ngit push origin master"}}')"
pg_deny "a real push after a semicolon" \
  "$(push_guard '{"tool_name":"Bash","tool_input":{"command":"pnpm verify; git push origin HEAD:main"}}')"
# A quoted refspec is legal shell and named the default branch all along: the
# first version compared raw tokens, so `"main"` never equalled `main`. Found
# 2026-08-10 while reviewing the fix above, and confirmed against HEAD as a
# PRE-EXISTING hole, not one the fix introduced (ADR 70).
pg_deny "a double-quoted default-branch refspec" \
  "$(push_guard '{"tool_name":"Bash","tool_input":{"command":"git push origin \"main\""}}')"
pg_deny "a single-quoted default-branch refspec" \
  "$(push_guard '{"tool_name":"Bash","tool_input":{"command":"git push origin '"'"'master'"'"'"}}')"
# The mirror: a mention that is only DATA must stay silent. The guard denied the
# sentence that documented it, which is how the bug was found.
pg_allow "the phrase inside a quoted echo (prose, not an invocation)" \
  "$(push_guard '{"tool_name":"Bash","tool_input":{"command":"echo '"'"'nunca ve um git push, a main fica sem muro'"'"'"}}')"
pg_allow "the phrase inside a shell comment" \
  "$(push_guard '{"tool_name":"Bash","tool_input":{"command":"true # nota sobre git push origin main"}}')"
pg_allow "a work-branch push after a real command" \
  "$(push_guard '{"tool_name":"Bash","tool_input":{"command":"pnpm verify && git push origin feat/x"}}')"
# Verdict ORDER, not just presence: outside a repo the branch is unresolvable, so
# the first push asks. A deny found later must still win - otherwise the weaker
# verdict of an earlier invocation licenses the stronger one. Found by a planted
# mutation that survived every case above (ADR 70): a surviving mutation means a
# missing test, never a harmless change.
echo "==> push-guard: a later deny outranks an earlier ask (strictest verdict wins)"
NOREPO="$TMP/norepo"; mkdir -p "$NOREPO"
out="$( ( cd "$NOREPO" && printf '%s' '{"tool_name":"Bash","tool_input":{"command":"git push && git push origin main"}}' \
  | python3 "$BIN/push-guard.py" ) )"
grep -q '"permissionDecision": "deny"' <<<"$out" \
  || { echo "FAIL: an earlier unresolvable push downgraded a later default-branch push to ask" >&2
       echo "$out" >&2; exit 1; }

python3 -c 'import json; json.load(open("'"$SETTINGS"'"))' \
  || { echo "FAIL: home/claude/settings.json is not valid JSON" >&2; exit 1; }
for script in secret-scan.py env-dump-guard.py write-containment.py deliberation-nudge.py decision-nudge.py audit-reminder.py recommendation-anchor.py shelf-inventory.py evidence-gate.py skill-activation.py backlog-inject.py push-guard.py; do
  grep -q "$script" "$SETTINGS" || { echo "FAIL: $script not wired in settings.json" >&2; exit 1; }
  test -x "$BIN/$script" || { echo "FAIL: $BIN/$script missing or not executable" >&2; exit 1; }
  # The mode GIT records, not the one on disk. This machine has core.fileMode
  # false (usual on WSL2), so chmod +x never reaches the index: the file is 755
  # locally, 644 in the commit, and CI checks out something it cannot run. The
  # disk check above passed while CI failed, which is a gate blind to the very
  # thing that breaks. Fix a 644 with: git update-index --chmod=+x <path>
  mode="$(git -C "$HARNESS_DIR" ls-files -s "home/bin/$script" | cut -d" " -f1)"
  [ "$mode" = "100755" ] || {
    echo "FAIL: home/bin/$script is $mode in git, not 100755 — CI will check out a file it cannot execute" >&2
    echo "      git update-index --chmod=+x home/bin/$script" >&2
    exit 1; }
done
grep -q '"Write|Edit|MultiEdit|NotebookEdit"' "$SETTINGS" \
  || { echo "FAIL: containment matcher must cover Write/Edit/NotebookEdit" >&2; exit 1; }

# The loop above only proves the FILENAME appears somewhere in settings.json. It
# says nothing about the event or the matcher the hook is bound to, and a hook
# bound to the wrong one is as dead as a hook that is absent. Measured by the
# fresh-context audit of 2026-08-10: swapping decision-nudge's matcher to "Bash"
# — where the payload never carries file_path, so the hook is structurally
# unable to fire — left this whole selftest green (ADR 69).
python3 - "$SETTINGS" <<'PY' || exit 1
import json, sys
settings = json.load(open(sys.argv[1]))
# hook script -> (event, exact matcher) it must be bound to for its input to exist.
REQUIRED = {"decision-nudge.py": ("PreToolUse", "Write|Edit")}
for script, (event, matcher) in REQUIRED.items():
    found = [b.get("matcher") for b in settings.get("hooks", {}).get(event, [])
             if any(script in h.get("command", "") for h in b.get("hooks", []))]
    if not found:
        sys.exit(f"FAIL: {script} is not wired under {event} at all")
    if matcher not in found:
        sys.exit(f"FAIL: {script} is wired under {event} with matcher {found},"
                 f" expected {matcher!r} — it reads tool_input.file_path, so any"
                 f" other matcher makes it structurally unable to fire")
PY

echo "SELFTEST-HOME OK — containment blocks escapes (plain, ../, symlink), allowlist holds, secret gates fire, deliberation + audit nudges fire and stay silent correctly, wiring intact."
