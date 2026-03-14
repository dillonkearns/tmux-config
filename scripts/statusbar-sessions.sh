#!/bin/bash
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# Compact tmux status bar: numbered icon per session.
# ● working (green)  ○ idle (dim)  ◆ review (magenta, idle+uncommitted)
# ✓ done (cyan)  ✗ blocked (red)

i=1
for session_name in $(tmux list-sessions -F '#{session_name}' 2>/dev/null); do
    path=$(tmux display-message -t "$session_name" -p '#{pane_current_path}' 2>/dev/null)
    [ -z "$path" ] && continue
    dir=$(git -C "$path" rev-parse --show-toplevel 2>/dev/null || echo "$path")
    sf="$dir/.claude-status.json"

    status="-"
    has_changes=false

    if [ -f "$sf" ]; then
        status=$(jq -r '.status // "-"' "$sf" 2>/dev/null)
    fi

    if git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
        [ -n "$(git -C "$dir" status --porcelain 2>/dev/null)" ] && has_changes=true
    fi

    if [ "$status" = "idle" ] && [ "$has_changes" = true ]; then
        icon="◆"; color="colour3"   # yellow = review
    else
        case "$status" in
            working) icon="⠿"; color="colour208,bold" ;;  # bright orange braille
            idle)    icon="●"; color="colour245" ;;     # gray filled
            done)    icon="✓"; color="colour6" ;;    # cyan
            blocked) icon="✗"; color="colour1" ;;    # red
            *)       icon="●"; color="colour245" ;;    # gray fallback
        esac
    fi

    printf "#[fg=%s]%s#[default]%d " "$color" "$icon" "$i"
    i=$((i + 1))
done

# Rebuild dashboard cache in background (keeps git status fresh every 30s)
"$(dirname "$0")/claude-dashboard-render.sh" &
