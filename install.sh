#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/agents" && pwd)"
CLAUDE_DIR="${CLAUDE_HOME:-$HOME/.claude}"
DEST_DIR="$CLAUDE_DIR/agents"

mkdir -p "$DEST_DIR"

for agent in "$SRC_DIR"/*.md; do
    name="$(basename "$agent")"
    target="$DEST_DIR/$name"
    if [ -L "$target" ] || [ -e "$target" ]; then
        rm -rf "$target"
    fi
    ln -s "$agent" "$target"
    echo "linked $name -> $target"
done

echo "done. installed $(ls -1 "$SRC_DIR" | wc -l) agents to $DEST_DIR"
