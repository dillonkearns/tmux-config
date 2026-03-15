#!/usr/bin/env bash
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# GitHub CI status — focused on current branch.
# Shows latest run status, watches if in progress.
# Designed for tmux popup. Press q/Ctrl-C to close.

if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Not a git repo"
    read -rsn1
    exit 0
fi

branch=$(git branch --show-current 2>/dev/null)
repo=$(basename "$(git rev-parse --show-toplevel)")

BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
CYAN='\033[36m'
RESET='\033[0m'

printf "\n${BOLD}  %s${RESET} ${DIM}(%s)${RESET}\n\n" "$repo" "$branch"

# Get latest run for this branch
run_json=$(gh run list --branch "$branch" --limit 1 --json databaseId,status,conclusion,name,createdAt 2>/dev/null)

if [ -z "$run_json" ] || [ "$run_json" = "[]" ]; then
    printf "  ${DIM}No CI runs for branch '%s'${RESET}\n\n" "$branch"
    # Show PR status as fallback
    echo ""
    gh pr status 2>/dev/null
    echo ""
    read -rsn1
    exit 0
fi

status=$(echo "$run_json" | jq -r '.[0].status')
conclusion=$(echo "$run_json" | jq -r '.[0].conclusion')
run_id=$(echo "$run_json" | jq -r '.[0].databaseId')
name=$(echo "$run_json" | jq -r '.[0].name')
created=$(echo "$run_json" | jq -r '.[0].createdAt')

# Time ago
created_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$created" +%s 2>/dev/null)
now_epoch=$(date +%s)
if [ -n "$created_epoch" ]; then
    diff=$((now_epoch - created_epoch))
    if [ "$diff" -lt 60 ]; then ago="${diff}s ago"
    elif [ "$diff" -lt 3600 ]; then ago="$((diff / 60))m ago"
    else ago="$((diff / 3600))h ago"
    fi
else
    ago="$created"
fi

if [ "$status" = "in_progress" ] || [ "$status" = "queued" ] || [ "$status" = "waiting" ]; then
    # Active run — watch it live
    printf "  ${YELLOW}⟳ ${name}${RESET} — ${BOLD}running${RESET} (started %s)\n\n" "$ago"
    printf "  ${DIM}Watching live... Ctrl-C to close${RESET}\n\n"
    gh run watch "$run_id" --compact
    echo ""
    # After watch completes, show final status
    final=$(gh run view "$run_id" --json conclusion -q '.conclusion' 2>/dev/null)
    if [ "$final" = "success" ]; then
        printf "\n  ${GREEN}✓ Passed${RESET}\n"
    else
        printf "\n  ${RED}✗ Failed${RESET}\n"
    fi
    echo ""
    read -rsn1 -p "  Press any key to close"
else
    # Completed run — show result
    if [ "$conclusion" = "success" ]; then
        printf "  ${GREEN}✓ ${name}${RESET} — ${GREEN}passed${RESET} (%s)\n" "$ago"
    elif [ "$conclusion" = "failure" ]; then
        printf "  ${RED}✗ ${name}${RESET} — ${RED}failed${RESET} (%s)\n" "$ago"
        echo ""
        printf "  ${DIM}Failed steps:${RESET}\n"
        gh run view "$run_id" --compact 2>/dev/null | grep -E "✗|X" | head -5
    else
        printf "  ${DIM}● ${name}${RESET} — %s (%s)\n" "$conclusion" "$ago"
    fi

    # PR status
    echo ""
    printf "  ${BOLD}PR Status${RESET}\n"
    printf "  ${DIM}─────────${RESET}\n"
    gh pr view --branch "$branch" --json title,state,reviewDecision --template '  {{.title}} — {{.state}} ({{.reviewDecision}})' 2>/dev/null || printf "  ${DIM}No PR for this branch${RESET}"
    echo ""
    echo ""
    read -rsn1 -p "  Press any key to close"
fi
