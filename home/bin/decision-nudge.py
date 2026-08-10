#!/usr/bin/env python3
"""decision-nudge: PreToolUse(Write|Edit) nudge (ADR 68). The /decide rite says it
"triggers even unprompted" on an irreversible-blast-radius decision, and until now
nothing fired it: the rite depended on the agent noticing, which is the prayer the
harness exists to kill (Principle 2, externalized memory). deliberation-nudge fires
on the HUMAN's wording, so it only arms once he is already deliberating; this one
fires on the DECISION's shape.

v1 watches one family on purpose - stack and deploy commitments - because the marker
list grows from real misses, never speculatively (the deliberation-nudge rule):

  * always      - Dockerfile, docker-compose*, fly.toml, *.tf, pnpm-workspace.yaml:
                  deploy target and repo shape, touched rarely, locking when touched;
  * dependency- - package.json: edited constantly for scripts and version bumps, so
    gated       firing on every edit would train the reader to ignore it (the reason
                  migrations are NOT watched in v1). Only a dependency change fires.

Nudge, never block: shape detection is heuristic, so a false positive must cost
nothing - the message carries a one-line escape for routine maintenance. Honest
limit: a stack decision taken without touching one of these files is missed entirely.
"""
import json
import re
import sys

# Touched rarely; when touched, the deploy target or the repo's shape is being set.
ALWAYS = (
    re.compile(r"^Dockerfile(\..+)?$"),
    re.compile(r"^docker-compose.*\.ya?ml$"),
    re.compile(r"^fly\.toml$"),
    re.compile(r".+\.tf$"),
    re.compile(r"^pnpm-workspace\.yaml$"),
)
DEP_GATED = ("package.json",)

# A dependency block header, or a package-name-to-semver pair that is not metadata.
# "version": "1.0.1" must NOT fire: a release bump is not a stack decision.
DEP_BLOCK = re.compile(r'"(?:dev|peer|optional)?[Dd]ependencies"')
DEP_PAIR = re.compile(r'"(@?[a-z0-9][\w.@/-]*)"\s*:\s*"[\^~>=<*]?\d[\w.\-+]*"')
META_KEYS = {
    "version", "name", "main", "module", "types", "typings", "license",
    "description", "author", "homepage", "private", "type", "packageManager",
}

NUDGE = (
    "[decision-nudge] This edit touches {what} - a stack/deploy commitment, which"
    " /decide lists as irreversible blast radius. Before writing it: run /decide"
    " (problem, real alternatives with costs, trade-offs, recommendation + when-NOT"
    " + exit cost) and land the dated ADR line in docs/DECISIONS.md. Quantitative"
    " claims in it carry an anchor or the words 'from training, not verified' - the"
    " agent's recall and the human's experience share a corpus, so an unlabelled"
    " number is two correlated guesses. Escape valve: if this is routine maintenance"
    " and not a decision, say so in one line and proceed - do not nag."
)


def dependency_change(tool_input: dict) -> bool:
    """True when the payload being written adds or changes a dependency."""
    text = tool_input.get("content") or tool_input.get("new_string") or ""
    if DEP_BLOCK.search(text):
        return True
    return any(m.group(1) not in META_KEYS for m in DEP_PAIR.finditer(text))


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, AttributeError):
        return
    tool_input = data.get("tool_input") or {}
    path = tool_input.get("file_path") or ""
    # Vendored trees are not decisions: the agent never authors them.
    if "/node_modules/" in path or "/.git/" in path:
        return

    name = path.rsplit("/", 1)[-1]
    what = ""
    if any(p.match(name) for p in ALWAYS):
        what = name
    elif name in DEP_GATED and dependency_change(tool_input):
        what = name + " dependencies"
    if not what:
        return

    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "additionalContext": NUDGE.format(what=what),
        }
    }))


main()
sys.exit(0)
