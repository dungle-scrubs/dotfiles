# Attention Dashboard: Project-Based Reorganization

## Overview

Reorganize the Attention dashboard to display items by **Project** (business entity)
instead of by integration type. Each project can have multiple integrations from
different services.

## Goals

1. Show all projects at once in the main view with clear visual sections
2. Support multiple Slack workspaces (Fuse, Rack Warehouse)
3. Support multiple Linear teams per project
4. Keep calendar as a global section (not project-specific)
5. Pure Lua config file - no SQLite database
6. **Search bar** at top for fuzzy filtering items (replaces "Attention (N)" title)

## Config File Design

Create `~/.config/hammerspoon/attention-config.lua`:

```lua
return {
  projects = {
    {
      id = "fuse",
      name = "Fuse",
      color = "#5e6ad2",  -- Linear purple
      integrations = {
        slack = {
          token_env = "SLACK_BOT_TOKEN",  -- Reference env var
          channels = { "C123456", "C789012" },  -- Optional: filter to specific channels
        },
        linear = {
          api_key_env = "LINEAR_API_KEY",
          team_ids = { "FUSE" },  -- Filter to specific teams
        },
      },
    },
    {
      id = "rack",
      name = "Rack Warehouse",
      color = "#10b981",  -- Green
      integrations = {
        slack = {
          token_env = "RACK_SLACK_BOT_TOKEN",  -- Different workspace
          channels = {},  -- All channels
        },
      },
    },
    {
      id = "reviewsion",
      name = "Reviewsion",
      color = "#f97316",  -- Orange
      integrations = {
        linear = {
          api_key_env = "LINEAR_API_KEY",  -- Can share API key
          team_ids = { "REV" },
        },
      },
    },
  },

  -- Calendar stays global (not project-specific)
  calendar = {
    enabled = true,
    -- Optional: filter to specific calendars
    calendar_names = { "kevin@fuse.is", "Personal" },
  },
}
```

## Architecture Changes

### 1. New Config Module (`config.lua`)

```lua
-- Loads and validates attention-config.lua
-- Provides getConfig() and getProjectById(id)
-- Falls back to legacy env-var mode if no config exists
```

### 2. Refactor API Modules

Each API module needs to accept config instead of reading global env vars:

**slack.lua changes:**
- `fetchMentions(config, callback)` - takes integration config
- `fetchHistory(channelId, config, callback)`
- `fetchThread(channelId, threadTs, config, callback)`

**linear.lua changes:**
- `fetchIssues(config, callback)` - takes integration config with team filter
- `fetchDetail(identifier, config, callback)`

**calendar.lua stays mostly the same** - just add optional calendar name filter

### 3. New Fetch Orchestrator (`fetch.lua`)

```lua
-- Orchestrates fetching for all projects in parallel
-- Returns: { projects: { [projectId]: { linear: [], slack: {} } }, calendar: [] }

function fetchAllProjects(config, callback)
  -- For each project, fetch its integrations in parallel
  -- Merge results by project
end
```

### 4. UI Changes (`init.lua` render function)

**New layout - vertical sections by project with search bar:**

```
+------------------------------------------+
| [Search... ]                       (15)  |
+------------------------------------------+
| Calendar                                 |
|   Today                                  |
|     09:00 - Meeting with...              |
|   Tomorrow                               |
|     14:00 - Product review               |
+------------------------------------------+
| Fuse                          [#5e6ad2]  |
|   Linear (3)                             |
|     a  FUSE-123  Fix auth bug            |
|     b  FUSE-456  Add dark mode           |
|   Slack (2)                              |
|     c  #eng  john: Can you review...     |
+------------------------------------------+
| Rack Warehouse                [#10b981]  |
|   Slack (1)                              |
|     d  #general  New shipment arriving   |
+------------------------------------------+
| Reviewsion                    [#f97316]  |
|   Linear (2)                             |
|     e  REV-789  Update landing page      |
+------------------------------------------+
```

### 5. State Changes

```lua
obj.cache = {
  projects = {
    fuse = { linear = [], slack = { dms = [], channels = [] } },
    rack = { slack = { dms = [], channels = [] } },
  },
  calendar = [],
}
```

## Implementation Steps

### Phase 1: Config System
1. Create `config.lua` module
2. Create default `attention-config.lua` template
3. Add config loading to init.lua with backward compatibility

### Phase 2: API Refactoring
4. Refactor `slack.lua` to accept config parameter
5. Refactor `linear.lua` to accept config parameter
6. Update `calendar.lua` to support calendar name filtering

### Phase 3: Fetch Orchestrator
7. Create `fetch.lua` module
8. Update `init.lua` fetchAll to use new orchestrator

### Phase 4: UI Reorganization
9. Rewrite `render()` for project-based layout
10. Update click handlers to track project context
11. Update detail views to show project context

### Phase 5: Search Bar
12. Add search input state and rendering
13. Implement fuzzy match algorithm
14. Add key handlers for typing, Enter, Escape, Backspace
15. Filter items based on active search

### Phase 6: Testing & Polish
16. Test with multiple Slack workspaces
17. Test with multiple Linear teams
18. Add project color indicators to UI

## Migration Path

1. If `attention-config.lua` doesn't exist, fall back to current behavior
2. Current env vars become the "default" project
3. Users can gradually migrate to project-based config

## Files to Create/Modify

**New files:**
- `config.lua` - Config loading and validation
- `fetch.lua` - Multi-project fetch orchestrator
- `search.lua` - Fuzzy search/filter logic
- `~/.config/hammerspoon/attention-config.lua` - User config

**Modified files:**
- `init.lua` - New render logic, state structure, search bar
- `api/slack.lua` - Accept config parameter
- `api/linear.lua` - Accept config parameter
- `api/calendar.lua` - Add calendar name filter

## Search Bar Feature

### Behavior
- Shows at top of dashboard as an input field
- Starts empty, placeholder: "Search..."
- Typing accumulates characters (no immediate filter)
- **Enter** applies fuzzy filter to all items
- **Escape** clears search and shows all items
- **Backspace** removes last character
- Item count "(15)" shows filtered count when searching

### Fuzzy Matching
Use simple fuzzy match algorithm:
```lua
-- Match if all characters in query appear in target in order
-- "fxau" matches "Fix auth bug"
function fuzzyMatch(query, target)
  local qi = 1
  for i = 1, #target do
    if target:sub(i,i):lower() == query:sub(qi,qi):lower() then
      qi = qi + 1
      if qi > #query then return true end
    end
  end
  return false
end
```

### What Gets Searched
- Calendar event titles
- Linear issue identifiers and titles
- Slack message text and channel names
- Project names (matching project shows all its items)

### State
```lua
obj.searchQuery = ""     -- Current typed query
obj.activeFilter = ""    -- Applied filter (after Enter)
```

### Key Handling
- Regular characters: append to searchQuery, re-render search bar only
- Enter: set activeFilter = searchQuery, re-render full dashboard
- Escape: if searchQuery or activeFilter, clear both; else close dashboard
- Backspace: remove last char from searchQuery

## Open Questions

1. Should project sections be collapsible?
2. Should there be a "collapsed by default if empty" behavior?
3. How to handle errors per-project (show error in section vs alert)?
4. Should search be "live" (filter as you type) or only on Enter?
