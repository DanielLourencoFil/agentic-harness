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

COMPOUND COMMANDS (ADR 70). A command is judged by EVERY push it contains, not by
the first `git push` substring in it, and the strictest verdict wins. The first
version read one occurrence anywhere in the string, which failed both ways: it
denied its own documentation (the phrase inside an echo) and, worse, allowed
`echo ... && git push origin main`, because the decoy moved the analysis onto the
mention's trailing tokens. Quoted regions and comments are data; a quoted refspec
is not (`git push origin "main"` names the default branch and was allowed by the
raw-token comparison all along).

Declared limit: HEREDOC bodies still read as command text, so a commit message or
PR body mentioning a default-branch push is denied. Left unfixed on purpose - a
mis-parsed heredoc would blank real command text and HIDE a push, which is the
unsafe direction, while the current behaviour only over-blocks. It earns its own
round with its own tests (harness-candidate, AGENT-LOG).
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


def scrub_data(cmd: str) -> str:
    """Blank out quoted regions and comments, so a `git push` that is only DATA
    stops reading as an invocation. Offsets are preserved (blanks, not deletion).

    Why this exists (ADR 70): the first version matched `git push` anywhere in
    the command. That produced BOTH failure directions. False positive: the
    sentence documenting the guard, inside an echo, was denied. False negative,
    the serious one: it read only the FIRST occurrence, so a mention before the
    real invocation moved the analysis onto the mention's trailing tokens and a
    push to the default branch was allowed. audit-reminder.py learned the same
    lesson on 2026-07-20; this is that lesson applied here.

    Unbalanced quotes return the command untouched: analysing too much denies,
    which is the safe direction for a guard that walls the default branch.
    """
    out = []
    quote = None
    in_comment = False
    prev = ""
    for ch in cmd:
        if in_comment:
            in_comment = ch != "\n"
            out.append(ch if ch == "\n" else " ")
        elif quote:
            out.append(ch if ch == quote else " ")
            if ch == quote:
                quote = None
        elif ch in "'\"":
            quote = ch
            out.append(ch)
        # `#` opens a comment only at the start of a word, never inside one.
        elif ch == "#" and (prev == "" or prev.isspace()):
            in_comment = True
            out.append(" ")
        else:
            out.append(ch)
        prev = ch
    return cmd if quote else "".join(out)


def push_invocations(cmd: str):
    """Argument tokens of EVERY real `git push` in the command; [] if there is none.

    Every occurrence is analysed, not just the first: a compound command can
    carry a decoy mention and a real push, and the real one is what matters.
    """
    scrubbed = scrub_data(cmd)
    out = []
    for m in re.finditer(r"\bgit\s+push\b", scrubbed):
        # scrub_data preserves offsets, so the INVOCATION is located in the
        # scrubbed copy but its ARGUMENTS are read from the ORIGINAL command: a
        # refspec may legally be quoted, and reading them scrubbed would blank
        # exactly the branch name this guard exists to see. Quotes are then
        # stripped per token - a pre-existing hole, since the first version
        # compared raw tokens, so `"main"` never equalled `main` (ADR 70).
        chunk = re.split(r"[;&|\n]", cmd[m.end():])[0]
        out.append([t.strip("\"'") for t in chunk.split()])
    return out


def verdict(args, head):
    """("deny"|"ask", reason) for one push invocation, or None when it is clear."""
    # 1) A destination that explicitly names a default branch, in any form:
    #    `origin main`, `main:main`, `HEAD:main`, `+main`, `-u origin master`.
    for a in args:
        for br in DEFAULTS:
            if a == br or a == "+" + br or a.endswith(":" + br):
                return (
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
        if head is None:
            return (
                "ask",
                "push-guard: could not resolve the target branch of this push - "
                "confirm it does not reach the default branch.",
            )
        if head in DEFAULTS:
            return (
                "deny",
                f"push-guard: HEAD is '{head}' (the default branch) and this push has no "
                "explicit work-branch target, so it would push to the default branch. "
                "Checkout a work branch first.",
            )
    return None


def main() -> int:
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0
    if data.get("tool_name") != "Bash":
        return 0
    invocations = push_invocations((data.get("tool_input") or {}).get("command", ""))
    if not invocations:
        return 0

    # Every invocation is judged; the strictest verdict wins. A compound command
    # is as dangerous as its worst push, and a clear one earlier in the line
    # never licenses a default-branch one later.
    head = current_branch()
    strictest = None
    for args in invocations:
        v = verdict(args, head)
        if v and v[0] == "deny":
            return decide(*v)
        if v and strictest is None:
            strictest = v
    if strictest:
        return decide(*strictest)
    return 0  # clear work-branch push -> allowed silently


if __name__ == "__main__":
    sys.exit(main())
