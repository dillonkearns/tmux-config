# tmux-config

Dillon's development environment configuration — tmux, Neovim, and Claude Code orchestration, optimized for remote development from an e-ink tablet.

## Physical Setup

- **Host machine**: MacBook Pro — runs tmux server, all dev tools, Claude Code instances
- **Local terminal**: Warp (used when working directly on the MacBook)
- **Remote client**: BOOX Note Air 5 C — Android-based color e-ink tablet, used as a portable dumb terminal outdoors in sunlight
- **Connection path**: BOOX tablet → Termux app → SSH → MacBook → `tmux attach`
- **Primary workspace**: `~/src/github.com/dillonkearns/` (~93 repositories, mostly Elm ecosystem)
- **tmux version**: 3.6a
- **Neovim version**: 0.11.6

## Core Principles

1. **E-ink first** — Every design decision optimizes for a small, slow-refresh color e-ink screen. High contrast, minimal redraws, no animations, no transparency.
2. **Keyboard-driven efficiency** — The tablet is a dumb terminal. Every action reachable with minimal keystrokes. Fuzzy finding, not browsing.
3. **Session-per-project** — Each repository gets its own tmux session. Jump between projects by switching sessions, not by cd-ing around.
4. **Claude Code as primary tool** — Most development happens through Claude Code (`--dangerously-skip-permissions` mode). The tmux workflow makes it easy to run, monitor, and juggle multiple concurrent sessions.
5. **Minimal and readable** — No visual noise. Status bar shows only what's needed. Content area is maximized.
6. **Push over pull** — Get notified when things change rather than polling. Hooks are instant and free.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│ MacBook Pro (tmux server)                                   │
│                                                             │
│  tmux sessions:                                             │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐  │
│  │0 supervisor│ │1 elm-pages│ │2 pinchy  │ │3 elm-cli-... │  │
│  │  (🔭)     │ │  (📖)    │ │  (🦞)   │ │  (⚙️)        │  │
│  │ Claude    │ │ Claude   │ │ Claude   │ │ Claude       │  │
│  │ can see   │ │ Code     │ │ Code     │ │ Code         │  │
│  │ all others│ │          │ │          │ │              │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────┘  │
│                                                             │
│  Status bar: ●0🔭 ⠿ 1 📖 ◆2🦞 ●3⚙️  │ 14:30           │
│                                                             │
│  Hooks → .claude-status.json (per-repo)                    │
│       → ~/.cache/claude-dashboard.cache                     │
│       → tmux refresh-client -S                              │
└─────────────────────────────────────────────────────────────┘
         ▲ SSH
         │
┌────────┴────────┐
│ BOOX Note Air 5C│
│ (Termux + SSH)  │
│ e-ink display   │
└─────────────────┘
```

## Workflow

### Daily flow
1. SSH into MacBook from BOOX tablet via Termux
2. `tmux attach` (or `tmux new`)
3. `C-Space f` to fuzzy-find a project → opens session + launches Claude Code
4. Work with Claude Code in that session
5. `C-Space 1-9` to jump between project sessions by number
6. `C-Space 0` to jump to supervisor (can see/control all other sessions)
7. `C-Space Space` for the dashboard overview, press 1-9 to jump
8. `C-Space g` for lazygit, `C-Space h` for GitHub CI/PR status
9. `C-Space F` to grab text from screen (tmux-fingers)

### Key tools installed
- **sesh** (Go binary) — Session manager, fuzzy-find projects, switch sessions
- **zoxide** — Smart directory ranking, powers sesh's project ordering. Init in `~/.zshrc`.
- **lazygit** — TUI git client, runs in a tmux popup
- **gh CLI** — GitHub CI/PR status in a popup, with `gh run watch` for live CI
- **fzf** — Fuzzy finder, used by sesh and custom scripts
- **jq** — JSON manipulation, used by all status scripts
- **tmux-resurrect + continuum** — Session persistence across reboots (auto-saves every 15m)
- **tmux-fingers** — Hint-based text grabbing from screen
- **tree-sitter** — Used by Neovim for syntax highlighting

## Supervisor Session

A special Claude Code session (`C-Space 0`) that can see and interact with all other sessions.

- Lives in `supervisor/` subdirectory with its own `CLAUDE.md`
- Shown as session `0🔭` in the status bar (always first, not numbered with others)
- Can read any session's screen via `tmux capture-pane`
- Can send input to any session via `tmux send-keys`
- Can read `.claude-status.json` for structured status data
- `C-Space 0` toggles to/from supervisor (pressing again returns to last session)

## Claude Code Session Status (Dashboard System)

A hooks-based system for tracking Claude Code session status across all projects.

### How it works

1. **Hooks** (in `~/.claude/settings.json`, must use absolute paths) automatically fire:
   - `PostToolUse` → updates `.claude-status.json` with `last_active`, `last_tool`, `status: "working"`, `git_dirty`, `git_branch`
   - `Stop` → sets `status: "idle"` + captures git state
   - `Notification` → sets `status: "attention"` (Claude waiting for user input)

2. **Global CLAUDE.md** (in `~/.claude/CLAUDE.md`) instructs Claude Code to:
   - Ask for the session goal at startup if not set
   - Keep `goal` and `summary` fields updated at milestones
   - Mark `status: "done"` when complete

3. **Status bar** shows a compact icon per session (numbered, color-coded), with the active session highlighted in yellow background. Updates instantly on session switch via `client-session-changed` hook.

4. **Dashboard** (`C-Space Space`) shows a fullscreen cached view of all sessions with goals, status badges, and git icons. Press 1-9 to jump to a session.

### Status icons

| Icon | Color | Meaning |
|------|-------|---------|
| `⠿` | orange (bold) | Claude is working (tools firing) |
| `❗` | red (bold) | Attention — Claude waiting for user input |
| `●` | gray | Idle (Claude finished or no active session) |
| `◆` | yellow | Review — idle but has uncommitted git changes |
| `✓` | cyan | Done (set by Claude via CLAUDE.md instructions) |
| `✗` | red | Blocked (set by Claude via CLAUDE.md instructions) |

### Per-repo metadata files

| File | Purpose | Gitignored |
|------|---------|-----------|
| `.claude-status.json` | Session status, goal, git state (written by hooks + Claude) | Yes |
| `.session-icon` | Single emoji for the repo, shown in status bar + dashboard | Yes |
| `.scratch/` | Ephemeral files for the session (notes, plans, temp data) | Yes |

### `.claude-status.json` schema

```json
{
  "session_id": "auto (hook)",
  "project": "auto (hook)",
  "goal": "set by Claude — one-line session goal",
  "status": "working|idle|attention|done|blocked",
  "summary": "set by Claude — brief current status",
  "last_tool": "auto (hook)",
  "last_active": "auto (hook)",
  "started_at": "auto (hook)",
  "git_dirty": "auto (hook) — number of uncommitted changes",
  "git_branch": "auto (hook) — current branch name"
}
```

### Data freshness strategy

**Design principles:**
- **Push over pull** — hooks are instant and free. Don't poll for what you can be notified about.
- **Piggyback expensive checks** — git status (~20ms) rides along with hook writes that are already happening async.
- **Per-repo locality** — each repo has its own `.claude-status.json`. Multiple agents writing to separate files avoids race conditions.
- **Stale-while-revalidate** — show cached data immediately, refresh in background.
- **Status bar must be <200ms** — reads only cached JSON, never runs git. Non-negotiable.

**How data flows:**

| Trigger | What updates | Latency |
|---------|-------------|---------|
| Claude tool use (PostToolUse hook) | `.claude-status.json` with status + git dirty/branch | Instant (async) |
| Claude stops (Stop hook) | `.claude-status.json` idle + git dirty/branch | Instant (async) |
| Claude needs input (Notification hook) | `.claude-status.json` attention | Instant (async) |
| Session switch (tmux hook) | Status bar refresh | Instant |
| Status bar render (every 30s) | Reads cached JSON + kicks off background dashboard render | <200ms |
| Dashboard render (background) | Full git checks, writes `~/.cache/claude-dashboard.cache` | ~2s, background |
| Dashboard open (C-Space Space) | Reads cache, background refresh for next time | Instant |

**What's NOT push-based (and the fallback):**
- Manual git changes outside Claude (commits in lazygit, manual edits) — caught by background render every 30s.

### Performance decisions

- **No git calls in status bar** — ever. This is the #1 performance rule.
- **Avoid `flock`** — not available on macOS. Write to variable first, then redirect.
- **PID-unique temp files** — dashboard render uses `$CACHE.tmp.$$` to prevent concurrent clobbering.
- **Pidfile guard** — only one dashboard render runs at a time; concurrent invocations skip.
- **Hook paths must be absolute** — `~` does not expand when Claude Code executes hook commands. Use `/Users/dillonkearns/...`.

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

- **Plugin manager**: lazy.nvim (auto-bootstraps on first run)
- **Theme**: rose-pine dawn (light, high contrast, no italics)
- **Fuzzy finder**: Telescope (`<Space>f` files, `<Space>g` grep, `<Space>b` buffers)
- **LSP**: elm-language-server via native nvim 0.11 `vim.lsp.config` API (not deprecated lspconfig plugin)
- **Treesitter**: Syntax highlighting for Elm, Lua, JSON, Markdown, Bash
- **Status line**: lualine (minimal, no fancy separators)

Note: Neovim 0.11 changed both the LSP and treesitter APIs. Use `vim.lsp.config` / `vim.lsp.enable` instead of `require('lspconfig')`, and don't call `require('nvim-treesitter.configs')`.

## Goals

### Done
- [x] Project fuzzy-finder (sesh + fzf, shows all repos by default)
- [x] Efficient keybindings (1-9 session jumping, j/k cycling, popup-based tools)
- [x] Git diff quick-view (lazygit popup)
- [x] GitHub CI/PR status popup with live `gh run watch`
- [x] Session persistence (resurrect + continuum)
- [x] Claude Code session status via hooks (working/idle/attention/review)
- [x] Status bar with numbered session icons, emojis, and active indicator
- [x] Instant dashboard with cached rendering and number-key navigation
- [x] Supervisor session for cross-session visibility and control
- [x] Neovim setup with Elm LSP and e-ink theme
- [x] Per-repo session icons (`.session-icon` files)
- [x] Scratch file convention (`.scratch/` directory)
- [x] tmux-fingers for hint-based text copying
- [x] OSC 52 clipboard for copy over SSH
- [x] Auto-launch Claude Code on new session creation

### In Progress
- [ ] E-ink theme fine-tuning (needs testing on BOOX tablet)

### Stretch
- [ ] Per-project goals tracking integrated into dashboard
- [ ] Cross-project status aggregation
- [ ] Git post-commit hook for instant cache updates on manual commits

## File Structure

```
tmux-config/
├── CLAUDE.md                          # This file — full project context
├── GOALS.md                           # Active project goals across repos
├── KEYBINDINGS.md                     # Quick reference for all keybindings
├── tmux.conf                          # Main tmux config (symlinked to ~/.tmux.conf)
├── nvim/
│   └── init.lua                       # Neovim config (symlinked to ~/.config/nvim/init.lua)
├── supervisor/
│   └── CLAUDE.md                      # Instructions for the supervisor Claude session
└── scripts/
    ├── claude-dashboard.sh            # Dashboard viewer: fullscreen, press 1-9 to jump
    ├── claude-dashboard-render.sh     # Renders dashboard to ~/.cache/claude-dashboard.cache
    ├── claude-status-update.sh        # Hook: update status + git on tool use
    ├── claude-status-stop.sh          # Hook: mark idle + git on stop
    ├── claude-status-attention.sh     # Hook: mark attention on notification
    ├── gh-status.sh                   # GitHub CI/PR popup with live watching
    ├── statusbar-sessions.sh          # Status bar: numbered session icons
    ├── supervisor.sh                  # Create/toggle supervisor session
    ├── switch-session.sh              # Jump to Nth session (used by 1-9 bindings)
    ├── project-switcher.sh            # Legacy (replaced by sesh)
    ├── session-picker.sh              # Legacy (replaced by sesh)
    └── session-status.sh              # Legacy (replaced by dashboard)
```

## External config files (not in this repo)

| File | Purpose |
|------|---------|
| `~/.claude/settings.json` | Claude Code hooks (PostToolUse, Stop, Notification) — must use absolute paths |
| `~/.claude/CLAUDE.md` | Global Claude instructions (session goals, status updates, scratch file convention) |
| `~/.config/sesh/sesh.toml` | Sesh config (wildcard pattern for repos) |
| `~/.gitignore_global` | Ignores: `.claude-status.json`, `.claude-status.json.lock`, `.session-icon`, `.scratch/`, `.claude` |
| `~/.zshrc` | Contains `eval "$(zoxide init zsh)"` for zoxide |

## Setup on a new machine

```bash
# 1. Clone this repo
git clone git@github.com:dillonkearns/tmux-config.git ~/src/github.com/dillonkearns/tmux-config

# 2. Install dependencies
brew install tmux neovim lazygit jq fzf tree-sitter
brew install joshmedeski/sesh/sesh
npm install -g @elm-tooling/elm-language-server

# 3. Install tmux plugins
git clone https://github.com/tmux-plugins/tmux-resurrect ~/.tmux/plugins/tmux-resurrect
git clone https://github.com/tmux-plugins/tmux-continuum ~/.tmux/plugins/tmux-continuum
git clone https://github.com/Morantron/tmux-fingers ~/.tmux/plugins/tmux-fingers

# 4. Symlink configs
ln -sf ~/src/github.com/dillonkearns/tmux-config/tmux.conf ~/.tmux.conf
mkdir -p ~/.config/nvim
ln -sf ~/src/github.com/dillonkearns/tmux-config/nvim/init.lua ~/.config/nvim/init.lua

# 5. Add zoxide to shell
echo 'eval "$(zoxide init zsh)"' >> ~/.zshrc

# 6. Seed zoxide with repos
for dir in ~/src/github.com/dillonkearns/*/; do zoxide add "$dir"; done

# 7. Configure Claude Code hooks (see ~/.claude/settings.json)
# 8. Configure global CLAUDE.md (see ~/.claude/CLAUDE.md)
```

## Conventions

- This repo's `tmux.conf` is the source of truth for tmux. `nvim/init.lua` for Neovim.
- Prefix key is `C-Space` (Ctrl+Space) — do NOT use `C-a` (conflicts with Emacs C-a/C-e keybindings Dillon uses heavily)
- All custom bindings documented in `KEYBINDINGS.md`
- Per-repo files (`.claude-status.json`, `.session-icon`, `.scratch/`) are globally gitignored
- Status bar scripts must be fast (<200ms) — no git calls, read cached data only
- Hook scripts use absolute paths (tilde doesn't expand in Claude Code hook execution)
- Supervisor session is always index 0, regular sessions are 1-9
