# tmux-config

Dillon's tmux configuration, optimized for remote development from a BOOX Note Air 5 C e-ink tablet.

## Setup Overview

- **Host machine**: MacBook Pro (runs tmux server, all dev tools, Claude Code)
- **Local terminal**: Warp (used on the MacBook directly)
- **Client device**: BOOX Note Air 5 C (Android e-ink tablet with color display)
- **Connection**: SSH from BOOX tablet → MacBook, then `tmux attach`
- **Primary workspace**: `~/src/github.com/dillonkearns/` (~93 repositories)
- **tmux version**: 3.6a
- **Existing config**: `~/.tmux.conf` (this repo will manage it)

## Core Principles

1. **E-ink first** — Every design decision optimizes for a small, slow-refresh color e-ink screen. High contrast, minimal redraws, no animations, no transparency.
2. **Keyboard-driven efficiency** — The tablet is a dumb terminal. Every action should be reachable with minimal keystrokes. Fuzzy finding, not browsing.
3. **Session-per-project** — Each repository gets its own tmux session. Jump between projects by switching sessions, not by cd-ing around.
4. **Claude Code as primary tool** — Most development happens through Claude Code. The tmux workflow should make it easy to run, monitor, and juggle multiple Claude Code sessions.
5. **Minimal and readable** — No visual noise. Status bar shows only what's needed. Content area is maximized.

## Workflow

### Daily flow
1. SSH into MacBook from BOOX tablet
2. Attach to tmux (or start new session)
3. Fuzzy-find a project → opens/attaches a named session in that repo
4. Run Claude Code in that session
5. Switch between project sessions as needed
6. Check diffs, commit status across projects

### Key capabilities needed
- **Project switching**: Fuzzy-find across `~/src/github.com/dillonkearns/` repos, attach/create session
- **Session juggling**: Quick switch between active tmux sessions (each is a project)
- **Diff viewing**: Quick way to see git diff in current project (toggle, not permanent split)
- **Status at a glance**: Which sessions are active, which have uncommitted changes

## Goals

### Immediate
- [ ] E-ink optimized color theme (high contrast, minimal colors, readable)
- [ ] Project fuzzy-finder (fzf-based session switcher)
- [ ] Efficient keybindings for session/window/pane management
- [ ] Git diff quick-view toggle

### Stretch / Dashboard
- [ ] Dashboard view showing all active sessions with status
- [ ] Per-project goals tracking (what am I trying to accomplish in each repo?)
- [ ] Claude Code session status — needs a clean data model, not process scraping. Open question: what's the right way to get structured status from Claude Code sessions? Could Claude Code itself write status to a known location? Is there a hook or API?
- [ ] Uncommitted changes indicator per session
- [ ] A way to list and prioritize concrete goals across projects

**Design constraint**: The dashboard should be built on a clean data model, not by scraping terminal output or guessing process state. Worth exploring whether Claude Code hooks, a status file convention, or some other structured approach could provide reliable session status.

## File Structure

```
tmux-config/
├── CLAUDE.md              # This file — project context and goals
├── tmux.conf              # Main tmux config (symlinked to ~/.tmux.conf)
├── scripts/
│   ├── project-switcher.sh    # fzf project finder + session creator
│   └── session-status.sh      # Show status of all sessions
├── KEYBINDINGS.md         # Quick reference for keybindings
└── GOALS.md               # Active project goals and priorities
```

## Conventions

- This repo's `tmux.conf` is the source of truth. Symlink: `ln -sf ~/src/github.com/dillonkearns/tmux-config/tmux.conf ~/.tmux.conf`
- Scripts go in `scripts/` and should be POSIX-friendly where possible
- Prefix key is `C-Space` (Ctrl+Space)
- All custom bindings documented in `KEYBINDINGS.md`
