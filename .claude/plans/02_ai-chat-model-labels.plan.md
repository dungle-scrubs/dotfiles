# Feature: AI Chat Model Labels

## Feature Description

Display the model identifier (provider/model format) above every assistant message in the Attention AI chat interface. This allows users to see which model generated each response, especially useful when switching models mid-conversation.

## User Story

As a user chatting with AI
I want to see which model generated each response
So that I can track model performance and know which model I'm interacting with throughout the conversation

## Problem Statement

Currently, the AI chat only displays the model name for assistant messages when using "openrouter/auto" routing mode. When manually selecting models, there's no indication of which model generated each response. If a user switches models mid-conversation, there's no way to tell which model responded to which query.

## Solution Statement

Modify the message data structure to always include the model used for each assistant response. Update the Lua backend to pass the model (selected or actual) for every response. Update the frontend to display the model ID above every assistant message in the "provider/model" format.

## Affected Packages

- `hammerspoon` - Attention Spoon UI and API modules

## Integration Points

- **Lua → Webview**: `window.receiveResponse()` already accepts `actualModel` parameter but needs to always receive it
- **OpenRouter API**: Already returns the actual model used in responses
- **Message State**: TypeScript Message interface needs to always populate `actualModel`

## Relevant Files

Use these files to implement the feature:

### Backend (Lua)
- `hammerspoon/.config/hammerspoon/Spoons/Attention.spoon/ui/ai-chat.lua` - Controls the webview and sends responses; needs to always pass model info
- `hammerspoon/.config/hammerspoon/Spoons/Attention.spoon/api/openai.lua` - API layer that returns the actual model used

### Frontend (TypeScript/Preact)
- `hammerspoon/.config/hammerspoon/Spoons/Attention.spoon/webview/src/ai-chat.tsx` - Message component and state management; needs to display model on all assistant messages
- `hammerspoon/.config/hammerspoon/Spoons/Attention.spoon/webview/src/lib/models.ts` - Model definitions (reference only)

### Styles
- `hammerspoon/.config/hammerspoon/Spoons/Attention.spoon/ui/styles.lua` - CSS for `.message-model` class (already exists, may need minor tweaks)

## Implementation Plan

### Phase 1: Foundation

Update the data flow to always include model information:
1. Modify `ai-chat.lua` to always pass the model (selected or actual) when calling `receiveResponse`
2. Ensure the model is passed for both successful responses and when using non-auto routing

### Phase 2: Core Implementation

Update the frontend to always display model labels:
1. Modify `MessageComponent` in `ai-chat.tsx` to always show the model (not just when `actualModel` exists)
2. Display the full model ID in "provider/model" format

### Phase 3: Integration & Testing

1. Build the webview bundle
2. Reload Hammerspoon
3. Test with multiple model switches mid-conversation

## Step by Step Tasks

### Step 1: Update Lua backend to always pass model

In `ui/ai-chat.lua`, modify the `sendMessage` function to always pass the model used:

- Change line ~151 where `modelToShow` is conditionally set
- Always set `modelToShow` to either `actualModel` (from API) or `M.currentModel` (selected)
- Remove the conditional that only shows model for "openrouter/auto"

### Step 2: Update frontend Message interface and display

In `webview/src/ai-chat.tsx`:

- The `Message` interface already has `actualModel?: string` - this is fine
- Modify `window.receiveResponse` to always populate `actualModel` from the parameter
- Modify `MessageComponent` to always render `.message-model` div when role is "assistant"
- Display the full model ID (no transformation, show raw "provider/model" format)

### Step 3: Build and test

- Run `pnpm run build` in the webview directory
- Reload Hammerspoon with `hs -c "hs.reload()"`
- Open AI chat, send messages with different models
- Verify each assistant message shows the model ID above it

## Testing Strategy

### Manual Testing

1. Open AI chat with default model (gpt-4o-mini)
2. Send a message, verify "openai/gpt-4o-mini" appears above the response
3. Switch to a different model (e.g., Claude Sonnet 4)
4. Send another message, verify "anthropic/claude-sonnet-4" appears above the new response
5. Verify previous response still shows "openai/gpt-4o-mini"
6. Test with "openrouter/auto" - should show the actual model that was routed to

### Config Validation

- TypeScript: `pnpm run typecheck` in webview directory
- Lint: `pnpm run lint` in webview directory

### Edge Cases

1. **Error responses**: Model label should NOT appear for error messages (role="error")
2. **Loading state**: Model label should NOT appear during loading
3. **User messages**: Model label should NOT appear for user messages
4. **Long model IDs**: Verify display handles long model IDs gracefully

## Acceptance Criteria

- [ ] Every assistant message displays the model ID above the message content
- [ ] Model is shown in "provider/model" format (e.g., "anthropic/claude-sonnet-4")
- [ ] When switching models mid-chat, each response shows the correct model that generated it
- [ ] Error messages and user messages do NOT show model labels
- [ ] "openrouter/auto" shows the actual model that was routed to
- [ ] TypeScript compiles without errors
- [ ] Lint passes without warnings

## Validation Commands

### Webview Build

```bash
cd hammerspoon/.config/hammerspoon/Spoons/Attention.spoon/webview
pnpm run typecheck
pnpm run lint
pnpm run build
```

### Hammerspoon

```bash
hs -c "hs.reload()"
```

## Notes

- The current `.message-model` CSS class already exists and is styled appropriately (10px italic muted text)
- The `actualModel` field naming is kept for backward compatibility, even though it will now always be populated
- The OpenRouter API always returns the actual model used in responses, so this is reliable data
