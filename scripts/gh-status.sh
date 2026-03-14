#!/usr/bin/env bash
# gh-status.sh
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
# Show GitHub PR and CI status using gh CLI's native output.
# Designed to run in a tmux popup. Press q to close.

{
    echo ""
    gh pr status 2>/dev/null || echo "  (not a GitHub repo or gh not authenticated)"
    echo ""
    echo "── CI Runs ──────────────────────────────"
    echo ""
    gh run list --limit 5 2>/dev/null || echo "  (no CI runs)"
} | less -R
