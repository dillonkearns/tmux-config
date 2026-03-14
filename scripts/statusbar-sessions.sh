#!/bin/bash
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# Fast status bar: reads only cached .claude-status.json, no git calls.
# Git status is updated by the dashboard render (every 30s / on hooks).

current_session=$(tmux display-message -p '#S' 2>/dev/null)

i=1
for session_name in $(tmux list-sessions -F '#{session_name}' 2>/dev/null); do
    path=$(tmux display-message -t "$session_name" -p '#{pane_current_path}' 2>/dev/null)
    [ -z "$path" ] && { i=$((i + 1)); continue; }
    dir=$(git -C "$path" rev-parse --show-toplevel 2>/dev/null || echo "$path")
    sf="$dir/.claude-status.json"

    status="-"
    if [ -f "$sf" ]; then
        status=$(jq -r '.status // "-"' "$sf" 2>/dev/null)
    fi

    case "$status" in
        working) icon="⠿"; color="colour208,bold" ;;
        idle)    icon="●"; color="colour245" ;;
        done)    icon="✓"; color="colour6" ;;
        blocked) icon="✗"; color="colour1" ;;
        *)       icon="●"; color="colour245" ;;
    esac

    # Session emoji if present
    emoji=""
    [ -f "$dir/.session-icon" ] && emoji=$(cat "$dir/.session-icon" 2>/dev/null)

    if [ "$session_name" = "$current_session" ]; then
        printf "#[fg=%s]%s#[default]#[bg=colour3,fg=colour0,bold] %d %s#[default] " "$color" "$icon" "$i" "$emoji"
    else
        printf "#[fg=%s]%s#[default]%d%s " "$color" "$icon" "$i" "$emoji"
    fi
    i=$((i + 1))
done

# Rebuild dashboard cache in background (this does the slow git checks)
"$(dirname "$0")/claude-dashboard-render.sh" >/dev/null 2>&1 &
