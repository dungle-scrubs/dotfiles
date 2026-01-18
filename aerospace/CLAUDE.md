# AeroSpace Configuration

## Overview

AeroSpace is a tiling window manager for macOS (i3-like). This config uses letter-based workspaces with a custom `aerospace-invader` daemon for workspace queue navigation.

## File Structure

```
.config/aerospace/
├── aerospace.toml    # Main config
└── kb-shortcuts.md   # Keybinding reference
```

## Keybindings

### Focus Movement

| Key | Action |
|-----|--------|
| `Alt+←/↓/↑/→` | Focus window in direction |

### Window Movement

| Key | Action |
|-----|--------|
| `Alt+Shift+←/↓/↑/→` | Move window in direction |
| `Alt+Shift+1-9` | Move window to workspace + follow |
| `Alt+Shift+A-Z` | Move window to workspace + follow |
| `Alt+Shift+Tab` | Move workspace to next monitor |

### Workspace Navigation

| Key | Action |
|-----|--------|
| `Alt+1-9` | Switch to workspace 1-9 |
| `Alt+A-Z` | Switch to workspace A-Z (except reserved) |
| `Ctrl+Alt+Shift+←/→` | Prev/next non-empty workspace |

### aerospace-invader Daemon Keys

| Key | Action |
|-----|--------|
| `Alt+I` | Queue forward (newer workspaces) |
| `Alt+O` | Queue back (older workspaces) |
| `Alt+P` | Toggle previous workspace |
| `Alt+Shift+;` | Whichkey overlay for service mode |

**Note**: `Alt+I/O/P` are handled by the daemon, not AeroSpace directly.

### Resize

| Key | Action |
|-----|--------|
| `Alt+-` | Shrink focused window by 50px |

### Service Mode (`Alt+Shift+;`)

Enters modal mode with whichkey overlay:

| Key | Action |
|-----|--------|
| `Esc` | Reload config, exit mode |
| `E` | Toggle AeroSpace enable |
| `R` | Flatten workspace tree |
| `F` | Toggle floating/tiling |
| `Alt+Shift+;` | Fullscreen toggle |
| `Backspace` | Close all windows but current |
| `/` | Tiles layout (horizontal/vertical) |
| `,` | Accordion layout |
| `H/J/K/L` | Move window + exit |
| `Alt+Shift+H/J/K/L` | Join with window + exit |

## Configuration Details

### Monitor Assignment

All numbered workspaces (1-9) are forced to external monitor `MDS-156F13`:

```toml
[workspace-to-monitor-force-assignment]
1 = 'MDS-156F13'
...
```

### Gaps

- Inner gaps: 15px
- Outer gaps: 5px (40px top on main monitor for menu bar)

### JankyBorders

Starts automatically on AeroSpace startup:
- Active window: green border (`0xff00ff00`)
- Inactive: gray (`0xff494d64`)
- Width: 5px

### Disabled macOS Keys

```toml
cmd-h = []     # Disable "hide application"
cmd-alt-h = [] # Disable "hide others"
cmd-m = []     # Disable "minimize"
```

### Normalization

Both normalization features disabled to preserve manual container nesting:

```toml
enable-normalization-flatten-containers = false
enable-normalization-opposite-orientation-for-nested-containers = false
```

## Integration

### aerospace-invader

External daemon providing:
- Workspace queue with visual overlay
- `whichkey` command for service mode hints

### JankyBorders

Started via `after-startup-command` for visual window focus indication.

## Common Commands

```bash
# Reload config
aerospace reload-config

# List workspaces
aerospace list-workspaces --all

# Focus window
aerospace focus left|down|up|right
```

## Unbound Keys (Available)

| Key | Notes |
|-----|-------|
| `Alt+H/J/K/L` | Currently unbound (could be workspaces) |
| `Alt+=` | Could be resize +50 |
| `Alt+Tab` | Removed, available for reassignment |
