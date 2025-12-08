--- Attention.spoon/input/notion-detail.lua
--- Input handler for Notion task detail view

---@class AttentionNotionDetailInputHandler
local M = {}

--- Handle keyboard input for Notion detail view
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
		actions.renderNotionDetail(nil, false)
		return true
	end

	-- Scroll up (k or Ctrl+u)
	if vim.isScrollUp(keyCode, mods) then
		local scrollAmount = mods.ctrl and 200 or 60
		state.scrollOffset = math.max(0, state.scrollOffset - scrollAmount)
		actions.renderNotionDetail(nil, false)
		return true
	end

	-- Back button (b)
	if char == "b" then
		state.scrollOffset = 0
		actions.render(state.cache)
		return true
	end

	-- Open in Notion (o)
	if char == "o" then
		local task = state.currentNotionTask
		if task and task.url then
			hs.urlevent.openURL(task.url)
			actions.hide()
		end
		return true
	end

	-- Block all other keys in detail view
	return true
end

return M
