#!/usr/bin/env python3
"""Stop hook (ADR 34, C-051): "done" and "it works" need a command that ran.

The constitution's oldest rule is that an "it works" claim carries the command
output that proves it, and that a feature is done only with output shown. It has
been steer since 2026-07-11 (C-047), and C-051 recorded the wired version as
deferred because nobody knew a hook could read what the agent writes. That
changed on 2026-08-04: a Stop hook receives `last_assistant_message` and can
block with a reason (ADR 30). This is the same mechanism pointed at the older,
more important rule.

What it checks, and the order matters:
  1. does the answer claim completion or that something works?
  2. does it already carry an honest label ("IMPLEMENTED - NOT VERIFIED", "nao
     verificado")? Labeling honestly is the sanctioned path, not an evasion.
  3. did a verification command actually run in THIS session? The transcript is
     parsed for Bash tool calls, so a command merely *quoted* in prose does not
     count. That distinction is the one env-dump-guard got wrong and
     audit-reminder had to fix.

Honest label: half-force. It proves a verification command ran, not that it
passed, and not that it covered the claim. A greener check would need the tool
result and a mapping from claim to command, neither of which a text hook can do.
What it removes is the cheapest failure: claiming done having run nothing.
"""
import json
import os
import re
import sys

CLAIM = [
    r"\bestá feito\b", r"\bestá pronto\b", r"\bconclu[ií]do\b", r"\bimplementado\b",
    r"\bfunciona\b", r"\bestá verde\b", r"\bficou verde\b", r"\btudo verde\b",
    r"\bpassou\b", r"\bpassaram\b", r"\bcorreu bem\b",
    r"\bit works\b", r"\bis done\b", r"\ball set\b", r"\bworking now\b",
    r"\btests? pass\b", r"\bis green\b", r"\bnow green\b", r"\bcompleted?\b",
]

# Labeling the absence honestly is compliance. The constitution names this exact
# escape: "No evidence = status IMPLEMENTED - NOT VERIFIED, with the exact command
# the human runs" (PLAYBOOK feature loop).
HONEST = re.compile(
    r"(implemented\s*[-–—]\s*not verified|n[aã]o verificad[oa]|not verified"
    r"|por verificar|hip[oó]tese|hypothesis|unverified)",
    re.IGNORECASE,
)

# Anchored at the START of a command segment, never anywhere in the string. A
# `grep -n "vitest\|test"` mentions the tool as DATA and must not count as
# evidence; measured against a real 2282-line transcript, the unanchored version
# accepted exactly that. Same lesson audit-reminder.py already carries for
# `gh pr create`.
VERIFICATION = re.compile(
    r"^(pnpm|npm|yarn|bun)\s+(run\s+)?(verify|test|typecheck|lint)\b"
    r"|^(vitest|jest|pytest)\b"
    r"|^(go|cargo)\s+test\b"
    r"|^tsc\s+--noEmit\b|^eslint\b"
    r"|^bash\s+scripts/selftest[a-z-]*\.sh\b",
    re.IGNORECASE,
)

# `cd somewhere && pnpm verify` is a real run; the prefix is navigation, not the
# command being judged.
CD_PREFIX = re.compile(r"^cd\s+\S+\s*$", re.IGNORECASE)


def is_verification(command: str) -> bool:
    for segment in re.split(r"&&|\|\||;|\n|\|", command):
        stripped = segment.strip()
        if not stripped or CD_PREFIX.match(stripped):
            continue
        if VERIFICATION.match(stripped):
            return True
    return False

REASON = (
    "[evidence-gate] This answer claims completion ('{term}') but no verification "
    "command ran in this session. The oldest rule in the constitution: an \"it "
    "works\" claim carries the command output that proves it; without output it is "
    "a hypothesis.\n\n"
    "Do one of these before answering again:\n"
    "  - run the verification (verify / test / typecheck / lint / selftest) and "
    "show the output, or\n"
    "  - downgrade the claim honestly: \"IMPLEMENTED - NOT VERIFIED\", naming the "
    "exact command the human should run.\n\n"
    "Honest limit of this gate: it proves a command RAN, not that it passed and "
    "not that it covered the claim. Those stay yours (ADR 34)."
)


def ran_verification(transcript_path: str) -> bool:
    """True when a Bash tool call in this session ran something verification-shaped.

    Parsed from the tool calls, never from the prose: a command quoted in an
    answer is data, not evidence. Reading the raw text instead is how a hook
    starts counting its own documentation as proof.
    """
    if not transcript_path or not os.path.exists(transcript_path):
        return False
    try:
        with open(transcript_path, encoding="utf-8", errors="replace") as handle:
            for line in handle:
                if "tool_use" not in line:
                    continue
                try:
                    entry = json.loads(line)
                except json.JSONDecodeError:
                    continue
                content = (entry.get("message") or {}).get("content")
                if not isinstance(content, list):
                    continue
                for block in content:
                    if not isinstance(block, dict) or block.get("type") != "tool_use":
                        continue
                    command = (block.get("input") or {}).get("command") or ""
                    if command and is_verification(command):
                        return True
    except OSError:
        return False
    return False


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, AttributeError):
        return
    if data.get("stop_hook_active"):
        return  # Never block twice: the revised answer must be able to land.
    message = data.get("last_assistant_message") or ""
    if not message or HONEST.search(message):
        return
    match = None
    for pattern in CLAIM:
        match = re.search(pattern, message, re.IGNORECASE)
        if match:
            break
    if not match or ran_verification(data.get("transcript_path") or ""):
        return
    print(json.dumps({
        "decision": "block",
        "reason": REASON.format(term=match.group(0)),
    }))


main()
