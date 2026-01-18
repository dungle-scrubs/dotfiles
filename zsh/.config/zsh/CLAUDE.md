# Zsh Configuration

XDG-compliant zsh setup with performance optimizations.

## File Structure

| File | When | Purpose |
|------|------|---------|
| `~/.zshenv` | All shells | Only sets `ZDOTDIR` - kept minimal |
| `.zprofile` | Login shells | Environment vars, PATH, runtime inits |
| `.zshrc` | Interactive | Plugins, aliases, functions, keybindings |
| `.zprofile.private` | Login | Private env vars (not version controlled) |
| `cache/` | - | Cached init scripts (gitignored) |

## Performance Features

### Cached Init Files
Tool initializers are cached to avoid spawning subshells on every shell start:

```bash
# Rebuild cache after updating tools
zsh-cache-rebuild
```

Caches: `atuin.zsh`, `zoxide.zsh`, `starship.zsh`

### Lazy NVM Loading
NVM only loads when you first call `nvm`, `node`, `npm`, or `npx`. Saves ~200ms on shell startup.

### Compinit Optimization
Completion dump only regenerates once per day.

## Plugins (from Homebrew)

- `zsh-syntax-highlighting` - Command highlighting
- `zsh-autosuggestions` - Fish-like suggestions
- `zsh-vi-mode` - Vi keybindings

No Oh My Zsh - direct plugin sourcing is faster.

## Key Bindings (Vi Insert Mode)

| Key | Action |
|-----|--------|
| `^r` | Atuin search |
| `^e` | Accept autosuggestion |
| `^w` | Execute autosuggestion |
| `^u` | Toggle autosuggestion |
| `^j/^k` | History navigation |
| `^o` | Zoxide interactive |
| `^L` | Forward word |

## Key Aliases

| Alias | Command |
|-------|---------|
| `l` | `eza -l --icons --git -a` |
| `lt` | `eza --tree --level=2` |
| `y` | Yazi with directory tracking |
| `lg` | lazygit |
| `cc` | claude |
| `sz` | Source .zshrc |

## Functions

| Function | Purpose |
|----------|---------|
| `y` | Yazi file manager with cd tracking |
| `cx <dir>` | cd + list |
| `fcd` | Fuzzy cd with fzf |
| `f` | Fuzzy file → clipboard |
| `fv` | Fuzzy file → nvim |
| `brew` | Wrapper that auto-updates Brewfile |
| `zsh-cache-rebuild` | Regenerate cached init files |

## Auto-behaviors

- **NVM auto-switch**: Detects `.nvmrc`/`.node-version` on directory change
- **Brewfile sync**: `brew install/uninstall/upgrade` auto-commits Brewfile changes
- **Direnv**: Auto-loads `.envrc` files

## Troubleshooting

```bash
# Slow startup? Profile it:
time zsh -i -c exit

# Rebuild caches after tool updates:
zsh-cache-rebuild

# Zsh-vi-mode clobbering bindings?
# Bindings are restored in zvm_after_init()
```
