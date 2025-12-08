--- Attention.spoon/input/linear-detail.lua
--- Input handler for Linear issue detail view

---@class AttentionLinearDetailInputHandler
local M = {}

--- Handle keyboard input for Linear detail view
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

	-- Escape key - back to main
	if keyCode == vim.keyCodes.escape then
		state.scrollOffset = 0
		actions.render(state.cache)
		return true
	end

	-- Scroll down (j or Ctrl+d)
	if vim.isScrollDown(keyCode, mods) then
		local maxScroll = math.max(0, (state.contentHeight or 0) - (state.viewHeight or 400))
		local scrollAmount = mods.ctrl and 200 or 60
		state.scrollOffset = math.min(state.scrollOffset + scrollAmount, maxScroll)
		actions.renderLinearDetail(nil, false)
		return true
	end

	-- Scroll up (k or Ctrl+u)
	if vim.isScrollUp(keyCode, mods) then
		local scrollAmount = mods.ctrl and 200 or 60
		state.scrollOffset = math.max(0, state.scrollOffset - scrollAmount)
		actions.renderLinearDetail(nil, false)
		return true
	end

	-- Back button (b)
	if char == "b" then
		state.scrollOffset = 0
		actions.render(state.cache)
		return true
	end

	-- Block all other keys in detail view
	return true
end

return M
