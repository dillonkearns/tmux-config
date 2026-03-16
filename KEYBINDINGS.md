# Tmux Keybindings Reference

Quick reference for the keybindings in this config. `Prefix` = `C-Space` (Ctrl+Space).

## Essential Concepts

- **Prefix key**: Press `C-Space` first, release, then press the next key.
- **Session**: A named tmux session. One per project/repo. Numbered 1-9 in the status bar.
- **Window**: A tab within a session. Use `n`/`p` to cycle, or create with `c`.
- **Pane**: A split within a window. Use `z` to zoom, `|` and `-` to split.

## Sessions (the main navigation)

| Keys | Action |
|------|--------|
| `Prefix + f` or `s` | **Fuzzy-find** projects & sessions (sesh — creates new or switches) |
| `Prefix + 1-9` | **Jump to session by number** (matches status bar) |
| `Prefix + 0` or `o` | **Supervisor** — toggle to/from the supervisor Claude session |
| `Prefix + j` | Next session |
| `Prefix + k` | Previous session |
| `Prefix + L` | Switch to last (most recent) session |
| `Prefix + X` | **Kill current session** (switches to next first) |
| `Prefix + d` | Detach from tmux (back to SSH shell) |
| `Prefix + $` | Rename current session |

## Dashboard & Status

| Keys | Action |
|------|--------|
| `Prefix + Space` or `D` | **Claude Code dashboard** — fullscreen, press 1-9 to jump |
| `Prefix + g` | **lazygit** popup (press `q` to close) |
| `Prefix + h` | **GitHub status** — CI runs with live watching, PR status |

## Windows (tabs within a session)

| Keys | Action |
|------|--------|
| `Prefix + c` | Create new window |
| `Prefix + n` | Next window |
| `Prefix + p` | Previous window |
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

## Text & Clipboard

| Keys | Action |
|------|--------|
| `Prefix + F` | **tmux-fingers** — hint-based text grabbing. Press letter to copy, Shift+letter to paste. |
| `Prefix + [` | Enter copy mode (for scrolling and selecting) |
| `v` (in copy mode) | Start selection |
| `y` (in copy mode) | Copy selection |
| `q` (in copy mode) | Exit copy mode |
| `Prefix + ]` | Paste |

## Session Persistence

| Keys | Action |
|------|--------|
| `Prefix + C-s` | **Save** all sessions (persists across reboot) |
| `Prefix + C-r` | **Restore** saved sessions |
| *(auto)* | Sessions auto-save every 15 minutes via continuum |

## Misc

| Keys | Action |
|------|--------|
| `Prefix + r` | Reload tmux config |
| `Prefix + :` | Command prompt (type tmux commands directly) |
| `Prefix + ?` | List all keybindings |

## Status Bar Legend

```
●0🔭  ⠿ 1 📖  ◆2🦞  ●3⚙️   │ 14:30
│      │        │      │
│      │        │      └─ gray ● = idle
│      │        └─ yellow ◆ = review (idle + uncommitted changes)
│      └─ orange ⠿ = Claude working
└─ supervisor (always first)

Active session number has yellow background highlight.
```

## Tips for E-ink

- Use `Prefix + z` (zoom) instead of splits — better on the small screen
- `Prefix + f` is your main navigation — fuzzy-find everything
- `Prefix + 1-9` for instant session jumps (matches status bar numbers)
- `Prefix + F` (fingers) to grab text without mouse selection
- Scrolling in copy mode is more e-ink friendly than mouse scrolling
