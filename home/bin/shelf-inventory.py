#!/usr/bin/env python3
"""PreToolUse(Write) shelf gate (ADR 31): creating a new file on a shared shelf
stops for the human, and hands the agent the inventory of what is already there.

The rule "scan the shelf before writing a new component" is pure steer, and it
leans on the agent remembering to look. This makes the moment mechanical: a NEW
file inside a configured shelf pauses, and the shelf's contents reach the agent,
which relays them in prose.

Measured on 5 probe runs, 2026-08-04, because the obvious design does not work:
  - `permissionDecision: "ask"` reaches the human and stops the write. Works.
  - `permissionDecisionReason` NEVER reaches the human on a file operation: the
    IDE diff takes that space. 874 characters emitted, zero seen, five times. So
    the inventory cannot travel there, and the reason below stays one line.
  - `additionalContext` DOES reach the agent, alongside "ask". That is the only
    channel that carries the list, and the agent then explains it far better than
    a 39-line prompt would.

Config lives in the project: `.claude/shelf.json`, absent by default, so a
project without a shelf convention never sees this hook. Shape:

    {"shelves": [{"path": "src/components/ui", "minEntries": 10}]}

`minEntries` exists because the firing profile is the inverse of the usefulness
profile. On the reference repo 81% of new shelf files landed in the first three
months, while the shelf was being built and had nothing to duplicate; steady
state is about one per month. Below the threshold the hook is noise.

The context deliberately names the shelf PATH and forbids searching elsewhere.
Both probe runs where it carried names alone sent the agent hunting for the
source: one swept ~/Dev, the other walked into a different project entirely and
tried to read its components. Bash is uncontained (ADR 29), so nothing stopped
it but a permission prompt. A shelf hook that pushes an agent into a sibling
project would import that project's conventions by accident, which is worse than
the duplication it set out to prevent.
"""
import json
import os
import sys

MAX_LISTED = 60


def emit(reason: str, context: str) -> None:
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "ask",
            "permissionDecisionReason": reason,
            "additionalContext": context,
        }
    }))


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, AttributeError):
        return

    target = (data.get("tool_input") or {}).get("file_path") or ""
    if not target:
        return

    root = os.environ.get("CLAUDE_PROJECT_DIR") or data.get("cwd") or ""
    if not root:
        return
    root = os.path.realpath(root)

    if not os.path.isabs(target):
        target = os.path.join(data.get("cwd") or root, target)
    target = os.path.realpath(target)

    # Creation only. An edit of an existing file is not the moment this exists for.
    if os.path.exists(target):
        return

    try:
        with open(os.path.join(root, ".claude", "shelf.json"), encoding="utf-8") as fh:
            shelves = json.load(fh).get("shelves") or []
    except (OSError, json.JSONDecodeError):
        return  # No config, or broken config: inert, never a false positive.

    for shelf in shelves:
        path = shelf.get("path")
        if not path:
            continue
        shelf_dir = os.path.realpath(os.path.join(root, path))
        # Direct children only: a nested dir is its own concern, not this shelf.
        if os.path.dirname(target) != shelf_dir:
            continue
        try:
            entries = sorted(
                os.path.splitext(name)[0]
                for name in os.listdir(shelf_dir)
                if os.path.isfile(os.path.join(shelf_dir, name))
            )
        except OSError:
            continue
        if len(entries) < int(shelf.get("minEntries", 10)):
            continue

        listing = "\n".join(f"  - {name}" for name in entries[:MAX_LISTED])
        if len(entries) > MAX_LISTED:
            listing += f"\n  ... and {len(entries) - MAX_LISTED} more"
        emit(
            f"New file on the shared shelf {path} ({len(entries)} already there).",
            (
                f"[shelf] {os.path.basename(target)} is a NEW file on a shared"
                f" shelf. {len(entries)} entries already live in {path}:\n"
                f"{listing}\n\n"
                "Before continuing, tell the human plainly whether any of these"
                " already does what was asked under a different name, and if so"
                " propose reusing it instead of creating.\n"
                f"Read them from {path} inside THIS project. Do not search other"
                " directories and never another project: a shelf check that walks"
                " into a sibling repo imports its conventions by accident, which"
                " is worse than the duplication it was meant to prevent."
            ),
        )
        return


main()
