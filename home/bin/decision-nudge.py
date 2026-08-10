#!/usr/bin/env python3
"""decision-nudge: PreToolUse(Write|Edit) nudge (ADR 68, hardened by ADR 69). The
/decide rite says it "triggers even unprompted" on an irreversible-blast-radius
decision, and until now nothing fired it: the rite depended on the agent noticing,
which is the prayer the harness exists to kill (Principle 2, externalized memory).
deliberation-nudge fires on the HUMAN's wording, so it only arms once he is already
deliberating; this one fires on the DECISION's shape.

v1 watches one family on purpose - stack and deploy commitments - because the marker
list grows from real misses, never speculatively (the deliberation-nudge rule):

  * always      - Dockerfile (any environment prefix or suffix), compose and
                  docker-compose files, fly.toml, *.tf, pnpm-workspace.yaml: the
                  deploy target and the repo's shape, touched rarely, locking when
                  touched;
  * manifests   - package.json. Authoring the WHOLE file is the stack decision
                  itself, so a payload carrying `content` always fires. An Edit
                  fragment is dependency-gated: it fires only when the text adds or
                  changes a dependency, because a manifest is edited constantly for
                  scripts and version bumps and a nudge on every edit trains the
                  reader to ignore it (the ADR 10 lesson, and the reason migrations
                  are NOT watched in v1).

Nudge, never block: shape detection is heuristic, so a false positive must cost
nothing - the message carries a one-line escape for routine maintenance. Honest
limits: a stack decision taken without touching one of these files is missed
entirely, and an `engines` constraint reads as a dependency (deliberate - a pinned
runtime version is a stack commitment).
"""
import json
import re
import sys

# Touched rarely; when touched, the deploy target or the repo's shape is being set.
# Both compose spellings: V2's documented default file is compose.yaml, and a
# marker knowing only the legacy prefix is a naming gap (audit 2026-08-10).
ALWAYS = (
    re.compile(r"^(.+\.)?Dockerfile(\..+)?$"),
    re.compile(r"^(docker-)?compose.*\.ya?ml$"),
    re.compile(r"^fly\.toml$"),
    re.compile(r".+\.tf$"),
    re.compile(r"^pnpm-workspace\.yaml$"),
)
MANIFESTS = ("package.json",)

# A package-name-to-spec pair. The spec alternatives cover semver ranges AND the
# non-numeric forms a narrower regex missed: workspace:* is the canonical pnpm
# form, in the very repo family this hook watches (audit 2026-08-10).
DEP_PAIR = re.compile(
    r'"(@?[a-z0-9][\w.@/-]*)"\s*:\s*"'
    r'(?:[\^~]?\d|[><]=?\d|\*"|latest"|(?:workspace|npm|file|link|github|catalog):|git\+)'
)
# Metadata whose value is itself semver-shaped. Kept to exactly what the regex can
# actually reach: a longer list reads as a broad guard while being dead code.
META_KEYS = {"version"}


def dependency_change(text: str) -> bool:
    """True when an edit fragment adds or changes a dependency."""
    return any(m.group(1) not in META_KEYS for m in DEP_PAIR.finditer(text))


def commitment(tool_input: dict) -> str:
    """Name the stack/deploy commitment this payload makes, or "" for none."""
    path = tool_input.get("file_path")
    if not isinstance(path, str):
        return ""
    # Vendored trees are not decisions: the agent never authors them.
    if "node_modules/" in path or "/.git/" in path:
        return ""

    name = path.rsplit("/", 1)[-1]
    if any(p.match(name) for p in ALWAYS):
        return name
    if name in MANIFESTS:
        # `content` = the whole file is being authored, which IS the decision.
        # `new_string` = a fragment, so gate it on a dependency actually changing.
        if isinstance(tool_input.get("content"), str):
            return name
        fragment = tool_input.get("new_string")
        if isinstance(fragment, str) and dependency_change(fragment):
            return name + " dependencies"
    return ""


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


def main() -> None:
    # A hook is fed whatever the tool layer sends. Anything unreadable means
    # "no decision visible", never a traceback: stderr noise on every call is
    # what the reader learns to skip, and a crashing hook silently satisfies
    # every silence assertion a test can write (audit 2026-08-10).
    try:
        data = json.load(sys.stdin)
        tool_input = data.get("tool_input")
        what = commitment(tool_input) if isinstance(tool_input, dict) else ""
    except (json.JSONDecodeError, AttributeError, TypeError, ValueError):
        return
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
