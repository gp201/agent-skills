#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_HOME:-$HOME/.claude}"

install_links() {
    local src_dir="$1" dest_dir="$2" kind="$3"
    mkdir -p "$dest_dir"
    local count=0
    for item in "$src_dir"/*; do
        name="${item##*/}"
        target="$dest_dir/$name"
        ln -sf "$item" "$target"
        echo "linked $name -> $target"
        count=$((count + 1))
    done
    echo "done. installed $count $kind to $dest_dir"
}

install_links "$REPO_DIR/agents" "$CLAUDE_DIR/agents" "reviewer agents"
install_links "$REPO_DIR/skills" "$CLAUDE_DIR/commands" "skills"
