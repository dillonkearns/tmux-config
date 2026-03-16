#!/bin/bash
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# Open or switch to the supervisor session.
# Runs Claude Code in the supervisor/ subdirectory of tmux-config.

SUPERVISOR_DIR="$HOME/src/github.com/dillonkearns/tmux-config/supervisor"
SESSION_NAME="supervisor"

current=$(tmux display-message -p '#S' 2>/dev/null)

if [ "$current" = "$SESSION_NAME" ]; then
    # Already in supervisor — jump back to last session
    tmux switch-client -l
    exit 0
fi

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    tmux switch-client -t "$SESSION_NAME"
else
    tmux new-session -d -s "$SESSION_NAME" -c "$SUPERVISOR_DIR"
    tmux send-keys -t "$SESSION_NAME" "claude --dangerously-skip-permissions" Enter
    tmux switch-client -t "$SESSION_NAME"
fi
