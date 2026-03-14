#!/usr/bin/env bash
# session-picker.sh
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
# Fuzzy-find active tmux sessions with context (window count, path, git branch).
# Replaces the built-in choose-tree (Prefix + s).

current_session=$(tmux display-message -p '#S')

# Build a list of sessions with context
tmux list-sessions -F '#{session_name}' | while read -r name; do
    # Get the active pane's path for this session
    path=$(tmux display-message -t "$name" -p '#{pane_current_path}' 2>/dev/null)
    windows=$(tmux display-message -t "$name" -p '#{session_windows}' 2>/dev/null)

    # Git branch if available
    branch=""
    if [ -n "$path" ] && git -C "$path" rev-parse --git-dir >/dev/null 2>&1; then
        branch=$(git -C "$path" branch --show-current 2>/dev/null)
        dirty=$(git -C "$path" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
        if [ "$dirty" -gt 0 ]; then
            branch="$branch*"
        fi
    fi

    # Format: session_name | windows | branch | short path
    short_path=$(echo "$path" | sed "s|$HOME/src/github.com/dillonkearns/||" | sed "s|$HOME|~|")
    marker=""
    if [ "$name" = "$current_session" ]; then
        marker=" (attached)"
    fi

    printf "%-25s %2sw  %-20s %s%s\n" "$name" "$windows" "${branch:--}" "$short_path" "$marker"
done > /tmp/tmux-sessions-$$

selected=$(fzf --prompt="session> " \
    --height=100% \
    --layout=reverse \
    --border=none \
    --info=hidden \
    --no-scrollbar \
    --nth=1 \
    --with-nth=1.. \
    < /tmp/tmux-sessions-$$ | awk '{print $1}')

rm -f /tmp/tmux-sessions-$$

if [ -n "$selected" ]; then
    tmux switch-client -t "$selected"
fi
