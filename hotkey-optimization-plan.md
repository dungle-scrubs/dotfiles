# Hotkey System Optimization Plan

## Current Setup Analysis

### Services in Use
- **Karabiner**: Homerow mods (asdf/jkl; as meta keys when held), e→numpad, r→symbols
- **Hammerspoon**: Limited use (Shift+Ctrl for some operations)
- **Aerospace**: Tiled window management
- **Wezterm**: Terminal with multiplexer
- **VSCode & LazyVim**: Code editing (LazyVim via Neovim extension and standalone)

### Current Key Patterns
- **Shift+Opt**: Move apps to other Aerospace screens
- **Opt+[letter/number]**: Switch Aerospace workspaces (except jkl;)
- **Shift+Ctrl**: Wezterm standard keys
- **Cmd+Opt**: In-app hotkeys (browsers)
- **Cmd+Space**: Raycast launcher
- **Alt+hjkl**: Wezterm pane navigation
- **Ctrl+Alt+hl**: Wezterm workspace/tab navigation
- **Space (held)+hjkl**: Arrow keys
- **Caps Lock**: Escape (no Caps Lock functionality)

## Core Challenges

### The Multi-Context Navigation Problem
Need hjkl navigation across:
1. Aerospace windows
2. Wezterm panes  
3. VSCode panels/splits
4. Browser tabs

Current conflict: Alt+hjkl used for both Aerospace and Wezterm

### Multi-App Navigation Scenario
When Wezterm (with multiple panes) and another app are open:
- Need to focus Wezterm window (Aerospace operation)
- Need to navigate Wezterm panes (Wezterm operation)
- Same keys can't do both simultaneously

## Proposed Solution: Two-Step Navigation

### Core Principle: Clear Context Separation
- **Alt = Between Apps** (Aerospace window focus)
- **Ctrl = Within Apps** (app-specific navigation)

### Key Mappings

#### Navigation Keys
- **Alt+hjkl**: Focus between apps/windows (Aerospace)
  - Keep existing but rarely used
  - Primary window switching stays with Alt+letters
- **Ctrl+hjkl**: Navigate within focused app
  - In Wezterm: pane navigation
  - In VSCode: panel/split navigation
  - In browsers: could be tab navigation
  - Elsewhere: no-op or app-specific

#### Workspace Management
- **Alt+[letters]**: Aerospace workspace switching (keep as-is)
- **Alt+[1-9]**: Alternative workspace access
- **Shift+Alt+[letters]**: Move window to workspace and follow
- **Alt+`** or **Alt+Tab**: Workspace back-and-forth (instead of Alt+o)

#### Wezterm Specific
- **Leader (Alt+Space)**: Existing leader key
- **Leader+hjkl**: Alternative pane navigation (explicit mode)
- **Ctrl+Alt+hl**: Workspace/tab navigation (keep existing)
- **Ctrl+Shift+hjkl**: Resize panes

#### Tab as Meh Key (Shift+Ctrl+Alt)
- **Tab+r**: Raycast (move from Cmd+Space)
- **Tab+w**: Workspace switcher
- **Tab+t**: Terminal launcher
- **Tab+c**: Caps Lock toggle (since Caps is Escape)
- **Tab+k**: Show key reference
- **Tab+a**: App switcher

#### In-App Operations (Cmd+Alt)
- **Cmd+Alt+t**: New tab
- **Cmd+Alt+w**: Close tab
- **Cmd+Alt+r**: Reload
- **Cmd+Alt+n/p**: Next/prev tab
- **Cmd+K**: Keep for command palettes (universal pattern)

#### Keep Existing
- **Space (held)+hjkl**: Arrow keys
- **asdf/jkl; (held)**: Homerow mods
- **e (held)**: Numpad
- **r (held)**: Symbols

## Implementation Strategy

### Phase 1: Karabiner Configuration
1. Add Tab as Meh key with launcher shortcuts
2. Create app-specific rules:
   - VSCode: Ctrl+hjkl → panel navigation commands
   - Wezterm: Pass through Ctrl+hjkl
   - Browsers: Ctrl+hjkl → tab navigation (optional)
3. Add Tab+c for Caps Lock functionality

### Phase 2: Wezterm Configuration
1. Change pane navigation from Alt+hjkl to Ctrl+hjkl
2. Add Leader+hjkl as alternative pane navigation
3. Keep Ctrl+Alt+hl for workspace navigation
4. Add Ctrl+Shift+hjkl for pane resizing

### Phase 3: Aerospace Configuration
1. Keep Alt+letters for workspace switching
2. Ensure Alt+hjkl available for window focus (even if rarely used)
3. Add Alt+` for workspace back-and-forth
4. Configure Shift+Alt+letters for move-and-follow

### Phase 4: Hammerspoon Enhancement
1. Remove conflict with Shift+Ctrl+n/p (already in use)
2. Add context detection for future smart routing
3. Implement Tab+[key] launchers if Karabiner can't handle

### Phase 5: VSCode Integration
1. Configure keybindings for Ctrl+hjkl panel navigation
2. Map Ctrl+Shift+hjkl to move editors between groups
3. Ensure Cmd+K preserved for command palette

## Workflow Examples

### Navigate from Browser to Wezterm Pane
1. Alt+h → Focus Wezterm window
2. Ctrl+h → Navigate to left pane within Wezterm

### Work Across Multiple Apps
1. Alt+w → Switch to 'work' workspace
2. Alt+h/l → Focus between browser and terminal
3. In terminal: Ctrl+hjkl → Navigate panes
4. In browser: Cmd+Alt+t → New tab

### Quick Terminal Access
1. Tab+t → Launch terminal in current workspace
2. Ctrl+hjkl → Navigate panes immediately

## Benefits
- **Clear mental model**: Alt=between, Ctrl=within
- **No conflicts**: Each context has dedicated keys
- **Preserves preferences**: Alt+letters, homerow mods intact
- **Scalable**: Pattern works across all applications
- **Muscle memory friendly**: Consistent patterns

## Open Questions
1. Should Ctrl+hjkl at Wezterm pane edge jump to next Aerospace window?
2. Add smart detection to make navigation seamless?
3. Should browsers get Ctrl+hjkl for tab navigation?
4. Need Shift+Ctrl+hjkl for moving/resizing universally?

## Next Steps
1. Review and refine this plan
2. Test with temporary bindings
3. Implement phase by phase
4. Document final configuration
