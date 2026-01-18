# Atuin

Shell history sync and search. Docs cached in ai-docs.

## Commands

```bash
atuin search <query>      # Search history
atuin stats               # Usage statistics
atuin sync                # Manual sync
atuin history list        # List recent history
atuin dotfiles alias set <name> <command>  # Sync aliases across machines
atuin dotfiles alias list
```

## Config

Config at `~/.config/atuin/config.toml` (stow-managed).

Key settings:
- `filter_mode = "workspace"` - Filter to current git repo
- `filter_mode_shell_up_key_binding = "directory"` - Up-arrow = directory history
- `keymap_mode = "auto"` - Respects zsh-vi-mode

## Keybindings

| Key | Action |
|-----|--------|
| `Ctrl+R` | Global search |
| `Up` | Directory-filtered search |
| `Ctrl+R` (in search) | Cycle filter modes |
| `Ctrl+S` (in search) | Cycle search modes |
| `Ctrl+O` | Open inspector (delete/view) |
| `Tab` | Select and edit |
| `Enter` | Execute |

## Sync

Logged in as `dungle-scrubs`. Sync is automatic after commands.

```bash
atuin sync        # Force sync
atuin logout      # Logout
atuin login -u dungle-scrubs  # Re-login
```
