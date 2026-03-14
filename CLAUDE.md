# tmux-config

Dillon's tmux configuration, optimized for remote development from a BOOX Note Air 5 C e-ink tablet.

## Setup Overview

- **Host machine**: MacBook Pro (runs tmux server, all dev tools, Claude Code)
- **Local terminal**: Warp (used on the MacBook directly)
- **Client device**: BOOX Note Air 5 C (Android e-ink tablet with color display)
- **Connection**: SSH from BOOX tablet → MacBook, then `tmux attach`
- **Primary workspace**: `~/src/github.com/dillonkearns/` (~93 repositories)
- **tmux version**: 3.6a
- **Config**: `~/.tmux.conf` symlinked from this repo

## Core Principles

1. **E-ink first** — Every design decision optimizes for a small, slow-refresh color e-ink screen. High contrast, minimal redraws, no animations, no transparency.
2. **Keyboard-driven efficiency** — The tablet is a dumb terminal. Every action should be reachable with minimal keystrokes. Fuzzy finding, not browsing.
3. **Session-per-project** — Each repository gets its own tmux session. Jump between projects by switching sessions, not by cd-ing around.
4. **Claude Code as primary tool** — Most development happens through Claude Code. The tmux workflow should make it easy to run, monitor, and juggle multiple Claude Code sessions.
5. **Minimal and readable** — No visual noise. Status bar shows only what's needed. Content area is maximized.

## Workflow

### Daily flow
1. SSH into MacBook from BOOX tablet
2. `tmux attach` (or `tmux new`)
3. `C-Space f` to fuzzy-find a project → opens/attaches a named session
4. Run Claude Code in that session
5. `C-Space j/k` to cycle between project sessions
6. `C-Space Space` for the Claude dashboard, press 1-9 to jump
7. `C-Space g` for lazygit, `C-Space h` for GitHub status

### Key tools
- **sesh** — Session manager (fuzzy-find projects, switch sessions, zoxide-ranked)
- **lazygit** — TUI git client in a popup
- **gh CLI** — GitHub status (CI, PRs) in a popup
- **tmux-resurrect + continuum** — Session persistence across reboots
- **zoxide** — Smart directory ranking (powers sesh's project ordering)

## Claude Code Session Status (Dashboard System)

A hooks-based system for tracking Claude Code session status across all projects.

### How it works

1. **Hooks** (in `~/.claude/settings.json`) automatically fire on every tool use and when Claude stops:
   - `PostToolUse` → updates `.claude-status.json` with `last_active`, `last_tool`, `status: "working"`
   - `Stop` → sets `status: "idle"`

2. **Global CLAUDE.md** (in `~/.claude/CLAUDE.md`) instructs Claude Code to:
   - Ask for the session goal at startup if not set
   - Keep `goal` and `summary` fields updated at milestones
   - Mark `status: "done"` when complete

3. **Status bar** shows a compact icon per session (numbered, color-coded), with the active session highlighted in yellow. Updates instantly on session switch via `client-session-changed` hook.

4. **Dashboard** (`C-Space Space`) shows a fullscreen cached view of all sessions with goals, status badges, and git icons. Press 1-9 to jump to a session.

### Status icons

| Icon | Color | Meaning |
|------|-------|---------|
| `⠿` | orange | Claude is working (tools firing) |
| `●` | gray | Idle (Claude waiting or no active session) |
| `◆` | yellow | Review — idle but has uncommitted git changes |
| `✓` | cyan | Done (set by Claude via CLAUDE.md instructions) |
| `✗` | red | Blocked (set by Claude via CLAUDE.md instructions) |

### `.claude-status.json` schema

```json
{
  "session_id": "auto (hook)",
  "project": "auto (hook)",
  "goal": "set by Claude — one-line session goal",
  "status": "working|idle|done|blocked",
  "summary": "set by Claude — brief current status",
  "last_tool": "auto (hook)",
  "last_active": "auto (hook)",
  "started_at": "auto (hook)",
  "git_dirty": "auto (hook) — number of uncommitted changes",
  "git_branch": "auto (hook) — current branch name"
}
```

The file is globally gitignored (`~/.gitignore_global`).

### Data freshness strategy

**Design principles:**
- **Push over pull** — get notified when things change rather than polling. Hooks are instant and free.
- **Piggyback expensive checks** — git status (~20ms) rides along with hook writes that are already happening async. No separate process needed.
- **Per-repo locality** — each repo has its own `.claude-status.json`. Multiple agents writing to separate files avoids race conditions. A single shared file would invite clobbering.
- **Stale-while-revalidate** — show cached data immediately, refresh in background. Dashboard opens instantly from cache, re-renders for next time.
- **Status bar must be <200ms** — reads only cached JSON, never runs git. This is non-negotiable for responsiveness.

**How data flows:**

| Trigger | What updates | Latency |
|---------|-------------|---------|
| Claude tool use (PostToolUse hook) | `.claude-status.json` with status + git dirty/branch | Instant (async) |
| Claude stops (Stop hook) | `.claude-status.json` idle + git dirty/branch | Instant (async) |
| Session switch (tmux hook) | Status bar refresh | Instant |
| Status bar render (every 30s) | Reads cached JSON + kicks off background dashboard render | <200ms |
| Dashboard render (background) | Full git checks, writes `~/.cache/claude-dashboard.cache` | ~2s, runs in background |
| Dashboard open (C-Space Space) | Reads cache, background refresh for next time | Instant |

**What's NOT push-based (and the fallback):**
- Manual git changes outside Claude (commits in lazygit, manual edits) — caught by background render every 30s. Acceptable tradeoff.

### Performance decisions

- **Avoid `flock`** — not available on macOS. Use write-to-variable + redirect instead of tmp file + mv for atomic-ish JSON updates.
- **PID-unique temp files** — dashboard render uses `$CACHE.tmp.$$` to prevent concurrent renders from clobbering each other.
- **Pidfile guard** — only one dashboard render runs at a time; concurrent invocations skip.
- **No git calls in status bar** — ever. This is the #1 performance rule.

### Setup dependencies

- Hooks configured in `~/.claude/settings.json`
- Global prompt in `~/.claude/CLAUDE.md`
- Scripts in this repo: `claude-status-update.sh`, `claude-status-stop.sh`, `claude-dashboard.sh`, `claude-dashboard-render.sh`, `statusbar-sessions.sh`
- `jq` for JSON manipulation
- `.claude-status.json` and `.claude-status.json.lock` in `~/.gitignore_global`

## Scratch Files

Ephemeral files (notes, plans, temp data) go in `.scratch/` at the project root. This directory is globally gitignored — never shows in git status, lazygit, or risk being committed.

## Warp Terminal

Warp does **not** have iTerm2-style `tmux -CC` native integration. Don't use `-CC` — it will dump raw protocol text. Just use `tmux attach` from Warp like any other terminal.

Warp's "warpify" feature uses tmux control mode invisibly for SSH. If you hit "sessions should be nested with care", run `unset TMUX` first or disable warpification: `defaults write dev.warp.Warp-Stable SshTmuxWrapperOverride false`.

## Theme / Colors

The tmux config uses **ANSI palette colors** (not hardcoded RGB) so each terminal controls the actual appearance:
- **Warp (MacBook)**: Use your preferred dark theme
- **Termux (BOOX)**: Use a high-contrast light theme for e-ink

Same approach for Claude Code: use "Light Mode (ANSI only)" theme so it adapts to the terminal palette.

Key finding: `status-style "default"` causes the status bar to disappear on some terminals. Use explicit ANSI palette colors (`bg=colour0,fg=colour7`) instead.

## Neovim

Minimal config optimized for e-ink, Elm-focused. Symlinked to `~/.config/nvim/init.lua`.

- **Theme**: rose-pine dawn (light, high contrast, no italics)
- **Fuzzy finder**: Telescope (`<Space>f` files, `<Space>g` grep, `<Space>b` buffers)
- **LSP**: elm-language-server via native nvim 0.11 `vim.lsp.config` API (not deprecated lspconfig plugin)
- **Treesitter**: Syntax highlighting for Elm, Lua, JSON, Markdown, Bash
- **Status line**: lualine (minimal, no fancy separators)

Note: Neovim 0.11 changed both the LSP and treesitter APIs. Use `vim.lsp.config` / `vim.lsp.enable` instead of `require('lspconfig')`, and don't call `require('nvim-treesitter.configs')`.

## Goals

### Done
- [x] Project fuzzy-finder (sesh + fzf, shows all repos by default)
- [x] Efficient keybindings (j/k session cycling, popup-based tools)
- [x] Git diff quick-view (lazygit popup)
- [x] GitHub CI/PR status popup (native gh CLI output)
- [x] Session persistence (resurrect + continuum)
- [x] Claude Code session status via hooks
- [x] Status bar with numbered session icons and active indicator
- [x] Instant dashboard with cached rendering and number-key navigation
- [x] Neovim setup with Elm LSP and e-ink theme

### In Progress
- [ ] E-ink theme fine-tuning (needs testing on BOOX tablet)

### Stretch
- [ ] Per-project goals tracking integrated into dashboard
- [ ] tmux-fingers for hint-based text copying (high value for e-ink)
- [ ] Cross-project status aggregation

## File Structure

```
tmux-config/
├── CLAUDE.md                          # This file — project context and goals
├── GOALS.md                           # Active project goals and priorities
├── KEYBINDINGS.md                     # Quick reference for keybindings
├── tmux.conf                          # Main tmux config (symlinked to ~/.tmux.conf)
├── nvim/
│   └── init.lua                       # Neovim config (symlinked to ~/.config/nvim/init.lua)
└── scripts/
    ├── claude-dashboard.sh            # Dashboard: fullscreen, press 1-9 to jump
    ├── claude-dashboard-render.sh     # Renders dashboard to cache file
    ├── claude-status-update.sh        # Hook: update status on tool use
    ├── claude-status-stop.sh          # Hook: mark idle when Claude stops
    ├── gh-status.sh                   # GitHub CI/PR status popup
    ├── statusbar-sessions.sh          # Status bar: numbered session icons
    ├── project-switcher.sh            # Legacy fzf project finder (replaced by sesh)
    ├── session-picker.sh              # Legacy fzf session picker (replaced by sesh)
    └── session-status.sh              # Legacy session status (replaced by dashboard)
```

## Conventions

- This repo's `tmux.conf` is the source of truth. Symlink: `ln -sf ~/src/github.com/dillonkearns/tmux-config/tmux.conf ~/.tmux.conf`
- Neovim config symlink: `ln -sf ~/src/github.com/dillonkearns/tmux-config/nvim/init.lua ~/.config/nvim/init.lua`
- Scripts go in `scripts/` and should be POSIX-friendly where possible
- Prefix key is `C-Space` (Ctrl+Space) — do NOT use `C-a` (conflicts with Emacs keybindings)
- All custom bindings documented in `KEYBINDINGS.md`
- `.claude-status.json` files are globally gitignored — never commit them
- Ephemeral session files go in `.scratch/` (globally gitignored)
- Status bar scripts must be fast (<200ms) — no git calls, read cached data only
