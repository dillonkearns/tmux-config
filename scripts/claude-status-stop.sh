#!/usr/bin/env bash
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
# Called by Claude Code Stop hook.

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

[ -z "$CWD" ] && exit 0

PROJECT_DIR=$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null || echo "$CWD")
STATUS_FILE="$PROJECT_DIR/.claude-status.json"

# Capture git state — this is when "review" status matters most
git_dirty=0
git_branch=""
if git -C "$PROJECT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    git_dirty=$(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    git_branch=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null)
fi

if [ -f "$STATUS_FILE" ]; then
    result=$(jq \
        --arg timestamp "$TIMESTAMP" \
        --argjson git_dirty "$git_dirty" \
        --arg git_branch "$git_branch" \
        '.status = "idle" | .last_active = $timestamp | .git_dirty = $git_dirty | .git_branch = $git_branch' \
        "$STATUS_FILE" 2>/dev/null)
    [ -n "$result" ] && echo "$result" > "$STATUS_FILE"
fi

tmux refresh-client -S 2>/dev/null
"$(dirname "$0")/claude-dashboard-render.sh" >/dev/null 2>&1 &

exit 0
