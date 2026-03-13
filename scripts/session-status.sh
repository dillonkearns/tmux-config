#!/usr/bin/env bash
# session-status.sh
# Show status of all tmux sessions with git info.
# Useful as a quick dashboard to see what's going on across projects.
#
# Usage: run directly, or bind to a tmux key

PROJECTS_DIR="$HOME/src/github.com/dillonkearns"

printf "%-25s %-12s %-8s %s\n" "SESSION" "BRANCH" "DIRTY?" "WINDOWS"
printf "%-25s %-12s %-8s %s\n" "-------" "------" "------" "-------"

tmux list-sessions -F '#{session_name}:#{session_path}:#{session_windows}' 2>/dev/null | while IFS=: read -r name path windows; do
    # Try to get git info from the session's starting directory
    branch=""
    dirty=""

    if [ -d "$path/.git" ] || git -C "$path" rev-parse --git-dir >/dev/null 2>&1; then
        branch=$(git -C "$path" branch --show-current 2>/dev/null)
        if [ -n "$(git -C "$path" status --porcelain 2>/dev/null)" ]; then
            dirty="YES"
        else
            dirty="clean"
        fi
    fi

    printf "%-25s %-12s %-8s %s\n" "$name" "${branch:--}" "${dirty:--}" "${windows}w"
done
