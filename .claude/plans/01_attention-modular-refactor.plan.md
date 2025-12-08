# Refactor: Attention Spoon Modular Architecture

## Refactor Description

Reorganize the Attention spoon from a monolithic `init.lua` (1846 lines) into a modular, well-documented architecture with:

- Shared design tokens (JSON) for both Lua canvas and TypeScript webviews
- Per-view input handlers instead of one massive event handler
- Extracted canvas rendering modules
- Consistent keyboard patterns across all views

## Motivation

1. **Maintainability**: `init.lua` is 1846 lines with 500+ line functions - hard to navigate and modify
2. **Design inconsistency**: AI chat uses purple (#8b5cf6), Slack uses blue (#5e6ad2), no shared tokens
3. **Code duplication**: Fuzzy match, model lists, and vim-style patterns duplicated across files
4. **Coupling**: All views handled in one event handler, making per-view behavior changes risky

## Current State Analysis

### File Sizes

| File | Lines | Issue |
|------|-------|-------|
| `init.lua` | 1846 | Monolithic - contains rendering, state, event handling |
| `ui/slack.lua` | 492 | Good pattern but CSS in styles.lua |
| `ui/ai-chat.lua` | 416 | Has own inline CSS, different color scheme |
| `ui/styles.lua` | 204 | Only serves slack.lua, not ai-chat.lua |
| `webview/src/app.tsx` | 570 | Has vim hints system (reusable) |
| `webview/src/ai-chat.tsx` | 398 | Duplicates fuzzy match, model list |

### Key Problems

1. **`setupEventHandlers()`** (550+ lines) handles:
   - Main view navigation (j/k, number keys, enter)
   - Search mode (typing, backspace, enter)
   - LLM mode (typing, model selection)
   - Detail views (scroll, back, specific actions)
   - All in one massive if/else chain

2. **`render()`** (520 lines) builds entire main dashboard canvas inline

3. **Design tokens scattered**:
   - `#1a1a1a` (bgPrimary) hardcoded in init.lua line 183
   - `#8b5cf6` (purple accent) in ai-chat.lua
   - `#5e6ad2` (blue accent) in styles.lua
   - No single source of truth

4. **Duplicate code**:
   - `fuzzyMatch()` in init.lua:106, ai-chat.tsx:43
   - `LLM_MODELS` in init.lua:82, ai-chat.tsx:29
   - Vim scroll helpers repeated in multiple places

## Target State

### Directory Structure

```
Attention.spoon/
├── init.lua                 # Entry point only (~200 lines)
├── state.lua                # State management
├── tokens.json              # Shared design tokens
├── config.lua               # Project configuration
├── fetch.lua                # Data fetching
├── search.lua               # Search/filter logic
├── utils.lua                # Shared utilities
├── api/                     # API modules (unchanged)
│   ├── calendar.lua
│   ├── linear.lua
│   ├── notion.lua
│   ├── openai.lua
│   └── slack.lua
├── ui/
│   ├── tokens.lua           # Lua interface to tokens.json
│   ├── styles.lua           # CSS generation from tokens
│   ├── slack.lua            # Slack webview
│   ├── ai-chat.lua          # AI chat webview
│   └── canvas/              # Canvas rendering
│       ├── loader.lua       # Loading indicator
│       ├── main.lua         # Main dashboard
│       ├── linear-detail.lua
│       ├── notion-detail.lua
│       └── helpers.lua      # Shared canvas utilities
├── input/                   # Per-view input handlers
│   ├── init.lua             # Handler registry & dispatch
│   ├── main.lua             # Main view (j/k, numbers, etc.)
│   ├── search.lua           # Search mode
│   ├── llm.lua              # LLM search mode
│   ├── linear-detail.lua    # Linear detail view
│   ├── notion-detail.lua    # Notion detail view
│   └── vim.lua              # Shared vim-style helpers
└── webview/
    └── src/
        ├── tokens.ts        # Generated from tokens.json
        ├── lib/
        │   ├── hints.ts     # Vim-style hint system
        │   ├── fuzzy.ts     # Fuzzy matching
        │   └── keyboard.ts  # Keyboard utilities
        ├── app.tsx
        └── ai-chat.tsx
```

### Shared Design Tokens (tokens.json)

```json
{
  "colors": {
    "bg": { "primary": "#1a1a1a", "secondary": "#252525", "tertiary": "#2a2a2a" },
    "text": { "primary": "#ffffff", "secondary": "#8b8b8b", "muted": "#666666" },
    "border": { "subtle": "#333333", "medium": "#444444" },
    "accent": {
      "primary": "#5e6ad2",
      "slack": "#e01e5a",
      "ai": "#8b5cf6",
      "warning": "#f97316"
    }
  },
  "fonts": {
    "mono": "CaskaydiaCove Nerd Font Mono",
    "sizes": { "sm": 12, "base": 14, "lg": 16, "xl": 18 }
  },
  "spacing": { "xs": 4, "sm": 8, "md": 16, "lg": 24, "xl": 32 },
  "radii": { "sm": 4, "md": 6, "lg": 10 }
}
```

### Input Handler Pattern

```lua
-- input/main.lua
local M = {}

M.keybindings = {
  { key = "j", action = "next_item" },
  { key = "k", action = "prev_item" },
  { key = "return", action = "select" },
  { key = "/", action = "enter_search" },
  { key = "?", action = "enter_llm" },
}

function M.handle(event, state)
  local key = event:getCharacters()
  local mods = event:getFlags()

  -- Number keys select item
  if key:match("^[1-9]$") then
    return M.selectByNumber(tonumber(key), state)
  end

  -- ... clean per-action handlers
end

return M
```

## Behavior Preservation Strategy

1. **Test-first**: Before each extraction, document current behavior via manual testing
2. **Incremental**: Extract one module at a time, test, commit
3. **Same keybindings**: All hotkeys remain identical
4. **Visual parity**: Verify UI renders identically after each change

## Impact Assessment

| Area | Impact |
|------|--------|
| init.lua | Complete rewrite into entry point |
| ui/styles.lua | Major - reads tokens.json |
| ui/ai-chat.lua | Minor - use shared tokens |
| webview/src/*.tsx | Minor - import shared libs |
| Testing | Manual verification required |

## Risk Analysis

| Risk | Mitigation |
|------|------------|
| Breaking keyboard shortcuts | Test all keybindings before/after each phase |
| Visual regressions | Screenshot comparison |
| Module loading errors | Incremental extraction with tests |
| Circular dependencies | Careful dependency graph planning |

## Scope Definition

### In Scope

- Extract canvas rendering from init.lua to ui/canvas/
- Extract input handlers from init.lua to input/
- Create shared tokens.json
- Unify design tokens across Lua and TypeScript
- Extract shared TypeScript utilities
- Add JSDoc/LuaDoc comments throughout

### Out of Scope

- Adding new features
- Changing existing keybindings
- Major visual redesign (minor refinements OK)
- Changing API modules
- Refactoring webview Preact components

## Affected Packages

- `hammerspoon` (Attention.spoon only)

## Relevant Files

### Files to Refactor

- `init.lua` - Split into modules
- `ui/styles.lua` - Read from tokens.json
- `ui/ai-chat.lua` - Use shared tokens
- `webview/src/app.tsx` - Extract shared utilities
- `webview/src/ai-chat.tsx` - Extract shared utilities, remove duplicate models

### New Files

| File | Purpose |
|------|---------|
| `tokens.json` | Shared design tokens |
| `state.lua` | Centralized state management |
| `ui/tokens.lua` | Lua reader for tokens.json |
| `ui/canvas/loader.lua` | Loading indicator rendering |
| `ui/canvas/main.lua` | Main dashboard rendering |
| `ui/canvas/linear-detail.lua` | Linear issue detail |
| `ui/canvas/notion-detail.lua` | Notion task detail |
| `ui/canvas/helpers.lua` | Shared canvas utilities |
| `input/init.lua` | Input handler registry |
| `input/main.lua` | Main view handler |
| `input/search.lua` | Search mode handler |
| `input/llm.lua` | LLM mode handler |
| `input/linear-detail.lua` | Linear detail handler |
| `input/notion-detail.lua` | Notion detail handler |
| `input/vim.lua` | Shared vim helpers |
| `webview/src/tokens.ts` | TypeScript tokens |
| `webview/src/lib/hints.ts` | Vim hint system |
| `webview/src/lib/fuzzy.ts` | Fuzzy matching |

## Implementation Plan

### Phase 1: Foundation - Design Tokens

1. Create `tokens.json` with unified color palette
2. Create `ui/tokens.lua` to read JSON
3. Update `ui/styles.lua` to use tokens
4. Update `ui/ai-chat.lua` to use tokens
5. Verify visual parity

### Phase 2: Extract Canvas Rendering

1. Create `ui/canvas/helpers.lua` with shared utilities
2. Extract `showLoader()` to `ui/canvas/loader.lua`
3. Extract main `render()` to `ui/canvas/main.lua`
4. Extract `renderLinearDetail()` to `ui/canvas/linear-detail.lua`
5. Extract `renderNotionDetail()` to `ui/canvas/notion-detail.lua`
6. Slim down init.lua to call modules

### Phase 3: Extract Input Handlers

1. Create `input/vim.lua` with shared scroll/navigation
2. Create `input/init.lua` with handler registry
3. Extract main view handling to `input/main.lua`
4. Extract search mode to `input/search.lua`
5. Extract LLM mode to `input/llm.lua`
6. Extract detail view handlers
7. Replace monolithic `setupEventHandlers()` with dispatcher

### Phase 4: TypeScript Cleanup

1. Generate `webview/src/tokens.ts` from JSON
2. Extract `lib/fuzzy.ts`
3. Extract `lib/hints.ts` from app.tsx
4. Update app.tsx and ai-chat.tsx to use libs
5. Remove duplicate model list from ai-chat.tsx

### Phase 5: Documentation & Polish

1. Add LuaDoc comments to all public functions
2. Add JSDoc comments to TypeScript
3. Update CLAUDE.md with new structure
4. Final visual verification

## Step by Step Tasks

### Step 1: Create Design Tokens Foundation

- Create `tokens.json` with colors, fonts, spacing, radii
- Create `ui/tokens.lua` that reads and caches tokens.json
- Test token loading works

### Step 2: Update styles.lua

- Import tokens from `ui/tokens.lua`
- Replace hardcoded hex values with token references
- Verify Slack webview CSS renders correctly

### Step 3: Update ai-chat.lua CSS

- Import tokens
- Replace hardcoded colors with token references
- Standardize accent colors (use `accent.ai` for AI features)
- Verify AI chat renders correctly

### Step 4: Extract Canvas Helpers

- Create `ui/canvas/helpers.lua` with:
  - Text measurement utilities
  - Rectangle drawing helpers
  - Color conversion helpers
- Document each function

### Step 5: Extract Loader

- Create `ui/canvas/loader.lua`
- Move `showLoader()` logic
- Update init.lua to use module
- Test loading indicator

### Step 6: Extract Main Render

- Create `ui/canvas/main.lua`
- Move `render()` logic (~520 lines)
- Pass state object instead of `self`
- Update init.lua to call module
- Test main dashboard

### Step 7: Extract Linear Detail

- Create `ui/canvas/linear-detail.lua`
- Move `renderLinearDetail()` logic
- Test Linear issue detail view

### Step 8: Extract Notion Detail

- Create `ui/canvas/notion-detail.lua`
- Move `renderNotionDetail()` logic
- Test Notion task detail view

### Step 9: Create State Module

- Create `state.lua` with:
  - State initialization
  - State getters/setters
  - State reset functions
- Migrate state from init.lua `obj` table
- Update all modules to use state module

### Step 10: Create Vim Helpers

- Create `input/vim.lua` with:
  - Scroll functions (j/k, gg/G, Ctrl+d/u)
  - Number key selection
  - Common keybinding utilities
- Document vim-style patterns

### Step 11: Create Input Handler Registry

- Create `input/init.lua` with:
  - Handler registration
  - View-based dispatch
  - Fallback handling
- Define handler interface

### Step 12: Extract Main View Handler

- Create `input/main.lua`
- Move main view keybindings (j/k, numbers, enter, etc.)
- Test navigation in main view

### Step 13: Extract Search Handler

- Create `input/search.lua`
- Move search mode handling (typing, backspace, enter)
- Test search functionality

### Step 14: Extract LLM Handler

- Create `input/llm.lua`
- Move LLM mode handling (typing, model selection, enter)
- Test LLM search and model picker

### Step 15: Extract Detail Handlers

- Create `input/linear-detail.lua`
- Create `input/notion-detail.lua`
- Move respective handling logic
- Test detail view navigation

### Step 16: Replace Event Handler

- Update init.lua to use input handler registry
- Remove old `setupEventHandlers()` monolith
- Test all keyboard interactions

### Step 17: TypeScript Tokens

- Create build script to generate `tokens.ts` from `tokens.json`
- Add to package.json scripts
- Import tokens in TSX files

### Step 18: Extract TypeScript Utilities

- Create `webview/src/lib/fuzzy.ts`
- Create `webview/src/lib/hints.ts`
- Update app.tsx to import from libs
- Update ai-chat.tsx to import from libs

### Step 19: Remove Duplicates

- Remove duplicate `MODELS` from ai-chat.tsx (import from shared)
- Remove duplicate `fuzzyMatch` from ai-chat.tsx
- Verify both webviews work

### Step 20: Documentation

- Add LuaDoc to all Lua modules
- Add JSDoc to all TypeScript files
- Update CLAUDE.md with architecture diagram
- Document keyboard shortcuts

### Step 21: Final Validation

- Test all keyboard shortcuts in all views
- Verify visual appearance unchanged
- Run lint checks
- Reload Hammerspoon and verify functionality

## Testing Strategy

### Behavior Verification

Before each extraction:
1. Document current behavior
2. Screenshot UI states
3. List all keybindings for that view

After each extraction:
4. Verify identical behavior
5. Compare screenshots
6. Test all keybindings

### Config Validation

```bash
# After each phase
hs -c "hs.reload()"
# Check Hammerspoon console for errors

# Rebuild webviews after TypeScript changes
cd webview && pnpm run build

# Run lints
pnpm run check
```

### Regression Testing

- Main dashboard: Navigate items, select, filter
- Search mode: Type, clear, apply filter
- LLM mode: Type, select model, submit
- Slack detail: Scroll, vim hints, back
- AI chat: Send message, switch models
- Linear detail: Scroll, open in browser
- Notion detail: Scroll, open in browser

## Acceptance Criteria

- [ ] `init.lua` reduced to <300 lines
- [ ] All design tokens in single `tokens.json`
- [ ] No hardcoded colors in Lua or TypeScript
- [ ] Each input handler <100 lines
- [ ] Each canvas module <200 lines
- [ ] All public functions have documentation
- [ ] All existing keybindings work identically
- [ ] Visual appearance preserved (minor refinements OK)
- [ ] `pnpm run check` passes

## Validation Commands

```bash
# Lint Lua
pnpm run lint:lua

# Lint TypeScript/ESLint
pnpm run lint:webview

# TypeScript type check
pnpm run typecheck:webview

# Build webviews
cd hammerspoon/.config/hammerspoon/Spoons/Attention.spoon/webview
pnpm run build

# Reload Hammerspoon
hs -c "hs.reload()"

# All checks
pnpm run check
```

## Notes

### Future Improvements (Out of Scope)

- Unit tests for Lua modules (needs test framework)
- Storybook for webview components
- Animation system for transitions
- Plugin architecture for new integrations

### Design Decisions

1. **JSON for tokens**: Allows build-time generation for both Lua and TypeScript
2. **Per-view handlers**: Matches vim modal editing paradigm user is familiar with
3. **Canvas modules by view**: Natural split that mirrors user mental model
4. **State module**: Enables future persistence and debugging tools
