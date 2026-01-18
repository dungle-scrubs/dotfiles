# WezTerm Configuration

## Overview

Modular WezTerm configuration with vim-style keybindings, workspace management, and a smart status bar.

## File Structure

```
.config/wezterm/
├── wezterm.lua           # Entry point
├── configs/
│   ├── colors.lua        # Color palette
│   ├── design.lua        # Visual settings, tab formatting
│   ├── events.lua        # Custom events (scrollback → nvim)
│   ├── keybinds.lua      # All keybindings and key tables
│   ├── launch_menu.lua   # Launch menu entries
│   ├── paths.lua         # Binary paths (fd, nvim, etc.)
│   ├── status.lua        # Right status bar rendering
│   └── util.lua          # Helper functions
└── functions/
    ├── balance.lua       # Pane balancing
    ├── focus_zoom.lua    # Auto-zoom focused pane
    ├── projects.lua      # Project picker (fd + InputSelector)
    └── workspace.lua     # Workspace management
```

## Keybindings

### Tier 1: Direct Keys (No Leader)

| Key | Action |
|-----|--------|
| `Shift+Enter` | Send literal newline (useful in Claude Code) |
| `Alt+h/j/k/l` | Navigate panes (with auto-zoom if enabled) |
| `Ctrl+Alt+h/l` | Navigate tabs (prev/next) |
| `Ctrl+Alt+Shift+h/l` | Navigate workspaces (prev/next) |
| `Ctrl+L` | Debug overlay |

### Tier 2: Leader (`Alt+Space`) + Single Key

| Key | Action |
|-----|--------|
| `o` | **Open project picker** → switch workspace |
| `p` | Enter **pane** key table |
| `t` | Enter **tab** key table |
| `w` | Enter **workspace** key table |
| `y` | Yank mode (copy mode) |
| `s` | Send scrollback to nvim |
| `q` | QuickSelect (URLs, hashes, paths, emails) |
| `u` | Unicode/emoji picker |
| `b` | Balance panes horizontally |
| `z` | Toggle focus zoom mode |
| `r` | Rotate panes clockwise |
| `k` | Command palette |
| `l` | Launch menu |

### Tier 3: Key Tables

#### Pane (`Leader → p`)

| Key | Action |
|-----|--------|
| `d` | Close pane |
| `s` | Split horizontal (33%) |
| `v` | Split vertical (33%) |
| `z` | Enter resize mode |
| `S` | Swap panes (PaneSelect) |
| `t` | Break pane to new tab |
| `Escape` | Exit |

#### Pane Resize (`Leader → p → z`)

| Key | Action |
|-----|--------|
| `h/j/k/l` | Resize in direction |
| `Escape` | Exit |

#### Tab (`Leader → t`)

| Key | Action |
|-----|--------|
| `d` | Close tab |
| `h/l` | Move tab left/right |
| `n` | New tab |
| `N` | New tab with name prompt |
| `r` | Rename tab |
| `c` | Clone workspace (duplicate) |
| `p` | Open project in new tab |
| `Escape` | Exit |

#### Workspace (`Leader → w`)

| Key | Action |
|-----|--------|
| `w` | Fuzzy workspace picker |
| `o` | Switch to previous workspace |
| `d` | Delete current workspace |
| `n` | New workspace (project picker) |
| `r` | Rename workspace |
| `Escape` | Exit |

## Features

### Focus Zoom Mode

When enabled (`Leader → z`), navigating to a pane automatically resizes it to 80% of the tab. Useful for reading/editing while keeping context visible.

Status bar shows `ZOOM` indicator when active.

### Project Picker

`Leader → o` scans `~/dev/` for git repositories using `fd` and presents a fuzzy picker. Selecting a project:
1. Creates a new workspace named after the project
2. Sets the cwd to the project root
3. Stores previous workspace for quick switching

### QuickSelect Patterns

`Leader → q` highlights and allows quick copying of:
- URLs (`https?://...`)
- Git hashes (7-40 hex chars)
- File paths (`/foo/bar/baz`)
- Email addresses
- SRI hashes and base64 tokens

### Scrollback to Neovim

`Leader → s` dumps the entire scrollback buffer to a temp file and opens it in neovim in a new tab. Useful for searching through long command output.

### Status Bar

**Right status** shows contextually:
- **Key table active**: Shows available keys and descriptions
- **Normal mode**: Process name, git branch (with ahead/behind), workspace name, workspace indicators

## Configuration Details

### Performance

```lua
config.max_fps = 120
config.front_end = "WebGpu"
config.prefer_egl = true
```

### Unix Domain (Mux)

```lua
config.unix_domains = {{ name = "unix" }}
```

Enables local multiplexer for session persistence.

### Design

- Font: JetBrains Mono, 16pt
- Tab bar at bottom, max 28 chars per tab
- Window decorations: resize only (no title bar)
- Inactive panes dimmed to 50% brightness

## Common Tasks

### Add a new key table entry

Edit `configs/keybinds.lua`, add to `config.key_tables.<table_name>`:

```lua
{ key = "x", desc = "Description", action = act.SomeAction },
```

### Add a launch menu item

Edit `configs/launch_menu.lua`:

```lua
config.launch_menu = {
  { label = "name", cwd = "/path", args = { "cmd" } },
}
```

### Modify status bar

Edit `configs/status.lua`. Add new functions following the `add_*` pattern and call them in the `update-right-status` event handler.

## Dependencies

External binaries (configured in `configs/paths.lua`):
- `fd` - Fast file finder for project discovery
- `nvim` - For scrollback viewing
- `wezterm` CLI - For workspace management
