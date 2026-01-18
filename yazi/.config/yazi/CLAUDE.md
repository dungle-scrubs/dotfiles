# Yazi File Manager

Blazing fast terminal file manager with vim keybindings and image preview.

## Config Files

| File | Purpose |
|------|---------|
| `yazi.toml` | Main config (layout, openers, plugins) |
| `keymap.toml` | All keybindings |
| `theme.toml` | Colors, icons, styles |

## Key Bindings

### Navigation
| Key | Action |
|-----|--------|
| `h/l` | Parent/child directory |
| `j/k` | Move down/up |
| `gg/G` | Top/bottom |
| `H/L` | History back/forward |
| `<C-u>/<C-d>` | Half page up/down |

### File Operations
| Key | Action |
|-----|--------|
| `y` | Yank (copy) |
| `x` | Cut |
| `p/P` | Paste / paste (overwrite) |
| `d/D` | Trash / permanent delete |
| `a` | Create file (append `/` for directory) |
| `r` | Rename |
| `-/_` | Symlink absolute/relative |

### Selection
| Key | Action |
|-----|--------|
| `<Space>` | Toggle select + move down |
| `v/V` | Visual mode / visual unset |
| `<C-a>` | Select all |
| `<C-r>` | Invert selection |

### Search & Filter
| Key | Action |
|-----|--------|
| `s` | Search via fd |
| `S` | Search via ripgrep (content) |
| `f` | Filter |
| `/` | Find next |
| `?` | Find previous |
| `n/N` | Next/previous match |
| `z` | Jump via fzf |
| `Z` | Jump via zoxide |

### Views & Modes
| Key | Action |
|-----|--------|
| `.` | Toggle hidden files |
| `<Tab>` | Spot (preview) hovered file |
| `w` | Task manager |
| `~` or `F1` | Help |

### Linemode (`m` prefix)
| Key | Action |
|-----|--------|
| `ms` | Show size |
| `mp` | Show permissions |
| `mm` | Show mtime |
| `mb` | Show btime |
| `mo` | Show owner |
| `mn` | None |

### Sort (`,` prefix)
| Key | Action |
|-----|--------|
| `,m/M` | Sort by mtime / reverse |
| `,s/S` | Sort by size / reverse |
| `,a/A` | Sort alphabetically / reverse |
| `,n/N` | Sort naturally / reverse |
| `,e/E` | Sort by extension / reverse |

### Copy paths (`c` prefix)
| Key | Action |
|-----|--------|
| `cc` | Copy full path |
| `cd` | Copy directory path |
| `cf` | Copy filename |
| `cn` | Copy name without extension |

### Goto (`g` prefix)
| Key | Action |
|-----|--------|
| `gh` | Home |
| `gc` | ~/.config |
| `gd` | ~/Downloads |
| `g<Space>` | Interactive jump |
| `gf` | Follow symlink |

### Tabs
| Key | Action |
|-----|--------|
| `t` | New tab with CWD |
| `1-9` | Switch to tab N |
| `[/]` | Previous/next tab |
| `{/}` | Swap tab left/right |

## Layout

```
ratio = [1, 4, 3]  # parent : current : preview
```

- Parent directory: 1 part
- Current directory: 4 parts
- Preview pane: 3 parts

## Openers

| Type | Action |
|------|--------|
| Text | `$EDITOR` |
| Image | `open` (macOS Preview) |
| Media | `mpv` |
| Archive | Extract via `ya pub extract` |

## Plugins

Uses built-in plugins:
- `fzf` - fuzzy file jumping (`z`)
- `zoxide` - smart directory jumping (`Z`)

## Preview Support

- Images: native + ImageMagick for AVIF/HEIC/JXL
- Video: thumbnail via ffmpeg
- PDF: page preview
- Code: syntax highlighting
- Archives: list contents
- Fonts: preview rendering

## Docs

https://yazi-rs.github.io/docs/
