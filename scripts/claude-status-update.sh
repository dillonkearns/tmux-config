#!/usr/bin/env bash
# claude-status-update.sh
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
# Called by Claude Code PostToolUse hook (async).
# Updates .claude-status.json in the project directory with activity info.

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Determine project root (git root or cwd)
if [ -n "$CWD" ]; then
    PROJECT_DIR=$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null || echo "$CWD")
else
    exit 0
fi

STATUS_FILE="$PROJECT_DIR/.claude-status.json"

# If file exists, update activity fields only (preserve goal/summary set by Claude)
if [ -f "$STATUS_FILE" ]; then
    jq \
        --arg session_id "$SESSION_ID" \
        --arg tool "$TOOL_NAME" \
        --arg timestamp "$TIMESTAMP" \
        '.session_id = $session_id | .last_tool = $tool | .last_active = $timestamp | .status = "working"' \
        "$STATUS_FILE" > "${STATUS_FILE}.tmp" && mv "${STATUS_FILE}.tmp" "$STATUS_FILE"
else
    # Create fresh status file
    PROJECT_NAME=$(basename "$PROJECT_DIR")
    jq -n \
        --arg session_id "$SESSION_ID" \
        --arg project "$PROJECT_NAME" \
        --arg tool "$TOOL_NAME" \
        --arg timestamp "$TIMESTAMP" \
        '{
            session_id: $session_id,
            project: $project,
            goal: null,
            status: "working",
            summary: null,
            last_tool: $tool,
            last_active: $timestamp,
            started_at: $timestamp
        }' > "$STATUS_FILE"
fi

# Refresh status bar and dashboard cache
tmux refresh-client -S 2>/dev/null
"$(dirname "$0")/claude-dashboard-render.sh" &

exit 0
