# Hammerspoon Configuration

## Reloading Config

After making changes, reload Hammerspoon with:

```bash
hs -c "hs.reload()"
```

The error about "message port was invalidated" is expected during reload.

## MenuHammer Spoon

MenuHammer provides a modal menu system triggered by `Ctrl+Alt+Space`.

### Cheat Sheet Feature

The menu displays a cheat sheet panel in the top-right corner, configured in `MenuConfigDefaults.lua`:

```lua
menuCheatSheet = {
    enabled = true,
    title = "Claude Code",
    items = {
        "Ctrl+Alt+R  Search prompts",
    },
    font = "CaskaydiaCove Nerd Font Mono",
    fontSize = 12,
    -- ...
}
```

The cheat sheet is rendered using `hs.canvas` in `Menu.lua:getCheatSheetCanvases()`. It creates canvas elements for:

- Background rectangle with rounded corners
- Border stroke
- Title text
- Item texts (one per line)

### Key Files

- `Spoons/MenuHammer.spoon/MenuConfigDefaults.lua` - Menu definitions, colors, cheat sheet config
- `Spoons/MenuHammer.spoon/Menu.lua` - Menu rendering, cheat sheet canvas generation
- `Spoons/MenuHammer.spoon/MenuItem.lua` - Individual menu item rendering
- `Spoons/MenuHammer.spoon/MenuManager.lua` - Menu lifecycle, hotkey bindings

### Navigation

- `Escape` - Back (in submenus) or Exit (at root)
- Menu hotkey toggles the menu open/closed

### WezTerm Workspaces

The `openWezTermAt(dir, workspace)` helper opens WezTerm at a directory on an AeroSpace workspace. Uses `hs.task` for async execution to avoid blocking.
