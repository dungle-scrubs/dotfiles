--- Attention.spoon/input/search.lua
--- Input handler for search mode (fuzzy filter)

---@class AttentionSearchInputHandler
local M = {}

--- Handle keyboard input for search mode
--- @param event hs.eventtap.event The key event
--- @param state table The Attention state
--- @param actions table Available actions
--- @param ctx table Context { keyCode, char, mods, vim }
--- @return boolean handled Whether the event was consumed
function M.handle(event, state, actions, ctx)
	local keyCode = ctx.keyCode
	local char = ctx.char
	local mods = ctx.mods
	local vim = ctx.vim

	-- Escape key - exit search mode
	if keyCode == vim.keyCodes.escape then
		state.searchMode = nil
		state.searchQuery = ""
		actions.render(state.cache)
		return true
	end

	-- Enter key - apply search filter
	if keyCode == vim.keyCodes.enter then
		if state.searchQuery ~= "" then
			state.activeFilter = state.searchQuery
		end
		state.searchMode = nil
		actions.render(state.cache)
		return true
	end

	-- Backspace key - remove last character
	if keyCode == vim.keyCodes.backspace then
		if state.searchQuery ~= "" then
			state.searchQuery = state.searchQuery:sub(1, -2)
			actions.render(state.cache)
		end
		return true
	end

	-- Handle typing (regular characters, no modifiers except shift)
	if char and #char == 1 and not mods.cmd and not mods.ctrl and not mods.alt then
		if vim.isPrintable(char) then
			state.searchQuery = state.searchQuery .. char
			actions.render(state.cache)
			return true
		end
	end

	-- Block all other keys in search mode
	return true
end

return M
