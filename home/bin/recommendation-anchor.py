#!/usr/bin/env python3
"""Stop hook (ADR 30): a recommendation must declare what verified it.

Trigger, 2026-08-04: three recommendations in one session were made from what
seemed reasonable instead of from measurement (cut the `workflow` scope, which
turned out to be required for pushing workflow files; cut the `gist` scope,
which `gh` does not permit removing and which closes nothing while `repo` can
publish; adopt a permissive permission mode, which contradicts the harness's own
premise). The anchoring law already covered this, and was read narrowly as
applying to claims "about a repo" while the failures were about a GitHub account
and a permission model.

What this checks: a message that recommends must also carry a line declaring the
evidence, in the closed set below. It does NOT check that the declaration is
true, nor that the measurement covers the claim. It forces the author to write
the line, which is the moment the absence becomes visible. Honest label:
half-force. The firing is mechanical; the honesty of the label stays steer, like
every other semantic half in this harness.

Known blind spot, stated so nobody mistakes the scope: it cannot catch a
recommendation whose premise WAS measured but whose consequence was not. Two of
the three failures above were exactly that, and would have been caught only
because writing "Verificado:" with nothing to put after it is hard to do without
noticing.

Blocks once per turn: `stop_hook_active` is honored so a revised answer is never
trapped in a loop.
"""
import json
import re
import sys

RECOMMENDATION = [
    r"\brecomendo\b", r"\brecomendaria\b", r"\bsugiro\b", r"\bsugeria\b",
    r"\bproponho\b", r"\baconselho\b", r"\bdevias\b", r"\bdeverias\b",
    r"\bo que eu faria\b", r"\bfaria a\b", r"\bo que eu diria\b",
    r"\bi recommend\b", r"\bi'?d recommend\b", r"\bi suggest\b",
    r"\bi'?d suggest\b", r"\bmy recommendation\b", r"\byou should\b",
    r"\bwhat i'?d do\b",
]

# The closed set of evidence declarations. "Not verified" counts: labeling an
# unverified recommendation honestly is compliance, not evasion.
DECLARATION = re.compile(
    r"^\s*(?:[-*>]\s*)?(?:\*\*)?"
    r"(verificado|medido|n[aã]o verificado|hip[oó]tese|por verificar"
    r"|verified|measured|not verified|hypothesis|unverified)"
    r"(?:\*\*)?\s*:",
    re.IGNORECASE | re.MULTILINE,
)

REASON = (
    "[recommendation-anchor] This answer recommends ('{term}') without declaring "
    "what verified it. Anchoring law, and it is not scoped to repositories: a "
    "recommendation carries the command or path that checked its precondition, "
    "or it carries an honest label saying it did not.\n\n"
    "Add one line per recommendation, using the closed set:\n"
    "  Verificado: <command or path that proves the precondition>\n"
    "  Medido: <what was measured, and the result>\n"
    "  Não verificado: <what would have to be checked first>\n"
    "  Hipótese: <the claim, marked as unchecked>\n\n"
    "If the line cannot be written because nothing was checked, that is the "
    "finding: measure first, or say plainly that there is nothing to recommend "
    "yet. A recommendation invented to give the turn a next step is the failure "
    "this hook exists for (ADR 30)."
)


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, AttributeError):
        return
    # Never block twice on the same turn: the revised answer must be able to land.
    if data.get("stop_hook_active"):
        return
    message = data.get("last_assistant_message") or ""
    if not message or DECLARATION.search(message):
        return
    for pattern in RECOMMENDATION:
        match = re.search(pattern, message, re.IGNORECASE)
        if match:
            print(json.dumps({
                "decision": "block",
                "reason": REASON.format(term=match.group(0)),
            }))
            return


main()
