#!/bin/bash
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# Claude Code Dashboard — instant from cache, press 1-9 to jump, q/Esc to close.

CACHE="$HOME/.cache/claude-dashboard.cache"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Collect session names for number→session mapping
sessions=()
for s in $(tmux list-sessions -F '#{session_name}' 2>/dev/null); do
    sessions+=("$s")
done

# If cache is missing or stale (>120s), render fresh synchronously
if [ ! -f "$CACHE" ] || [ $(($(date +%s) - $(stat -f %m "$CACHE" 2>/dev/null || echo 0))) -gt 120 ]; then
    "$SCRIPT_DIR/claude-dashboard-render.sh"
fi

# Display cache instantly
clear
cat "$CACHE"

# Refresh cache in background for next time
"$SCRIPT_DIR/claude-dashboard-render.sh" &

# Wait for keypress
while true; do
    read -rsn1 key
    case "$key" in
        [1-9])
            idx=$((key - 1))
            if [ "$idx" -lt "${#sessions[@]}" ]; then
                tmux switch-client -t "${sessions[$idx]}"
                exit 0
            fi
            ;;
        q|$'\e')
            exit 0
            ;;
    esac
done
