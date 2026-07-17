#!/usr/bin/env python3
"""write-containment: PreToolUse(Write|Edit|NotebookEdit) gate — ADR 10.

Denies file-tool writes whose REAL path (symlinks and `../` resolved) lands
outside the project root, with a short named allowlist: the agent memory dir
(~/.claude/projects/) and the session scratchpad (/tmp/claude-*). Honest limit:
binds the file tools only — Bash is contained by an OS sandbox, not by this.
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


memory_dir = os.path.realpath(os.path.join(os.path.expanduser("~"), ".claude", "projects"))
allowed = (
    under(real, real_root)
    or under(real, memory_dir)
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
                " Permitidos fora da raiz: memória do agente (~/.claude/projects/)"
                " e scratchpad da sessão (/tmp/claude-*). Se a escrita é mesmo"
                " intencional, faz o Daniel executá-la, ou abre a sessão na pasta"
                " do projeto certo."
            ),
        }
    }))
sys.exit(0)
