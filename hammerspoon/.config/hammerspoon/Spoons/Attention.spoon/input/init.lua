--- Attention.spoon/input/init.lua
--- Input handler registry and dispatcher
--- Routes keyboard events to view-specific handlers

-- Use global path set by main init.lua
local spoonPath = _G.AttentionSpoonPath
local vim = dofile(spoonPath .. "/input/vim.lua")

---@class AttentionInputRegistry
local M = {}

-- Handler modules (loaded lazily)
local handlers = {}

-- Load a handler module
local function loadHandler(name)
	if not handlers[name] then
		local ok, handler = pcall(dofile, spoonPath .. "/input/" .. name .. ".lua")
		if ok and handler then
			handlers[name] = handler
		else
			print("[Input] Failed to load handler: " .. name)
			handlers[name] = { handle = function() return false end }
		end
	end
	return handlers[name]
end

--- Get handler for current view
--- @param state table The Attention state
--- @return table handler The handler module
function M.getHandler(state)
	local view = state.currentView or "main"
	local searchMode = state.searchMode

	-- Search modes take precedence
	if searchMode == "search" then
		return loadHandler("search")
	elseif searchMode == "llm" then
		return loadHandler("llm")
	end

	-- View-specific handlers
	if view == "main" then
		return loadHandler("main")
	elseif view == "linear-detail" then
		return loadHandler("linear-detail")
	elseif view == "notion-detail" then
		return loadHandler("notion-detail")
	elseif view == "slack-detail" then
		-- Slack uses webview, minimal canvas handler
		return loadHandler("detail")
	end

	return loadHandler("main")
end

--- Dispatch keyboard event to appropriate handler
--- @param event hs.eventtap.event The key event
--- @param state table The Attention state
--- @param actions table Available actions { hide, render, showLoader, etc. }
--- @return boolean handled Whether the event was consumed
function M.dispatch(event, state, actions)
	local keyCode = event:getKeyCode()
	local char = event:getCharacters()
	local mods = event:getFlags()

	-- System hotkeys (meh, hyper) always pass through
	if vim.isSystemHotkey(mods) then
		return false
	end

	-- Cmd+Escape - emergency force close (always works)
	if keyCode == vim.keyCodes.escape and mods.cmd then
		actions.forceCleanup()
		return true
	end

	-- Get the appropriate handler for current state
	local handler = M.getHandler(state)

	-- Delegate to handler
	return handler.handle(event, state, actions, {
		keyCode = keyCode,
		char = char,
		mods = mods,
		vim = vim,
	})
end

--- Create the main keyboard event handler
--- @param state table The Attention state
--- @param actions table Available actions
--- @return function handler The event handler function
function M.createEventHandler(state, actions)
	return function(event)
		return M.dispatch(event, state, actions)
	end
end

-- Export vim helpers for use by sub-handlers
M.vim = vim

return M
