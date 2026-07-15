#!/usr/bin/env python3
"""env-dump-guard: PreToolUse(Bash) gate. Denies commands whose stdout would dump
secrets into the model context (printenv, bare env, reading .env files, listing
platform variables). Accident net: bypassable on purpose, aimed at slips.
"""
import json
import re
import sys

data = json.load(sys.stdin)
cmd = (data.get("tool_input") or {}).get("command", "") or ""

rules = [
    ("printenv", r"\bprintenv\b"),
    ("bare env dump", r"(^|[;&|]\s*)env\s*(\||$)"),
    ("reading a .env file into output", r"\b(cat|less|more|head|tail|bat|strings)\b[^|;&]*\.env"),
    ("railway variables listing", r"\brailway\s+variables\b(?!.*--set)"),
    ("vercel env pull to stdout", r"\bvercel\s+env\s+(ls|pull)\b"),
]
hits = [name for name, p in rules if re.search(p, cmd)]
if hits:
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": (
                "Secret-hygiene gate (" + ", ".join(hits) + "): o output deste comando"
                " despejaria segredos no contexto do modelo. Usa command substitution"
                " para levar o valor shell->destino sem o imprimir, por exemplo:"
                " railway variables --set \"KEY=$(grep '^KEY=' .env | cut -d= -f2-)\""
            ),
        }
    }))
sys.exit(0)
