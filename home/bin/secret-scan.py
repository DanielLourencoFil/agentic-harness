#!/usr/bin/env python3
"""secret-scan: UserPromptSubmit gate. Blocks prompts that appear to contain secrets.

Accident net, not adversarial defense. Scans raw stdin so it is immune to hook
payload field renames. Never echoes the matched value.
"""
import json
import re
import sys

text = sys.stdin.read()
patterns = {
    "API key (sk-...)": r"sk-[A-Za-z0-9_-]{16,}",
    "GitHub token": r"(ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,})",
    "AWS access key": r"AKIA[0-9A-Z]{16}",
    "Slack token": r"xox[baprs]-[A-Za-z0-9-]{10,}",
    "Google API key": r"AIza[0-9A-Za-z_-]{30,}",
    "private key block": r"-----BEGIN [A-Z ]*PRIVATE KEY-----",
    "JWT": r"eyJ[A-Za-z0-9_-]{8,}\.eyJ[A-Za-z0-9_-]{8,}",
    "DB URL with password": r"(postgres(ql)?|mysql|mongodb(\+srv)?|redis)://[^\s:/]+:[^\s@]+@",
}
hits = [name for name, p in patterns.items() if re.search(p, text)]
if hits:
    print(json.dumps({
        "decision": "block",
        "reason": ("Secret-hygiene gate: o prompt parece conter " + ", ".join(hits) +
                   ". Segredo visto = segredo queimado: substitui o valor por um placeholder"
                   " e, se o valor era real, RODA a credencial antes de continuar."),
    }))
sys.exit(0)
