# Tmux Keybindings Reference

Quick reference for the keybindings in this config. `Prefix` = `C-Space` (Ctrl+Space).

## Essential Concepts

- **Prefix key**: Press `C-Space` first, release, then press the next key. This is how all tmux commands start (unless bound without prefix).
- **Session**: A named collection of windows. We use one session per project/repo.
- **Window**: A tab within a session. Usually one per task (e.g., Claude Code, shell, diff).
- **Pane**: A split within a window. Useful for side-by-side views.

## Sessions (project-level)

| Keys | Action |
|------|--------|
| `Prefix + f` | **sesh** — fuzzy-find projects & sessions (create or switch) |
| `Prefix + s` | **sesh** — same as above (easy to remember either way) |
| `Prefix + j` | Next session |
| `Prefix + k` | Previous session |
| `Prefix + $` | Rename current session |
| `Prefix + d` | Detach from tmux (back to SSH shell) |
| `Prefix + L` | Switch to last (most recent) session |

## Windows (tabs within a session)

| Keys | Action |
|------|--------|
| `Prefix + c` | Create new window |
| `Prefix + n` | Next window |
| `Prefix + p` | Previous window |
| `Prefix + 1-9` | Jump to window by number |
| `Prefix + ,` | Rename window |
| `Prefix + &` | Close window (with confirmation) |
| `Prefix + l` | Toggle to last active window |

## Panes (splits within a window)

| Keys | Action |
|------|--------|
| `Prefix + \|` | Split vertically (side by side) |
| `Prefix + -` | Split horizontally (top/bottom) |
| `Prefix + arrow keys` | Move between panes |
| `Prefix + z` | **Toggle pane zoom** (fullscreen a pane, press again to restore) |
| `Prefix + x` | Close pane (with confirmation) |
| `Prefix + Space` | Cycle pane layouts |

## Git / GitHub

| Keys | Action |
|------|--------|
| `Prefix + g` | Open **lazygit** in a popup window (press `q` to close) |
| `Prefix + h` | **GitHub status** popup — CI runs, PR status, working tree |

## Dashboard

| Keys | Action |
|------|--------|
| `Prefix + D` | **Claude Code dashboard** — status of all sessions |

## Session Persistence (tmux-resurrect)

| Keys | Action |
|------|--------|
| `Prefix + C-s` | **Save** all sessions (persists across reboot) |
| `Prefix + C-r` | **Restore** saved sessions |

## Copy Mode (scrolling & selecting)

| Keys | Action |
|------|--------|
| `Prefix + [` | Enter copy mode (for scrolling) |
| `q` | Exit copy mode |
| `Up/Down` or `k/j` | Scroll line by line (in copy mode) |
| `PgUp/PgDn` | Scroll by page (in copy mode) |
| `Space` | Start selection (in copy mode) |
| `Enter` | Copy selection (in copy mode) |
| `Prefix + ]` | Paste |

## Misc

| Keys | Action |
|------|--------|
| `Prefix + :` | Command prompt (type tmux commands directly) |
| `Prefix + r` | Reload tmux config |
| `Prefix + ?` | List all keybindings |

## Tips for E-ink

- Use `Prefix + z` (zoom) instead of splits when you want to focus on one thing — better on the small screen
- `Prefix + f` (project switcher) is your main navigation — learn to love it
- Scrolling in copy mode is more e-ink friendly than mouse scrolling (less partial redraws)
- Keep window count low per session — you can always `Prefix + c` a new one
