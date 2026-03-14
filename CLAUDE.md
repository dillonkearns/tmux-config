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
6. `C-Space g` for lazygit, `C-Space h` for GitHub status, `C-Space D` for dashboard

### Key tools
- **sesh** — Session manager (fuzzy-find projects, switch sessions, zoxide-ranked)
- **lazygit** — TUI git client in a popup
- **gh CLI** — GitHub status (CI, PRs) in a popup
- **tmux-resurrect + continuum** — Session persistence across reboots

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

3. **Dashboard** (`C-Space D`) reads `.claude-status.json` from all active tmux sessions and shows a unified view.

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
  "started_at": "auto (hook)"
}
```

The file is globally gitignored (`~/.gitignore_global`).

### Setup dependencies

- Hooks configured in `~/.claude/settings.json`
- Global prompt in `~/.claude/CLAUDE.md`
- Scripts in this repo: `claude-status-update.sh`, `claude-status-stop.sh`, `claude-dashboard.sh`

## Goals

### Done
- [x] Project fuzzy-finder (sesh + fzf)
- [x] Efficient keybindings (j/k session cycling, popup-based tools)
- [x] Git diff quick-view (lazygit popup)
- [x] GitHub CI/PR status popup
- [x] Session persistence (resurrect + continuum)
- [x] Claude Code session status via hooks

### In Progress
- [ ] E-ink optimized color theme (palette-adaptive, needs testing on BOOX)
- [ ] Dashboard refinement (richer display, goal tracking)

### Stretch
- [ ] Per-project goals tracking integrated into dashboard
- [ ] tmux-fingers for hint-based text copying
- [ ] Cross-project status aggregation

## Neovim

Minimal config optimized for e-ink, Elm-focused. Symlinked to `~/.config/nvim/init.lua`.

- **Theme**: rose-pine dawn (light, high contrast, no italics)
- **Fuzzy finder**: Telescope (`<Space>f` files, `<Space>g` grep, `<Space>b` buffers)
- **LSP**: elm-language-server (go-to-def, hover, rename, diagnostics)
- **Treesitter**: Syntax highlighting for Elm, Lua, JSON, Markdown, Bash
- **Status line**: lualine (minimal, no fancy separators)

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
    ├── claude-dashboard.sh            # Dashboard: status across all sessions
    ├── claude-status-update.sh        # Hook: update status on tool use
    ├── claude-status-stop.sh          # Hook: mark idle when Claude stops
    ├── gh-status.sh                   # GitHub CI/PR status popup
    ├── project-switcher.sh            # Legacy fzf project finder (replaced by sesh)
    ├── session-picker.sh              # Legacy fzf session picker (replaced by sesh)
    └── session-status.sh              # Show git status of all sessions
```

## Conventions

- This repo's `tmux.conf` is the source of truth. Symlink: `ln -sf ~/src/github.com/dillonkearns/tmux-config/tmux.conf ~/.tmux.conf`
- Scripts go in `scripts/` and should be POSIX-friendly where possible
- Prefix key is `C-Space` (Ctrl+Space)
- All custom bindings documented in `KEYBINDINGS.md`
- `.claude-status.json` files are globally gitignored — never commit them
