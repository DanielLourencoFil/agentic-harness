#!/usr/bin/env python3
"""PreToolUse(Bash): deny a git push that would reach the default branch.

The project settings blocklist ("git push origin main" ...) is leaky: a bare
`git push` on main, `git push -u origin main`, `git push origin +main`, and
`git push origin HEAD` all slip through the fixed string patterns and reach the
default branch unasked (ADR 46). This resolves the ACTUAL target of the push
instead of matching strings:
  - DENY if a destination names a default branch (main/master), OR the push has
    no explicit work-branch target while HEAD is a default branch;
  - ASK if it is a git push whose target cannot be determined (fail safe);
  - otherwise stay silent - a clear work-branch push, allowed by the git rite.
Machine-layer, so it protects EVERY repo, including a foreign interview repo with
no server-side branch protection - the exact case the blocklist misses.
"""
import json
import re
import subprocess
import sys

DEFAULTS = ("main", "master")


def decide(kind: str, reason: str) -> int:
    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": kind,
                    "permissionDecisionReason": reason,
                }
            }
        )
    )
    return 0


def current_branch():
    try:
        out = subprocess.run(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        return out.stdout.strip() if out.returncode == 0 else None
    except (OSError, subprocess.SubprocessError):
        return None


def push_args(cmd: str):
    """Tokens after the first `git push`; None if the command is not a git push."""
    m = re.search(r"\bgit\s+push\b(.*)", cmd)
    if not m:
        return None
    return re.split(r"[;&|]", m.group(1))[0].split()


def main() -> int:
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0
    if data.get("tool_name") != "Bash":
        return 0
    args = push_args((data.get("tool_input") or {}).get("command", ""))
    if args is None:
        return 0

    # 1) A destination that explicitly names a default branch, in any form:
    #    `origin main`, `main:main`, `HEAD:main`, `+main`, `-u origin master`.
    for a in args:
        for br in DEFAULTS:
            if a == br or a == "+" + br or a.endswith(":" + br):
                return decide(
                    "deny",
                    f"push-guard: this git push targets '{br}', the default branch. "
                    "Open a PR - merging to the default branch is the human's act.",
                )

    # 2) No explicit work-branch refspec -> the push carries the CURRENT branch.
    #    (`git push`, `git push origin`, `git push origin HEAD` all do this.)
    non_flags = [a for a in args if not a.startswith("-")]
    refspecs = non_flags[1:]  # everything after the remote token
    carries_current = (not refspecs) or any(r == "HEAD" for r in refspecs)
    if carries_current:
        br = current_branch()
        if br is None:
            return decide(
                "ask",
                "push-guard: could not resolve the target branch of this push - "
                "confirm it does not reach the default branch.",
            )
        if br in DEFAULTS:
            return decide(
                "deny",
                f"push-guard: HEAD is '{br}' (the default branch) and this push has no "
                "explicit work-branch target, so it would push to the default branch. "
                "Checkout a work branch first.",
            )
    return 0  # clear work-branch push -> allowed silently


if __name__ == "__main__":
    sys.exit(main())
