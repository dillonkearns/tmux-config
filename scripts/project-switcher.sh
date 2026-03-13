#!/usr/bin/env bash
# project-switcher.sh
# Fuzzy-find a project in ~/src/github.com/dillonkearns/ and open/switch to
# a tmux session named after it.
#
# Usage: called from tmux keybinding (Prefix + f)

PROJECTS_DIR="$HOME/src/github.com/dillonkearns"

# List directories only (the repos), pipe to fzf
selected=$(find "$PROJECTS_DIR" -mindepth 1 -maxdepth 1 -type d | \
    sed "s|$PROJECTS_DIR/||" | \
    sort | \
    fzf --prompt="project> " \
        --height=100% \
        --layout=reverse \
        --border=none \
        --info=hidden \
        --no-scrollbar)

# If nothing selected, exit
if [ -z "$selected" ]; then
    exit 0
fi

# Session name: replace dots with underscores (tmux doesn't like dots in names)
session_name=$(echo "$selected" | tr '.' '_')
project_path="$PROJECTS_DIR/$selected"

# If session exists, switch to it. Otherwise create it.
if tmux has-session -t="$session_name" 2>/dev/null; then
    tmux switch-client -t "$session_name"
else
    tmux new-session -d -s "$session_name" -c "$project_path"
    tmux switch-client -t "$session_name"
fi
