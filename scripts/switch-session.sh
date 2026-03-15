#!/bin/bash
# Switch to the Nth tmux session (1-indexed)
target=$(tmux list-sessions -F '#{session_name}' | sed -n "${1}p")
[ -n "$target" ] && tmux switch-client -t "$target"
