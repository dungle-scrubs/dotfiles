# Feature: Arc Tab Toggle (Back and Forth)

## Feature Description

Implement a quick toggle keybinding (`Opt+Cmd+O`) that switches between the current and last-visited tab within the current Arc browser space. This enables rapid context switching between two tabs without navigating through the tab list, similar to how `Ctrl+Shift+I` works for AeroSpace workspace back-and-forth.

## User Story

As a developer using Arc browser
I want to quickly toggle between my current tab and the previous tab I was viewing
So that I can rapidly switch context between reference material and active work without losing my place

## Problem Statement

Arc browser doesn't natively provide a "go to last tab" keyboard shortcut. When researching while coding, users frequently need to flip between two tabs (e.g., documentation and a PR, or API response and code). Currently this requires manually finding and clicking the previous tab or using Arc's tab switcher, which interrupts flow.

## Solution Statement

Implement a Hammerspoon-based tab history tracker that:

1. Monitors the active tab in Arc via AppleScript polling
2. Maintains a two-element history (current + previous) per Arc space
3. Persists this history to `~/.config/arc/tab-history.json` for survival across Hammerspoon reloads
4. Provides a toggle function bound to `Opt+Cmd+O` that swaps between current and last tab
5. Handles edge cases gracefully (deleted tabs, closed spaces, first launch)

## Affected Packages

- `hammerspoon` - Add arc tab toggle module to init.lua

## Integration Points

- **Hammerspoon ↔ Arc**: Uses AppleScript via `hs.osascript.applescript` to query and control Arc tabs
- **Extends existing arcBrowser**: Builds on the existing `arcBrowser` global in init.lua
- **Persistence**: Uses `~/.config/arc/` directory (respects XDG-style structure)

## Relevant Files

Use these files to implement the feature:

### Existing Files

- `hammerspoon/.config/hammerspoon/init.lua` - Main Hammerspoon config where `arcBrowser` module already exists (lines 273-376). Will extend this with tab tracking functionality and add the hotkey binding.

### New Files

- `~/.config/arc/tab-history.json` - Persisted tab history data (created at runtime, not stowed)

## Implementation Plan

### Phase 1: Foundation

Extend the existing `arcBrowser` module with tab-related AppleScript functions:

- `getCurrentTab()` - Get the active tab's ID and URL in the current space
- `getCurrentSpaceId()` - Get the active space's identifier
- `selectTabById(tabId)` - Focus a specific tab by its ID

### Phase 2: Core Implementation

Add tab history tracking and toggle logic:

- In-memory history table: `{ [spaceId] = { current = tabInfo, previous = tabInfo } }`
- `updateTabHistory(spaceId, tabInfo)` - Called when tab changes, shifts current→previous
- `toggleTab()` - The main function bound to the hotkey
- Timer-based polling to detect tab changes (Arc doesn't emit events we can watch)
- File-based persistence to `~/.config/arc/tab-history.json`

### Phase 3: Integration & Testing

- Bind `Opt+Cmd+O` using `hs.hotkey.bind({"alt", "cmd"}, "o", ...)`
- Handle graceful fallbacks (alert user if no previous tab exists)
- Test across multiple spaces, tab closures, and Hammerspoon reloads

## Step by Step Tasks

### 1. Add Tab Query Functions to arcBrowser

- Add `arcBrowser.getCurrentSpaceId()` function using AppleScript to get the active space index
- Add `arcBrowser.getCurrentTab()` function that returns `{ id, title, url, spaceId }` for the active tab
- Add `arcBrowser.selectTab(tabIndex, spaceIndex)` function to focus a specific tab

### 2. Implement Tab History Data Structure

- Add `arcBrowser.tabHistory = {}` table to store per-space tab history
- Add `arcBrowser.configDir` path constant (`~/.config/arc/`)
- Add `arcBrowser.historyFile` path constant (`~/.config/arc/tab-history.json`)

### 3. Implement Persistence Functions

- Add `arcBrowser.ensureConfigDir()` to create `~/.config/arc/` if needed
- Add `arcBrowser.saveHistory()` to write tab history to JSON file
- Add `arcBrowser.loadHistory()` to read tab history on startup
- Call `loadHistory()` during module initialization

### 4. Implement Tab Change Detection

- Add `arcBrowser.lastKnownTab = nil` to track previous poll result
- Add `arcBrowser.pollInterval = 1` (seconds) for polling frequency
- Add `arcBrowser.startTabWatcher()` function that:
  - Creates a timer using `hs.timer.doEvery()`
  - Calls `getCurrentTab()` each interval
  - Compares with `lastKnownTab` to detect changes
  - Updates history when tab changes
- Start the watcher during initialization

### 5. Implement History Update Logic

- Add `arcBrowser.updateHistory(tabInfo)` function that:
  - Gets current space ID from tabInfo
  - If space not in history, initializes it with `{ current = tabInfo, previous = nil }`
  - If tab changed within same space, shifts: `previous = current, current = tabInfo`
  - Calls `saveHistory()` after update

### 6. Implement Toggle Function

- Add `arcBrowser.toggleTab()` function that:
  - Gets current space ID
  - Looks up history for that space
  - If no previous tab exists, shows alert "No previous tab"
  - If previous tab exists, calls `selectTab()` with previous tab
  - Swaps current and previous in history (so next toggle goes back)

### 7. Implement Graceful Fallback for Deleted Tabs

- In `toggleTab()`, wrap `selectTab()` call in error handling
- If tab selection fails (tab was closed), show alert "Tab no longer exists"
- Clear the invalid previous entry from history
- Try to find the tab by URL as backup (tabs can be reopened with same URL)

### 8. Add Hotkey Binding

- Add `hs.hotkey.bind({"alt", "cmd"}, "o", arcBrowser.toggleTab)` in the hotkey section of init.lua
- Add a short comment explaining the binding

### 9. Validation Commands

- `hs -c "hs.reload()"` - Reload Hammerspoon config
- Open Arc, switch between tabs, verify history tracking works
- Press `Opt+Cmd+O` to verify toggle works
- Close a tab, attempt toggle, verify graceful fallback
- Restart Hammerspoon, verify history persisted

## Testing Strategy

### Manual Testing

1. Open Arc with at least 2 tabs in a space
2. View Tab A, then switch to Tab B manually
3. Press `Opt+Cmd+O` - should switch back to Tab A
4. Press `Opt+Cmd+O` again - should switch back to Tab B
5. Test with multiple Arc spaces - history should be independent per space

### Config Validation

- `hs -c "print(hs.inspect(arcBrowser.tabHistory))"` - Verify history structure
- `cat ~/.config/arc/tab-history.json` - Verify persistence file format
- `hs -c "arcBrowser.getCurrentTab()"` - Verify tab query works

### Edge Cases

1. **No previous tab**: First tab in a new space - should show "No previous tab" alert
2. **Deleted tab**: Close the previous tab, then toggle - should show "Tab no longer exists" and clear history
3. **Arc not running**: Toggle when Arc is closed - should fail gracefully
4. **Multiple windows**: Behavior with multiple Arc windows (focus on front window)
5. **Empty space**: Space with no tabs
6. **Hammerspoon reload**: History should persist and be restored

## Acceptance Criteria

- [ ] `Opt+Cmd+O` toggles between current and last tab within the same Arc space
- [ ] Tab history is tracked independently for each Arc space
- [ ] History persists across Hammerspoon reloads (saved to `~/.config/arc/tab-history.json`)
- [ ] Graceful alert shown when no previous tab exists
- [ ] Graceful handling when previous tab has been closed
- [ ] No noticeable performance impact from tab polling (1-second interval)
- [ ] Works correctly with Arc's front window

## Validation Commands

Execute every command to validate the feature works correctly.

### Hammerspoon

- `hs -c "hs.reload()"` - Reload Hammerspoon config
- `hs -c "print(hs.inspect(arcBrowser.tabHistory))"` - Check history state
- `hs -c "print(hs.inspect(arcBrowser.getCurrentTab()))"` - Test tab query

### Persistence

- `ls -la ~/.config/arc/` - Verify config directory exists
- `cat ~/.config/arc/tab-history.json` - Verify history file format

## Notes

- **Polling vs Events**: Arc doesn't provide AppleScript notifications for tab changes, so we use polling. A 1-second interval balances responsiveness with performance.
- **Tab Identification**: Tabs are identified by their index within a space, not by URL, since the same URL can appear in multiple tabs.
- **Future Enhancement**: Could add `Opt+Cmd+Shift+O` to show a visual indicator of the previous tab before switching.
- **Arc CLI Reference**: The implementation draws from [arc-cli](https://github.com/GeorgeSG/arc-cli) AppleScript patterns for tab/space queries.
