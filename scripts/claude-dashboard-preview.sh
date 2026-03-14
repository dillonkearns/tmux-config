#!/bin/bash
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
CYAN='\033[36m'
MAGENTA='\033[35m'
WHITE='\033[97m'
BG_GREEN='\033[42;30m'
BG_RED='\033[41;37m'
BG_YELLOW='\033[43;30m'
BG_CYAN='\033[46;30m'
BG_MAGENTA='\033[45;37m'
BG_DIM='\033[100;37m'

selected_name=$(echo "$1" | sed 's/^[^ ]* //' | awk '{print $1}')

for session_name in $(tmux list-sessions -F '#{session_name}' 2>/dev/null); do
    path=$(tmux display-message -t "$session_name" -p '#{pane_current_path}' 2>/dev/null)
    [ -z "$path" ] && continue
    dir=$(git -C "$path" rev-parse --show-toplevel 2>/dev/null || echo "$path")
    sf="$dir/.claude-status.json"
    branch=$(git -C "$dir" branch --show-current 2>/dev/null)

    # Claude fields
    status="-"
    goal=""
    summary=""
    has_changes=false

    if [ -f "$sf" ]; then
        status=$(jq -r '.status // "-"' "$sf" 2>/dev/null)
        goal=$(jq -r '.goal // ""' "$sf" 2>/dev/null)
        summary=$(jq -r '.summary // ""' "$sf" 2>/dev/null)
    fi

    # Git status icons
    staged=0; modified=0; untracked=0; ahead=0; behind=0
    if git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
        staged=$(git -C "$dir" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
        modified=$(git -C "$dir" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
        untracked=$(git -C "$dir" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
        counts=$(git -C "$dir" rev-list --left-right --count HEAD...@{upstream} 2>/dev/null)
        if [ -n "$counts" ]; then
            ahead=$(echo "$counts" | awk '{print $1}')
            behind=$(echo "$counts" | awk '{print $2}')
        fi
        [ "$staged" -gt 0 ] || [ "$modified" -gt 0 ] || [ "$untracked" -gt 0 ] && has_changes=true
    fi

    git_icons=""
    [ "$staged" -gt 0 ]    && git_icons="${git_icons}${GREEN}+${RESET}"
    [ "$modified" -gt 0 ]  && git_icons="${git_icons}${RED}~${RESET}"
    [ "$untracked" -gt 0 ] && git_icons="${git_icons}${YELLOW}?${RESET}"
    [ "$ahead" -gt 0 ]     && git_icons="${git_icons}${CYAN}↑${RESET}"
    [ "$behind" -gt 0 ]    && git_icons="${git_icons}${MAGENTA}↓${RESET}"

    # Clean check mark if nothing at all
    if [ -z "$git_icons" ]; then
        git_icons="${GREEN}✔${RESET}"
    fi

    # Status badge
    if [ "$status" = "idle" ] && [ "$has_changes" = true ]; then
        badge="${BG_MAGENTA} ◆ REVIEW ${RESET}"
    else
        case "$status" in
            working) badge="${BG_GREEN} ● WORKING ${RESET}" ;;
            idle)    badge="${BG_DIM} ○ IDLE ${RESET}" ;;
            done)    badge="${BG_CYAN} ✓ DONE ${RESET}" ;;
            blocked) badge="${BG_RED} ✗ BLOCKED ${RESET}" ;;
            *)       badge="${BG_DIM} - ${RESET}" ;;
        esac
    fi

    # Session header: name  badge  git-icons
    if [ "$session_name" = "$selected_name" ]; then
        printf "${BOLD}${CYAN}▸ %s${RESET}  %b  %b" "$session_name" "$badge" "$git_icons"
    else
        printf "${BOLD}  %s${RESET}  %b  %b" "$session_name" "$badge" "$git_icons"
    fi
    [ -n "$branch" ] && printf "  ${MAGENTA}%s${RESET}" "$branch"
    echo ""

    # Goal and summary — indented for hierarchy
    if [ -n "$goal" ]; then
        printf "      ${BOLD}${WHITE}Goal:${RESET} ${WHITE}%s${RESET}\n" "$goal"
    fi
    if [ -n "$summary" ]; then
        printf "      ${CYAN}%s${RESET}\n" "$summary"
    fi

    echo ""
done
