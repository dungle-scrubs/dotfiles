--- Attention.spoon/input/llm.lua
--- Input handler for LLM search mode (AI chat)

---@class AttentionLLMInputHandler
local M = {}

--- Handle keyboard input for LLM mode
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

	-- Escape key - exit model selector or LLM mode
	if keyCode == vim.keyCodes.escape then
		if state.showModelSelector then
			state.showModelSelector = false
			state.modelFilter = ""
			actions.render(state.cache)
			return true
		end
		state.searchMode = nil
		state.searchQuery = ""
		state.showModelSelector = false
		state.modelFilter = ""
		actions.render(state.cache)
		return true
	end

	-- Model selector mode has different key handling
	if state.showModelSelector then
		return M.handleModelSelector(event, state, actions, ctx)
	end

	-- Shift+Space toggles model selector
	if keyCode == vim.keyCodes.space and mods.shift and not mods.cmd and not mods.ctrl and not mods.alt then
		state.showModelSelector = true
		state.modelFilter = ""
		actions.render(state.cache)
		return true
	end

	-- Enter key - open AI chat with query
	if keyCode == vim.keyCodes.enter then
		local query = state.searchQuery
		local model = state.currentLLMModel
		state.searchMode = nil
		state.searchQuery = ""
		state.showModelSelector = false
		state.modelFilter = ""
		actions.hide()
		actions.openAIChat(query, model)
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

	-- Handle typing
	if char and #char == 1 and not mods.cmd and not mods.ctrl and not mods.alt then
		if vim.isPrintable(char) then
			state.searchQuery = state.searchQuery .. char
			actions.render(state.cache)
			return true
		end
	end

	-- Block all other keys in LLM mode
	return true
end

--- Handle keyboard input when model selector is open
--- @param event hs.eventtap.event The key event
--- @param state table The Attention state
--- @param actions table Available actions
--- @param ctx table Context { keyCode, char, mods, vim }
--- @return boolean handled
function M.handleModelSelector(event, state, actions, ctx)
	local keyCode = ctx.keyCode
	local char = ctx.char
	local mods = ctx.mods
	local vim = ctx.vim

	-- Enter key - select first filtered model
	if keyCode == vim.keyCodes.enter then
		local filtered = actions.filterModels(state.modelFilter)
		if #filtered > 0 then
			state.currentLLMModel = filtered[1].id
			state.showModelSelector = false
			state.modelFilter = ""
			actions.render(state.cache)
		end
		return true
	end

	-- Backspace key - remove last character from filter
	if keyCode == vim.keyCodes.backspace then
		if state.modelFilter ~= "" then
			state.modelFilter = state.modelFilter:sub(1, -2)
			actions.render(state.cache)
		end
		return true
	end

	-- Letter keys for quick model selection (only when filter is empty)
	if state.modelFilter == "" and char and char:match("^[a-j]$") then
		local models = actions.getModels()
		for _, model in ipairs(models) do
			if model.key == char then
				state.currentLLMModel = model.id
				state.showModelSelector = false
				state.modelFilter = ""
				actions.render(state.cache)
				return true
			end
		end
	end

	-- Handle typing for model filter
	if char and #char == 1 and not mods.cmd and not mods.ctrl and not mods.alt then
		if vim.isPrintable(char) then
			state.modelFilter = state.modelFilter .. char
			actions.render(state.cache)
			return true
		end
	end

	-- Block all other keys in model selector
	return true
end

return M
