#!/usr/bin/env bash
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
# Called by Claude Code Notification hook.
# Sets status to "attention" — Claude is waiting for user input.

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

[ -z "$CWD" ] && exit 0

PROJECT_DIR=$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null || echo "$CWD")
STATUS_FILE="$PROJECT_DIR/.claude-status.json"

if [ -f "$STATUS_FILE" ]; then
    # Only set attention if currently working (don't overwrite idle/done)
    current=$(jq -r '.status // ""' "$STATUS_FILE" 2>/dev/null)
    if [ "$current" = "working" ]; then
        result=$(jq \
            --arg timestamp "$TIMESTAMP" \
            '.status = "attention" | .last_active = $timestamp' \
            "$STATUS_FILE" 2>/dev/null)
        [ -n "$result" ] && echo "$result" > "$STATUS_FILE"
    fi
fi

tmux refresh-client -S 2>/dev/null
"$(dirname "$0")/claude-dashboard-render.sh" >/dev/null 2>&1 &

exit 0
