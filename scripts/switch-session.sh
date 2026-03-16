#!/bin/bash
# Switch to the Nth tmux session (1-indexed), excluding supervisor
target=$(tmux list-sessions -F '#{session_name}' | grep -v '^supervisor$' | sed -n "${1}p")
[ -n "$target" ] && tmux switch-client -t "$target"
