#!/bin/bash
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# claude-dashboard.sh
# Interactive Claude Code dashboard. j/k to navigate, Enter to switch, q to close.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Collect all sessions into a temp file
tmpfile=$(mktemp)

for session_name in $(tmux list-sessions -F '#{session_name}' 2>/dev/null); do
    session_path=$(tmux display-message -t "$session_name" -p '#{pane_current_path}' 2>/dev/null)
    [ -z "$session_path" ] && continue

    project_dir=$(git -C "$session_path" rev-parse --show-toplevel 2>/dev/null || echo "$session_path")
    status_file="$project_dir/.claude-status.json"

    # Git branch
    branch=$(git -C "$project_dir" branch --show-current 2>/dev/null)

    # Claude status from JSON
    icon=" "
    info=""
    if [ -f "$status_file" ]; then
        claude_status=$(jq -r '.status // "-"' "$status_file" 2>/dev/null)
        goal=$(jq -r '.goal // ""' "$status_file" 2>/dev/null)

        case "$claude_status" in
            working) icon="●" ;;
            idle)    icon="○" ;;
            done)    icon="✓" ;;
            blocked) icon="✗" ;;
        esac

        [ -n "$goal" ] && info="→ $goal"
    fi

    line="${icon} ${session_name}"
    [ -n "$branch" ] && line="${line}  (${branch})"
    [ -n "$info" ] && line="${line}  ${info}"

    echo "$line" >> "$tmpfile"
done

# If no sessions found
if [ ! -s "$tmpfile" ]; then
    echo "(no tmux sessions)" > "$tmpfile"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

selected=$(fzf \
    --no-sort \
    --layout=reverse \
    --border-label ' Claude Dashboard ' \
    --header '  enter: switch to session' \
    --preview "$SCRIPT_DIR/claude-dashboard-preview.sh {}" \
    --preview-window=right:60%:wrap \
    --ansi \
    < "$tmpfile")

rm -f "$tmpfile"

if [ -n "$selected" ]; then
    # Extract session name (second field, after the icon)
    session=$(echo "$selected" | sed 's/^[^ ]* //' | awk '{print $1}')
    tmux switch-client -t "$session"
fi
