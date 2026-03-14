#!/usr/bin/env bash
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
# Called by Claude Code PostToolUse hook (async).

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

[ -z "$CWD" ] && exit 0

PROJECT_DIR=$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null || echo "$CWD")
STATUS_FILE="$PROJECT_DIR/.claude-status.json"

# Piggyback git status onto the hook (cheap, ~20ms)
git_dirty=0
git_branch=""
if git -C "$PROJECT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    git_dirty=$(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    git_branch=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null)
fi

if [ -f "$STATUS_FILE" ]; then
    result=$(jq \
        --arg session_id "$SESSION_ID" \
        --arg tool "$TOOL_NAME" \
        --arg timestamp "$TIMESTAMP" \
        --argjson git_dirty "$git_dirty" \
        --arg git_branch "$git_branch" \
        '.session_id = $session_id | .last_tool = $tool | .last_active = $timestamp | .status = "working" | .git_dirty = $git_dirty | .git_branch = $git_branch' \
        "$STATUS_FILE" 2>/dev/null)
    [ -n "$result" ] && echo "$result" > "$STATUS_FILE"
else
    PROJECT_NAME=$(basename "$PROJECT_DIR")
    jq -n \
        --arg session_id "$SESSION_ID" \
        --arg project "$PROJECT_NAME" \
        --arg tool "$TOOL_NAME" \
        --arg timestamp "$TIMESTAMP" \
        --argjson git_dirty "$git_dirty" \
        --arg git_branch "$git_branch" \
        '{session_id:$session_id,project:$project,goal:null,status:"working",summary:null,last_tool:$tool,last_active:$timestamp,started_at:$timestamp,git_dirty:$git_dirty,git_branch:$git_branch}' \
        > "$STATUS_FILE" 2>/dev/null
fi

tmux refresh-client -S 2>/dev/null
"$(dirname "$0")/claude-dashboard-render.sh" >/dev/null 2>&1 &

exit 0
