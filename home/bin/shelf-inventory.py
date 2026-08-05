#!/usr/bin/env python3
"""PreToolUse(Write) shelf gate (ADR 31): creating a new file on a shared shelf
stops for the human, and hands the agent the inventory of what is already there.

The rule "scan the shelf before writing a new component" is pure steer, and it
leans on the agent remembering to look. This makes the moment mechanical.

WHY IT AUTO-DETECTS. The first version required `.claude/shelf.json` per
project, which traded "the agent must remember to look" for "the human must
remember to declare" — the same disease renamed, and the owner said so. A
directory is now judged by two measured signals, no naming convention and no
setup:

  1. it holds at least MIN_ENTRIES files (something worth duplicating), and
  2. at least MIN_IMPORTERS distinct directories import from it (genuinely
     shared, rather than local to one screen).

Both are needed. Measured on the reference repo across 18 sibling directories:
`ui` (39 files, fan-in 63) and `booking` (30, 16) are real shelves; `landing`
(28, 2) and `public-page` (14, 2) hold just as many files but serve one screen,
and a file-count rule alone fires on them. Fan-in alone would catch
`platform-admin` (6 files, fan-in 13), where there is barely anything to
duplicate. Together the pair fires twice out of eighteen, both correct.

HOW THE CHANNELS WORK, measured over 5 probe runs on 2026-08-04, because the
obvious design does not work:
  - `permissionDecision: "ask"` reaches the human and stops the write. Works.
  - `permissionDecisionReason` NEVER reaches the human on a file operation: the
    IDE diff takes that space. 874 characters emitted, zero seen, five times.
  - `additionalContext` DOES reach the agent alongside "ask". That is the only
    channel that carries the list, and the agent relays it far better than a
    39-line permission dialog would.

DECLARED LIMIT, and it fails closed. Fan-in is counted by grepping for import
statements shaped like JS/TS. In a project whose imports it cannot read (Python,
Go, relative-only paths it does not match), fan-in reads as zero and the hook
stays inert: no false positives, no protection. `.claude/shelf.json` is the
override for those, and for any project that wants this off:

    {"shelves": [{"path": "src/components/ui"}]}   explicit shelves
    {"shelves": []}                                 disabled
"""
import json
import os
import re
import subprocess
import sys

MIN_ENTRIES = 10
MIN_IMPORTERS = 10
MAX_LISTED = 60
SKIP_DIRS = {".git", "node_modules", ".next", "dist", "build", "coverage", ".claude"}
SOURCE_SUFFIXES = (".ts", ".tsx", ".js", ".jsx", ".mjs", ".vue", ".svelte")


def entries_in(directory):
    try:
        return sorted(
            os.path.splitext(name)[0]
            for name in os.listdir(directory)
            if os.path.isfile(os.path.join(directory, name))
        )
    except OSError:
        return []


def import_needle(root, directory):
    """The path fragment an import of this directory would contain.

    Everything after the last `src` segment, because that is what the usual
    alias maps to: with `"@/*": ["./src/*"]`, the directory `apps/web/src/lib`
    is imported as `@/lib/...`, so a needle of `src/lib` finds nothing. Measured:
    that exact miss left a 46-file, fan-in-88 shelf undetected.

    Without a `src` segment, two path segments (`components/ui`), because one is
    too loose: a bare `ui` matches half the tree. The alias prefix (`@/`, `~/`,
    `../`) stays unanchored, which is what lets one needle match
    `@/components/ui` and `../../components/ui` alike.
    """
    relative = os.path.relpath(directory, root)
    parts = [p for p in relative.split(os.sep) if p not in (".", "")]
    if not parts:
        return ""
    if "src" in parts:
        after_src = parts[parts.index("src") + 1:]
        if after_src:
            return "/".join(after_src)
    return "/".join(parts[-2:]) if len(parts) >= 2 else parts[0]


def importer_directories(root, directory):
    """Distinct directories, outside `directory`, importing from it."""
    needle = import_needle(root, directory)
    if not needle:
        return 0
    pattern = r"""from ['"][^'"]*""" + re.escape(needle) + "/"
    try:
        found = subprocess.run(
            ["grep", "-rlE", pattern, root,
             *(f"--exclude-dir={d}" for d in SKIP_DIRS),
             *(f"--include=*{s}" for s in SOURCE_SUFFIXES)],
            capture_output=True, text=True, timeout=8,
        ).stdout.split("\n")
    except (OSError, subprocess.SubprocessError):
        return 0  # Cannot read this project's imports: stay inert, fail closed.
    dirs = {
        os.path.dirname(path) for path in found
        if path.strip() and os.path.dirname(path) != directory
    }
    return len(dirs)


def configured_shelves(root):
    """Explicit config, or None when the project has not spoken."""
    try:
        with open(os.path.join(root, ".claude", "shelf.json"), encoding="utf-8") as fh:
            shelves = json.load(fh).get("shelves")
    except (OSError, json.JSONDecodeError):
        return None
    if not isinstance(shelves, list):
        return None
    return [os.path.realpath(os.path.join(root, s["path"]))
            for s in shelves if isinstance(s, dict) and s.get("path")]


def is_shelf(root, directory, declared):
    if declared is not None:
        return directory in declared  # Explicit config wins, empty list disables.
    if len(entries_in(directory)) < MIN_ENTRIES:
        return False
    return importer_directories(root, directory) >= MIN_IMPORTERS


def main():
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, AttributeError):
        return
    target = (data.get("tool_input") or {}).get("file_path") or ""
    root = os.environ.get("CLAUDE_PROJECT_DIR") or data.get("cwd") or ""
    if not target or not root:
        return
    root = os.path.realpath(root)
    if not os.path.isabs(target):
        target = os.path.join(data.get("cwd") or root, target)
    target = os.path.realpath(target)

    # Creation only: editing an existing file is not the moment this exists for.
    if os.path.exists(target):
        return
    directory = os.path.dirname(target)
    if os.path.commonpath([directory, root]) != root:
        return
    if any(part in SKIP_DIRS for part in os.path.relpath(directory, root).split(os.sep)):
        return
    if not is_shelf(root, directory, configured_shelves(root)):
        return

    entries = entries_in(directory)
    shown = "\n".join(f"  - {name}" for name in entries[:MAX_LISTED])
    if len(entries) > MAX_LISTED:
        shown += f"\n  ... and {len(entries) - MAX_LISTED} more"
    where = os.path.relpath(directory, root)
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "ask",
            "permissionDecisionReason": (
                f"New file on the shared shelf {where} ({len(entries)} already there)."
            ),
            "additionalContext": (
                f"[shelf] {os.path.basename(target)} is a NEW file in {where},"
                f" which {len(entries)} files already share and many parts of this"
                f" project import from:\n{shown}\n\n"
                "Before continuing, tell the human plainly whether any of these"
                " already does what was asked under a different name, and if so"
                " propose reusing it instead of creating.\n"
                f"Read them from {where} inside THIS project. Do not search other"
                " directories and never another project: a shelf check that walks"
                " into a sibling repo imports its conventions by accident, which"
                " is worse than the duplication it was meant to prevent."
            ),
        }
    }))


main()
