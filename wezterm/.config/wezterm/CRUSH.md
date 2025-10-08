# Wezterm Configuration

## Overview
This is a Lua-based Wezterm terminal configuration using a modular structure.

## Commands
- No specific build commands needed (Lua files are interpreted)
- No testing framework configured
- Reload configuration with `wezterm cli reload-config` or `⌘ + ⇧ + R`

## LSP
- Lua LSP configured via `.luarc.jsonc`
- Uses EmmyLua-style annotations for type checking
- Formatting enabled with 2-space indentation
- Single quote style preferred
- Type definitions in `types/` directory provide enhanced IDE support

## Code Style
- Use 2 space indentation
- Files are organized in a modular structure under `configs/`, `types/`, `scripts/`, and `functions/`
- Separate configuration concerns into different files:
  - Key bindings: `configs/keybinds.lua`
  - Visual design: `configs/design.lua`
  - Status line: `configs/status.lua`
  - Launch menu: `configs/launch_menu.lua`
- Type definitions are in `types/` directory for better IDE support
- Shell scripts are in `scripts/` directory for complex operations
- Utility functions are in `functions/` directory

## Naming Conventions
- Lua files use snake_case
- Configuration variables use snake_case
- Function names use snake_case
- Constants use UPPER_SNAKE_CASE

## Imports
- Use `require` for including modules
- Local variables are preferred over global when possible
- Configuration modules are typically required in `wezterm.lua` which is the entry point

## Formatting
- 2 space indentation
- Single quotes preferred
- No specific line length limit since this is configuration code
- Logical grouping of related configuration options

## Error Handling
- Minimal error handling since this is configuration code
- When needed, use standard Lua error handling with `pcall`

## Additional Notes
- The configuration is heavily inspired by https://github.com/tjex/wezterm-conf
- Type definitions are copied from wezterm-types and expanded