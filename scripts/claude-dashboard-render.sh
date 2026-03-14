#!/bin/bash
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# Renders dashboard content to ~/.cache/claude-dashboard.cache
# Called by hooks for instant dashboard display.

CACHE="$HOME/.cache/claude-dashboard.cache"
PIDFILE="$HOME/.cache/claude-dashboard.pid"
mkdir -p "$(dirname "$CACHE")"

# Skip if another render is already running
if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE" 2>/dev/null)" 2>/dev/null; then
    exit 0
fi
echo $$ > "$PIDFILE"

BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
CYAN='\033[36m'
MAGENTA='\033[35m'
WHITE='\033[97m'
ORANGE='\033[1;38;5;208m'
GRAY='\033[38;5;245m'
REVERSE='\033[7m'
BG_GREEN='\033[42;30m'
BG_RED='\033[41;37m'
BG_CYAN='\033[46;30m'
BG_MAGENTA='\033[45;37m'
BG_YELLOW='\033[43;30m'
BG_DIM='\033[100;37m'
BG_ORANGE='\033[48;5;208;30m'

{
    printf "\n"

    i=1
    for session_name in $(tmux list-sessions -F '#{session_name}' 2>/dev/null); do
        path=$(tmux display-message -t "$session_name" -p '#{pane_current_path}' 2>/dev/null)
        [ -z "$path" ] && continue
        dir=$(git -C "$path" rev-parse --show-toplevel 2>/dev/null || echo "$path")
        sf="$dir/.claude-status.json"
        branch=$(git -C "$dir" branch --show-current 2>/dev/null)

        status="-"; goal=""; summary=""; has_changes=false

        if [ -f "$sf" ]; then
            status=$(jq -r '.status // "-"' "$sf" 2>/dev/null)
            goal=$(jq -r '.goal // ""' "$sf" 2>/dev/null)
            summary=$(jq -r '.summary // ""' "$sf" 2>/dev/null)
        fi

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
        [ -z "$git_icons" ]    && git_icons="${GREEN}✔${RESET}"

        if [ "$status" = "idle" ] && [ "$has_changes" = true ]; then
            badge="${BG_YELLOW} ◆ REVIEW ${RESET}"
        else
            case "$status" in
                working) badge="${BG_ORANGE} ⠿ WORKING ${RESET}" ;;
                idle)    badge="${BG_DIM} ● IDLE ${RESET}" ;;
                done)    badge="${BG_CYAN} ✓ DONE ${RESET}" ;;
                blocked) badge="${BG_RED} ✗ BLOCKED ${RESET}" ;;
                *)       badge="${BG_DIM} ● ${RESET}" ;;
            esac
        fi

        emoji=""
        [ -f "$dir/.session-icon" ] && emoji="$(cat "$dir/.session-icon" 2>/dev/null) "

        printf "  ${REVERSE} %d ${RESET}  %s${BOLD}%s${RESET}  %b  %b" "$i" "$emoji" "$session_name" "$badge" "$git_icons"
        [ -n "$branch" ] && printf "  ${MAGENTA}%s${RESET}" "$branch"
        printf "\n"

        if [ -n "$goal" ]; then
            printf "      ${BOLD}${WHITE}Goal:${RESET} ${WHITE}%s${RESET}\n" "$goal"
        fi
        if [ -n "$summary" ]; then
            printf "      ${CYAN}%s${RESET}\n" "$summary"
        fi

        printf "\n"
        i=$((i + 1))
    done
} > "$CACHE.tmp.$$" 2>/dev/null && mv "$CACHE.tmp.$$" "$CACHE" 2>/dev/null

rm -f "$PIDFILE"
