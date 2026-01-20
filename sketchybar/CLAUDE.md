# SketchyBar Configuration

## Overview

SketchyBar is a custom macOS menu bar. This package uses the SketchyBar Lua API (SbarLua) with Catppuccin Macchiato theme and Nerd Font icons.

## File Structure

```
.config/sketchybar/
├── sketchybarrc   # Main Lua config
└── colors.lua     # Catppuccin Macchiato palette
```

## Requirements

- SketchyBar installed via Homebrew
- SbarLua installed (Lua API bindings)
- A Nerd Font installed (uses Hack Nerd Font for icons)

## Items

| Position | Item | Description |
|----------|------|-------------|
| Left | Apple menu | Popup with System Settings, Activity Monitor, Lock |
| Left | Front app | Active application name (auto-updates on switch) |
| Notch-left (`q`) | CPU/Disk | Vertically stacked percentage displays |
| Notch-right (`e`) | API Usage | Anthropic, OpenAI, Codex costs/usage popup |
| Right | Date/Time | Vertically stacked |
| Right | WiFi | IP address or VPN status |
| Right | Battery | Percentage with charging indicator |
| Right | Volume | Level with icon |
| Right | Weather | Current temp with forecast popup |

## Icon Font

Uses Nerd Font icons (Material Design + Octicons):
- `󰀵` Apple, `󰠭` Brain (Anthropic), `󰧑` OpenAI, `` Terminal (Codex)
- `󰖩` WiFi, `󰦝` VPN, `󰁹` Battery, `󰕾` Volume

## After Making Changes

```bash
cd ~/dev/dotfiles && stow sketchybar && sketchybar --reload
```

## Common Commands

```bash
sketchybar --reload                   # Reload config
stow sketchybar                       # Re-stow symlinks
brew services restart sketchybar      # Full restart
```
