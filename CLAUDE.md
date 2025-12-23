# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **macOS dotfiles repository** managed with **GNU Stow**. Each top-level directory is a stow package that gets symlinked to `$HOME`.

## Common Commands

```bash
# Stow all packages at once (preferred method)
stow */

# Install/link a single package (from repo root)
stow <package>          # e.g., stow wezterm

# Unlink a package
stow -D <package>

# Re-stow (unlink then link)
stow -R <package>

# Stow respects .stowrc which ignores .stowrc, DS_Store, and .git
```

### Karabiner (Goku)

```bash
cd karabiner/.config/karabiner
goku                    # Compile karabiner.edn → karabiner.json

# Force reload Karabiner
launchctl kickstart -k gui/$(id -u)/org.pqrs.karabiner.karabiner_console_user_server
```

**Important**: Never edit `karabiner.json` directly - always edit `karabiner.edn` and run `goku`.

### Hammerspoon

```bash
hs -c "hs.reload()"     # Reload config (ignore "message port invalidated" error)
```

**Important**: Always reload Hammerspoon after any config change.

#### Attention Spoon Loading Indicator

When implementing loading states in the Attention spoon, **always use the shared loading animator utility** from `utils.lua`. Do not create custom loading animations.

```lua
local utils = dofile(spoonPath .. "/utils.lua")

-- Set initial text
canvas[3].text = utils.getLoadingText()  -- "Loading ⠋"

-- Start animation
self.loadingAnimator = utils.createLoadingAnimator("Loading", function(text)
    canvas[3].text = text
end)

-- Stop when done
self.loadingAnimator.stop()
```

This ensures consistent, fixed-width loading indicators with a smooth braille spinner animation.

### AeroSpace

```bash
aerospace reload-config  # Reload config
```

### Homebrew

```bash
brew bundle --file=homebrew/Brewfile  # Install all packages
brew bundle dump --file=homebrew/Brewfile --force  # Export current packages
```

### WezTerm

**Important**: `~/.wezterm.lua` must NOT exist. WezTerm uses `~/.config/wezterm/init.lua` (managed by stow). If `~/.wezterm.lua` exists, it takes precedence and breaks the stow-managed config.

```bash
# Check and remove if it exists
rm -f ~/.wezterm.lua
```

## Architecture

### Stow Package Structure

Each package follows XDG conventions:
```
<package>/
└── .config/
    └── <package>/
        └── config files...
```

When stowed, `~/.config/<package>` becomes a symlink to the repo.

### Key Configurations

| Package | Config Location | Notes |
|---------|-----------------|-------|
| `karabiner` | `.config/karabiner/karabiner.edn` | Goku EDN format, see CLAUDE.md in package |
| `hammerspoon` | `.config/hammerspoon/init.lua` | Lua config, see CLAUDE.md in package |
| `aerospace` | `.config/aerospace/aerospace.toml` | TOML config |
| `wezterm` | `.config/wezterm/init.lua` | Modular Lua (design, keybinds, status) |
| `nvim` | `.config/nvim/` | LazyVim-based Neovim |
| `zsh` | `.config/zsh/.zshrc` | Requires `ZDOTDIR=$HOME/.config/zsh` in ~/.zshenv |
| `launchagents` | `Library/LaunchAgents/` | macOS LaunchAgents |

### Integration Points

- **AeroSpace ↔ Hammerspoon**: Service mode (`Alt+Shift+;`) triggers Hammerspoon overlay via `hs -c "aerospaceOverlay.show()"`
- **AeroSpace ↔ JankyBorders**: Starts borders on AeroSpace startup
- **Hammerspoon MenuHammer**: Modal menu system via `Ctrl+Alt+Space`
- **Karabiner home row mods**: A/S/D/F and J/K/L/; as modifiers when held

### Zsh Setup

Zsh uses XDG-style config. Requires this in `~/.zshenv`:
```bash
export ZDOTDIR=$HOME/.config/zsh
```

## Workflow

When changes are made and approved, always commit to `main` and push to origin:
```bash
git add -A && git commit -m "description" && git push origin main
```

**Plans**: When a plan is created in `.claude/plans/`, always commit and push to origin immediately.
