# home/ — the machine layer

The harness has two delivery targets. `templates/` stamps **projects**: gates and
rites copied into each new repo at kickoff, versioned with that project's git.
This directory equips the **machine**: the rules that must hold in *every* session,
including sessions with no project at all — a planning conversation, a third-party
repo where you are a guest, an empty folder. One clone plus one script, and any
machine (Linux, macOS, or Windows via WSL) works exactly like the last one, before
the first prompt.

The delivery mechanism is the point: project rules are *copied per project*;
machine rules are *symlinked once per machine* into `~/.claude`. Same method,
two scopes. (Why some rules cannot live in project stamps: the secret-hygiene
hooks below must fire in sessions that have no project to carry them.)

## Contents

- `claude/CLAUDE.md`: the constitution. Global rules loaded in every session, every
  folder: values, git rite, backlog rite, secret hygiene, session scoping.
- `claude/settings.json`: user-level permissions and hooks — the secret-scan gate
  on every prompt, the env-dump guard on every shell command (accident nets, not
  adversarial defense; see `bin/`), and the write-containment gate on every file
  edit (ADR 10: a file-tool write whose real path — symlinks and `../` resolved —
  lands outside the project root is denied; named allowlist: agent memory,
  session scratchpad. Honest limit: binds the file tools, not Bash).
- `bin/`: the hook scripts. Pipe-testable in isolation, no Claude required;
  `scripts/selftest-home.sh` does exactly that in CI, negative cases included.
- `skills/`: the conversation rituals — formats only the conversation obeys, so
  they live here, not in project stamps (rites the *repo* obeys, `/feature` and
  `/audit`, ship in `templates/`):
  - `decide`: architecture deliberation in the write-up standard (real
    alternatives, trade-offs, when-NOT, a paste-ready ADR line).
  - `checklist`: non-code workflows only; code plans are views over tests.
- `bootstrap.sh`: symlinks the above into `~/.claude` and creates `~/Dev`.
  Idempotent; run it again after any change here.

This is my reference implementation of the layer, personal defaults included —
fork the contents, keep the mechanism. Career-specific rituals and personal data
live elsewhere by design (a private data repo, linked by the bootstrap when
present as a sibling); nothing machine-local (credentials, agent memory, session
caches) ever enters this repo.

## New machine

1. Prerequisites: git, gh, Claude Code. On Windows: WSL first, always.
2. `git clone https://github.com/DanielLourencoFil/agentic-harness ~/Dev/agentic-harness`
3. `sh ~/Dev/agentic-harness/home/bootstrap.sh`
