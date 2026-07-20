#!/usr/bin/env python3
"""audit-reminder: PreToolUse(Bash) nudge. When a PR is opened (gh pr create) —
the natural completed-unit boundary — inject a reminder to offer the human a
fresh-context /audit before the unit merges, so the audit rite does not depend
on anyone remembering it (externalized memory, ADR 24). Nudge, never block: it
adds context, the tool proceeds. The agent applies judgment — offer the audit
for product / load-bearing logic, note "audit N/A" for docs/ledger/config-only
PRs, so it does not over-fire (the ADR 10 lesson: a nagging gate dies socially).
The audit runs as the read-only `auditor` subagent: fresh (uncontaminated)
context AND zero marginal cost on a fixed plan.
"""
import json
import re
import sys

data = json.load(sys.stdin)
cmd = (data.get("tool_input") or {}).get("command", "") or ""

# Match only a REAL invocation — command start, or right after a shell operator
# (&& ; |) — never the string appearing as data (heredoc, echo, grep, prose).
# No re.MULTILINE on purpose: ^ is the whole-command start only, so a heredoc
# line reading "gh pr create" does not match. (Regression: the hook fired on its
# own ADR-writing command, which contained the literal text — 2026-07-20.)
if re.search(r"(?:^|&&|;|\|)\s*gh\s+pr\s+create\b", cmd):
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "additionalContext": (
                "[audit-reminder] A PR is being opened — a completed unit. Before"
                " it merges, offer the human a fresh-context /audit (the read-only"
                " auditor subagent: uncontaminated context, free on the fixed"
                " plan) IF this unit carries product or load-bearing logic. For a"
                " docs / ledger / config-only PR, say 'audit N/A (no logic)' and"
                " proceed — do not nag. The audit is the human's yes/no, never"
                " automatic."
            ),
        }
    }))
sys.exit(0)
