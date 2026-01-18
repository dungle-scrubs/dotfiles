# dotfiles

macOS dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## What's Included

| Package | Description |
|---------|-------------|
| [aerospace](aerospace/) | Tiling window manager |
| [atuin](atuin/) | Shell history search & sync |
| [git](git/) | Git configuration |
| [jq](jq/) | jq JSON processor config |
| [kanata](kanata/) | Keyboard remapping |
| [launchagents](launchagents/) | macOS startup services |
| [nvim](nvim/) | Neovim (LazyVim-based) |
| [starship](starship/) | Cross-shell prompt |
| [wezterm](wezterm/) | Terminal emulator |
| [yazi](yazi/) | Terminal file manager |
| [zsh](zsh/) | Shell configuration |

## Requirements

- macOS
- [Homebrew](https://brew.sh)
- [GNU Stow](https://www.gnu.org/software/stow/) (`brew install stow`)

## Installation

```bash
# Clone
git clone https://github.com/dungle-scrubs/dotfiles.git ~/dev/dotfiles
cd ~/dev/dotfiles

# Stow all packages
stow -t ~ */

# Or stow individual packages
stow -t ~ zsh nvim wezterm
```

### Zsh Setup

Zsh requires `~/.zshenv` to point to the config:

```bash
# If stow didn't create it (home dir issues), create manually:
ln -s ~/dev/dotfiles/zsh/.zshenv ~/.zshenv
```

## Structure

```
dotfiles/
├── <package>/
│   ├── .config/
│   │   └── <package>/
│   │       └── config files...
│   └── CLAUDE.md          # Package documentation
├── .stowrc                 # Stow ignore patterns
└── CLAUDE.md               # Repository overview
```

Each package follows XDG conventions. When stowed, `~/.config/<package>` symlinks to the repo.

## Key Features

### Zsh
- No Oh My Zsh (direct plugin sourcing for speed)
- Cached init files for atuin/zoxide/starship
- Lazy-loaded NVM
- Vi-mode with preserved keybindings

### WezTerm
- Workspace and project picker
- Catppuccin theme
- Custom status bar

### Starship
- Minimal left prompt (directory + character)
- Right-side info (git, languages, time)
- Catppuccin Mocha palette

### Kanata
- Home row mods (Caps Lock → Esc/Ctrl)
- Layer-based key remapping

## Updating

```bash
cd ~/dev/dotfiles
git pull
stow -R -t ~ */  # Re-stow all packages
```

## Documentation

Each package has a `CLAUDE.md` file with package-specific documentation, keybindings, and configuration details.

## License

MIT
