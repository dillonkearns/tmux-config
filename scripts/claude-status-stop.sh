#!/usr/bin/env bash
# claude-status-stop.sh
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
# Called by Claude Code Stop hook.
# Marks the session as idle in .claude-status.json.

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [ -n "$CWD" ]; then
    PROJECT_DIR=$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null || echo "$CWD")
else
    exit 0
fi

STATUS_FILE="$PROJECT_DIR/.claude-status.json"

if [ -f "$STATUS_FILE" ]; then
    jq \
        --arg timestamp "$TIMESTAMP" \
        '.status = "idle" | .last_active = $timestamp' \
        "$STATUS_FILE" > "${STATUS_FILE}.tmp" && mv "${STATUS_FILE}.tmp" "$STATUS_FILE"
fi

exit 0
