#!/usr/bin/env python3
"""SessionStart: activate git-tracked skills, warn on untracked drops.

A skill lives in home/skills/<name>/ and only loads once symlinked into
~/.claude/skills/<name>. That link is created by home/bootstrap.sh, run by hand
- so a skill added after the last bootstrap is born dead: tracked and indexed,
but never linked, invisible to every gate (CI cannot see the user's live
~/.claude symlinks). The /plan rite sat dead this way for 17 days (ADR 43).

This closes the gap without depending on memory, and without re-opening the one
the /absorb quarry deletion closed:
  - a git-TRACKED skill missing its link is AUTO-LINKED (force): committed means
    it passed the commit gate, so activating it is safe;
  - an UNTRACKED dir in home/skills is WARNED, never auto-linked (half-force): a
    foreign drop-in has not been vetted - the human vets+commits it or deletes
    it. "present in home/skills" is not "should be active".

Idempotent: it acts only on what is missing. Never clobbers a real dir sitting
where a link should go - that is surfaced, not overwritten (anti-destruction).
"""
import os
import subprocess
import sys
from pathlib import Path


def harness_dir() -> Path:
    # Overridable for the selftest, which plants a fake repo; else derived from
    # this file's place in the tree (home/bin/skill-activation.py).
    env = os.environ.get("AGENTIC_HARNESS_DIR")
    return Path(env).resolve() if env else Path(__file__).resolve().parents[2]


def tracked_skills(root: Path) -> "set[str]":
    try:
        out = subprocess.run(
            ["git", "-C", str(root), "ls-files", "-z", "--", "home/skills"],
            capture_output=True,
            text=True,
            timeout=5,
        ).stdout
    except (OSError, subprocess.SubprocessError):
        return set()
    names = set()
    for path in out.split("\0"):
        parts = path.split("/")
        # Only the tracked SKILL.md itself vets the dir: a tracked sibling
        # (README, asset) is not "committed means it passed the commit gate"
        # (ADR 43/44). Exactly 4 parts: home/skills/<name>/SKILL.md.
        if (
            len(parts) == 4
            and parts[0] == "home"
            and parts[1] == "skills"
            and parts[3] == "SKILL.md"
        ):
            names.add(parts[2])
    return names


def main() -> int:
    root = harness_dir()
    src = root / "home" / "skills"
    dst_dir = Path(os.environ["HOME"]) / ".claude" / "skills"
    if not src.is_dir():
        return 0

    tracked = tracked_skills(root)
    activated, untracked, blocked = [], [], []

    for entry in sorted(src.iterdir()):
        if not (entry / "SKILL.md").is_file():
            continue
        name = entry.name
        dst = dst_dir / name
        if name not in tracked:
            untracked.append(name)
            continue
        if dst.is_symlink() and dst.resolve() == entry.resolve():
            continue  # already active
        if dst.exists() and not dst.is_symlink():
            blocked.append(name)  # a real dir/file squats the slot - do not clobber
            continue
        dst_dir.mkdir(parents=True, exist_ok=True)
        if dst.is_symlink():
            dst.unlink()  # a stale/broken link
        os.symlink(entry.resolve(), dst)
        activated.append(name)

    lines = []
    if activated:
        lines.append(
            "[skill-activation] Linked tracked skills that were not active: "
            + ", ".join(activated) + "."
        )
    if untracked:
        lines.append(
            "[skill-activation] Untracked dirs in home/skills, NOT auto-activated "
            "(vet and commit, or delete): " + ", ".join(untracked) + "."
        )
    if blocked:
        lines.append(
            "[skill-activation] Could not link (a non-symlink already occupies the "
            "slot in ~/.claude/skills): " + ", ".join(blocked) + "."
        )
    if lines:
        print("\n".join(lines))
    return 0


if __name__ == "__main__":
    sys.exit(main())
