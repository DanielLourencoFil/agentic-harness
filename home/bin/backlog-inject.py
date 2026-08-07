#!/usr/bin/env python3
"""SessionStart: inject the cross-project BACKLOG only at the desk (cwd == ~/Dev).

The BACKLOG is the cross-project desk's tool. Injecting it into a PROJECT session
force-feeds unrelated context (including career PII on named third parties) into a
session that should be isolated by design - it contradicts "one project, one
session, one cwd", and it is a real leak vector on a screen-shared interview
(ADR 45, demonstrated live: a career dossier bled into a coding rehearsal).

So it fires only when the session's cwd IS the desk root (~/Dev); in any project
subfolder it stays silent. The file remains the durable cross-project index; only
its delivery is gated, which resolves the constitution's own contradiction
between the isolation rule and the backlog rite.
"""
import json
import os
import sys
from pathlib import Path

HEADER = (
    "== BACKLOG (~/Dev/BACKLOG.md): fonte de verdade das pendencias cross-project. "
    "Consulte antes de propor rumo; todo novo 'depois' entra la antes da sessao acabar. =="
)


def main() -> int:
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        data = {}
    cwd = data.get("cwd") or os.getcwd()
    desk = Path(os.environ["HOME"]) / "Dev"
    backlog = desk / "BACKLOG.md"
    try:
        at_desk = Path(cwd).resolve() == desk.resolve()
    except OSError:
        at_desk = False
    if not at_desk or not backlog.is_file():
        return 0
    print(HEADER)
    print(backlog.read_text(encoding="utf-8", errors="replace"), end="")
    return 0


if __name__ == "__main__":
    sys.exit(main())
