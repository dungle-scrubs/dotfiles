# AeroSpace Keyboard Shortcuts

## Workspace Navigation

| Key | Action | Notes |
|-----|--------|-------|
| alt-1 to 9 | workspace 1-9 | |
| alt-a | workspace A | |
| alt-b | workspace B | |
| alt-c | workspace C | |
| alt-d | workspace D | |
| alt-e | workspace E | |
| alt-f | workspace F | |
| alt-g | workspace G | |
| alt-i | queue forward | aerospace-invader daemon |
| alt-m | workspace M | |
| alt-n | workspace N | |
| alt-o | queue back | aerospace-invader daemon |
| alt-p | workspace-back-and-forth | aerospace-invader daemon |
| alt-q | workspace Q | |
| alt-r | workspace R | |
| alt-s | workspace S | |
| alt-t | workspace T | |
| alt-u | workspace U | |
| alt-v | workspace V | |
| alt-w | workspace W | |
| alt-x | workspace X | |
| alt-y | workspace Y | |
| alt-z | workspace Z | |

## Focus Movement

| Key | Action |
|-----|--------|
| alt-left | focus left |
| alt-down | focus down |
| alt-up | focus up |
| alt-right | focus right |

## Window Movement

| Key | Action |
|-----|--------|
| alt-shift-left | move left |
| alt-shift-down | move down |
| alt-shift-up | move up |
| alt-shift-right | move right |
| alt-shift-1 to 9 | move to workspace + follow |
| alt-shift-a to z | move to workspace + follow |
| alt-shift-tab | move workspace to next monitor |

## Resize

| Key | Action |
|-----|--------|
| alt-minus | resize smart -50 |

## Modes

| Key | Action |
|-----|--------|
| alt-shift-; | enter service mode (whichkey via aerospace-invader) |

### Service Mode

| Key | Action |
|-----|--------|
| esc | reload config, exit service mode |
| e | toggle enable |
| r | flatten workspace tree |
| f | toggle floating/tiling |
| alt-shift-; | fullscreen |
| backspace | close all windows but current |
| / | layout tiles |
| , | layout accordion |
| h/j/k/l | move window left/down/up/right |
| alt-shift-h/j/k/l | join with left/down/up/right |

## TODO: Unassigned

| Key | Candidate Action |
|-----|------------------|
| alt-tab | *removed - reassign* |
| alt-h | workspace H (currently unbound) |
| alt-j | workspace J (currently unbound) |
| alt-k | workspace K (currently unbound) |
| alt-l | workspace L (currently unbound) |
| alt-equal | resize smart +50 |

## aerospace-invader Daemon

Handles workspace queue navigation with overlay:
- `alt-o` = queue back (older workspaces)
- `alt-i` = queue forward (newer workspaces)
- `alt-p` = workspace-back-and-forth
- `alt-shift-;` = whichkey overlay for service mode

Lost workspace bindings (now handled by daemon):
- **alt-i** was workspace I
- **alt-o** was workspace-back-and-forth

To access workspace I/O directly, use `alt-shift-i/o` (move window to workspace).
