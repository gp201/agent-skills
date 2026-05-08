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
install_links "$REPO_DIR/skills" "$CLAUDE_DIR/skills" "skills"

ensure_attribution() {
    local settings_file="$CLAUDE_DIR/settings.json"
    if ! command -v jq >/dev/null 2>&1; then
        echo "jq not found; skipping attribution block in $settings_file" >&2
        return
    fi
    [ -f "$settings_file" ] || echo '{}' > "$settings_file"
    local tmp
    tmp="$(mktemp "$CLAUDE_DIR/.settings.json.XXXXXX")"
    jq '.attribution.commit //= "" | .attribution.pr //= ""' \
        "$settings_file" > "$tmp"
    mv "$tmp" "$settings_file"
    echo "ensured attribution block in $settings_file"
}

ensure_attribution
