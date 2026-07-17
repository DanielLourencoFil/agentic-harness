#!/usr/bin/env python3
"""write-containment: PreToolUse(Write|Edit|NotebookEdit) gate — ADR 10.

Denies file-tool writes whose REAL path (symlinks and `../` resolved) lands
outside the project root, with a short named allowlist: the agent memory dir
(~/.claude/projects/), the session scratchpad (/tmp/claude-*) and the
cross-project data repo (~/Dev/organizer/ — the backlog rite writes there from
any session; ADR 13). Honest limit: binds the file tools only — Bash is
contained by an OS sandbox, not by this.
"""
import json
import os
import sys

data = json.load(sys.stdin)
tool_input = data.get("tool_input") or {}
target = tool_input.get("file_path") or tool_input.get("notebook_path") or ""
if not target:
    sys.exit(0)

root = os.environ.get("CLAUDE_PROJECT_DIR") or data.get("cwd") or ""
if not root:
    sys.exit(0)

if not os.path.isabs(target):
    target = os.path.join(data.get("cwd") or root, target)
real = os.path.realpath(target)
real_root = os.path.realpath(root)


def under(path: str, prefix: str) -> bool:
    return path == prefix or path.startswith(prefix + os.sep)


home = os.path.expanduser("~")
memory_dir = os.path.realpath(os.path.join(home, ".claude", "projects"))
organizer = os.path.realpath(os.path.join(home, "Dev", "organizer"))
allowed = (
    under(real, real_root)
    or under(real, memory_dir)
    or under(real, organizer)
    # scratchpad; /private/tmp is macOS's realpath of /tmp
    or real.startswith(("/tmp/claude-", "/private/tmp/claude-"))
)
if not allowed:
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": (
                "Contenção de escrita (ADR 10): o alvo real " + real
                + " está fora da raiz do projeto (" + real_root + ")."
                " Permitidos fora da raiz: memória do agente (~/.claude/projects/),"
                " scratchpad da sessão (/tmp/claude-*) e o repo de dados"
                " cross-project (~/Dev/organizer/). Se a escrita é mesmo"
                " intencional, faz o Daniel executá-la, ou abre a sessão na pasta"
                " do projeto certo."
            ),
        }
    }))
sys.exit(0)
