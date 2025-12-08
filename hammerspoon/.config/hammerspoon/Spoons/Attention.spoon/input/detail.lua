--- Attention.spoon/input/detail.lua
--- Input handler for detail views (Linear, Notion, Slack fallback)

---@class AttentionDetailInputHandler
local M = {}

--- Handle keyboard input for detail views
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

	-- Handle specific shortcuts from keyMap
	if char and state.keyMap[char] then
		local itemIdx = state.keyMap[char]
		local item = state.clickableItems[itemIdx]
		if item then
			if item.type == "back" then
				state.scrollOffset = 0
				actions.render(state.cache)
			elseif item.type == "open-notion" then
				if item.data and item.data.url then
					hs.urlevent.openURL(item.data.url)
					actions.hide()
				end
			end
		end
		return true
	end

	-- Block all other keys in detail views
	return true
end

return M
