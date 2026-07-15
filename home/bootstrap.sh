#!/bin/sh
# home layer bootstrap: symlink the machine layer into place. Idempotent.
# POSIX sh; targets Linux and macOS (Windows = WSL, always).
set -eu

HOME_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

link() {
  target=$1
  linkpath=$2
  if [ -e "$linkpath" ] && [ ! -L "$linkpath" ]; then
    mv "$linkpath" "$linkpath.pre-bootstrap.bak"
    echo "backup: $linkpath -> $linkpath.pre-bootstrap.bak"
  fi
  ln -sfn "$target" "$linkpath"
  echo "link:   $linkpath -> $target"
}

mkdir -p "$HOME/Dev" "$HOME/.claude/skills"

link "$HOME_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
link "$HOME_DIR/claude/settings.json" "$HOME/.claude/settings.json"

for skill in "$HOME_DIR"/skills/*/; do
  name=$(basename "$skill")
  link "${skill%/}" "$HOME/.claude/skills/$name"
done

# Data repo (optional sibling of this harness clone): backlog + career linked
# into the workspace root. Career rituals (e.g. /teach) live there, with the data.
ORGANIZER="$(dirname "$(dirname "$HOME_DIR")")/organizer"
if [ -d "$ORGANIZER" ]; then
  link "$ORGANIZER/BACKLOG.md" "$HOME/Dev/BACKLOG.md"
  link "$ORGANIZER/career" "$HOME/Dev/career"
else
  echo "note:   organizer not found at $ORGANIZER; data links skipped"
fi

echo "bootstrap complete"
