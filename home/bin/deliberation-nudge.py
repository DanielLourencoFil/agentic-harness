#!/usr/bin/env python3
"""UserPromptSubmit nudge (ADR 19): deliberation markers in the prompt inject a
reminder that evaluation requests end in a REPORT, never a same-turn diff.

A nudge, never a block — false positives must cost nothing (contrast:
secret-scan.py, which blocks). A hook cannot switch the session's permission
mode; the chain is: this reminder fires mechanically (force) -> the agent
enters plan mode (steer, re-armed per firing) -> plan mode blocks edits until
the human approves (force). Marker list grows only from real misses
(harness-candidate discipline), never speculatively.
"""
import json
import re
import sys

MARKERS = [
    r"\be se\b", r"\bconsiderando\b", r"\bimagin[ae]\b", r"\bno caso\b",
    r"\bn[aã]o entendi\b", r"\bestou perdid[oa]\b", r"\bfaz sentido\b",
    r"\bfaria sentido\b", r"\bser[aá] que\b", r"\bo que\s+(voc[eê]\s+)?ach",
    r"\bavali[ae]\b", r"\breporte antes\b",
    r"\bwhat if\b", r"\bconsidering\b", r"\bimagine\b",
    r"\bdoes (it|this) make sense\b", r"\bwhat do you think\b",
    r"\bevaluate\b", r"\bi'?m lost\b", r"\bi don'?t understand\b",
]

NUDGE = (
    "[deliberation-nudge] Deliberation marker detected ('{term}'). Standing "
    "rule (ADR 19): an evaluation request ends in a REPORT — anchored "
    "assessment, options, recommendation — never a same-turn diff. Enter plan "
    "mode (EnterPlanMode) before any Write/Edit and wait for the explicit go. "
    "Escape valve: if this prompt itself is an explicit go on an "
    "already-reported plan, proceed."
)


def main() -> None:
    try:
        prompt = json.load(sys.stdin).get("prompt", "")
    except (json.JSONDecodeError, AttributeError):
        return
    low = prompt.lower()
    for pattern in MARKERS:
        match = re.search(pattern, low)
        if match:
            print(NUDGE.format(term=match.group(0)))
            return


main()
