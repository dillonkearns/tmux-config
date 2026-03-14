#!/usr/bin/env bash
# gh-status.sh
# Show GitHub CI and PR status for the current branch.
# Designed to run in a tmux popup. Press q to close (via less).

{
# Colors (ANSI — adapts to terminal palette)
BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
CYAN='\033[36m'
RESET='\033[0m'

# Check if we're in a git repo
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Not a git repo"
    exit 0
fi

branch=$(git branch --show-current 2>/dev/null)
repo=$(basename "$(git rev-parse --show-toplevel)")

printf "${BOLD}%s${RESET} ${DIM}(%s)${RESET}\n\n" "$repo" "$branch"

# --- CI Status ---
printf "${BOLD}CI Runs${RESET}\n"
printf "${DIM}─────────────────────────────────────────${RESET}\n"

gh run list --branch "$branch" --limit 5 --json name,status,conclusion,event,updatedAt \
    --template '{{range .}}{{if eq .conclusion "success"}}✓ {{else if eq .conclusion "failure"}}✗ {{else if eq .status "in_progress"}}⟳ {{else}}  {{end}}{{.name}} ({{.event}}) {{timeago .updatedAt}}
{{end}}' 2>/dev/null

if [ $? -ne 0 ]; then
    printf "  ${DIM}(no CI runs or gh not authenticated)${RESET}\n"
fi

echo ""

# --- PR Status ---
printf "${BOLD}Pull Requests${RESET}\n"
printf "${DIM}─────────────────────────────────────────${RESET}\n"

pr_info=$(gh pr view --branch "$branch" --json number,title,state,reviewDecision,mergeable,statusCheckRollup 2>/dev/null)

if [ $? -eq 0 ] && [ -n "$pr_info" ]; then
    pr_number=$(echo "$pr_info" | jq -r '.number')
    pr_title=$(echo "$pr_info" | jq -r '.title')
    pr_state=$(echo "$pr_info" | jq -r '.state')
    pr_review=$(echo "$pr_info" | jq -r '.reviewDecision // "PENDING"')
    pr_mergeable=$(echo "$pr_info" | jq -r '.mergeable')

    case "$pr_state" in
        OPEN) state_color="$GREEN" ;;
        CLOSED) state_color="$RED" ;;
        MERGED) state_color="$CYAN" ;;
        *) state_color="$RESET" ;;
    esac

    case "$pr_review" in
        APPROVED) review_color="$GREEN"; review_icon="✓" ;;
        CHANGES_REQUESTED) review_color="$RED"; review_icon="✗" ;;
        *) review_color="$YELLOW"; review_icon="○" ;;
    esac

    printf "  ${state_color}#%s${RESET} %s\n" "$pr_number" "$pr_title"
    printf "  State: ${state_color}%s${RESET}  Review: ${review_color}%s %s${RESET}  Mergeable: %s\n" \
        "$pr_state" "$review_icon" "$pr_review" "$pr_mergeable"

    checks=$(echo "$pr_info" | jq -r '.statusCheckRollup // [] | length')
    if [ "$checks" -gt 0 ]; then
        passing=$(echo "$pr_info" | jq '[.statusCheckRollup[] | select(.conclusion == "SUCCESS")] | length')
        failing=$(echo "$pr_info" | jq '[.statusCheckRollup[] | select(.conclusion == "FAILURE")] | length')
        pending=$(echo "$pr_info" | jq '[.statusCheckRollup[] | select(.conclusion == null or .conclusion == "")] | length')
        printf "  Checks: ${GREEN}%s pass${RESET}  ${RED}%s fail${RESET}  ${YELLOW}%s pending${RESET}\n" \
            "$passing" "$failing" "$pending"
    fi
else
    printf "  ${DIM}No PR for branch '%s'${RESET}\n" "$branch"
fi

echo ""

# --- Uncommitted changes summary ---
printf "${BOLD}Working Tree${RESET}\n"
printf "${DIM}─────────────────────────────────────────${RESET}\n"
staged=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
unstaged=$(git diff --numstat 2>/dev/null | wc -l | tr -d ' ')
untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
printf "  Staged: %s  Modified: %s  Untracked: %s\n" "$staged" "$unstaged" "$untracked"

} | less -R
