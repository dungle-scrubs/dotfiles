# Attention Spoon

A Hammerspoon Spoon that provides a quick dashboard overlay for Slack messages, Notion tasks, Linear issues, and AI chat.

## Architecture

```
Attention.spoon/
├── init.lua              # Main entry point, state management, lifecycle
├── fetch.lua             # Data fetching orchestration
├── utils.lua             # Shared utilities (HTTP, date formatting)
├── config.lua            # Multi-project configuration
├── tokens.json           # Design tokens (colors, fonts, spacing) - SINGLE SOURCE OF TRUTH
├── api/
│   ├── notion.lua        # Notion API integration
│   ├── slack.lua         # Slack API integration
│   └── openai.lua        # OpenRouter API for AI chat
├── ui/
│   ├── tokens.lua        # Lua token reader (reads tokens.json)
│   ├── styles.lua        # Shared styles, CSS generation
│   ├── slack.lua         # Slack webview UI controller
│   ├── ai-chat.lua       # AI chat webview UI controller
│   └── canvas/           # Canvas rendering modules
│       ├── helpers.lua   # Shared canvas utilities (bg, text, rect, etc.)
│       ├── loader.lua    # Loading indicator animation
│       ├── main.lua      # Main dashboard canvas
│       ├── linear-detail.lua  # Linear issue detail view
│       └── notion-detail.lua  # Notion task detail view
├── input/                # Keyboard input handlers
│   ├── vim.lua           # Shared vim-style navigation helpers
│   ├── init.lua          # Handler registry and dispatcher
│   ├── main.lua          # Main view handler
│   ├── search.lua        # Search mode handler
│   ├── llm.lua           # LLM mode handler
│   ├── detail.lua        # Generic detail view handler
│   ├── linear-detail.lua # Linear detail handler
│   └── notion-detail.lua # Notion detail handler
└── webview/              # Preact frontend (see below)
```

## Design Tokens

Design tokens provide a single source of truth for styling across both Lua (canvas) and TypeScript (webview):

- `tokens.json` - Master token definitions
- `ui/tokens.lua` - Lua reader with caching
- `webview/src/tokens.ts` - TypeScript exports

Usage in Lua:
```lua
local tokens = require("ui.tokens")
tokens.color("bg.primary")      -- "#1a1a1a"
tokens.font()                   -- "CaskaydiaCove Nerd Font Mono"
tokens.fontSize("base")         -- 14
tokens.spacing("md")            -- 16
```

Usage in TypeScript:
```typescript
import { colors, fonts, spacing } from './tokens';
colors.bg.primary  // "#1a1a1a"
fonts.mono         // "CaskaydiaCove Nerd Font Mono"
```

## Webview (Preact Frontend)

The `webview/` directory contains Preact-based UIs rendered in `hs.webview`:

- `src/app.tsx` - Slack messages dashboard
- `src/ai-chat.tsx` - AI chat interface
- `src/tokens.ts` - Design tokens (generated from tokens.json)
- `src/lib/fuzzy.ts` - Fuzzy matching utilities
- `src/lib/hints.ts` - Vim-style hint system
- `src/lib/models.ts` - LLM model definitions

### Commands

```bash
cd hammerspoon/.config/hammerspoon/Spoons/Attention.spoon/webview

# Build both bundles
pnpm run build

# Watch mode (development)
pnpm run watch          # Slack app
pnpm run watch:ai-chat  # AI chat

# Linting and type checking
pnpm run lint           # ESLint with --max-warnings 0
pnpm run typecheck      # TypeScript (separate configs per file)
```

### TypeScript Configuration

Each TSX file has its own tsconfig to avoid global declaration conflicts:

- `tsconfig.app.json` - for `src/app.tsx` (SlackAppState)
- `tsconfig.ai-chat.json` - for `src/ai-chat.tsx` (AiChatAppState)

Both extend `tsconfig.json` for shared compiler options.

### Build Output

Bundles are output to `webview/dist/`:
- `bundle.js` - Slack messages UI
- `ai-chat.js` - AI chat UI

## Input Handler System

Keyboard input is handled through a modular dispatcher system:

1. `input/init.lua` - Registry that routes events to view-specific handlers
2. View handlers (`main.lua`, `search.lua`, etc.) - Focused per-view logic
3. `input/vim.lua` - Shared utilities (key codes, scroll detection, fuzzy match)

Flow: `init.lua eventtap → input/init.lua dispatch → view handler`

## Lua-Webview Communication

Communication between Lua and webview uses `hs.webview.usercontent`:

```lua
-- Lua: Send data to webview
webview:evaluateJavaScript("window.receiveData(" .. hs.json.encode(data) .. ")")

-- Lua: Receive messages from webview
usercontent:setCallback(function(msg)
  if msg.body.action == "send" then
    -- handle message
  end
end)
```

```typescript
// TypeScript: Send to Lua
window.webkit.messageHandlers.hammerspoon.postMessage({ action: 'send', message: text });

// TypeScript: Receive from Lua (exposed on window)
window.receiveResponse = (content: string, isError: boolean) => { ... };
```

## Keyboard Handling

The Spoon uses `hs.eventtap` to capture keyboard input when visible:

- `Escape` - Close overlay (or Cmd+Escape as emergency exit)
- `j/k` - Scroll down/up
- `Ctrl+d/u` - Page down/up
- `h/l` - Switch between items/columns
- `s` - Enter search mode
- `S` - Enter LLM mode
- `f` - Hint mode for thread links (Slack webview)
- `Shift+Space` - Open model selector (AI chat)

If keyboard gets stuck, call `spoon.Attention:forceCleanup()` from Hammerspoon console.

## Reloading

After changes to Lua files:
```bash
hs -c "hs.reload()"
```

After changes to webview TSX files:
```bash
cd webview && pnpm run build
hs -c "hs.reload()"
```
