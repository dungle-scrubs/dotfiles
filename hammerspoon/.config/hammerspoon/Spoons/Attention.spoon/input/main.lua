--- Attention.spoon/input/main.lua
--- Input handler for main dashboard view

---@class AttentionMainInputHandler
local M = {}

--- Handle keyboard input for main view
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

	-- Escape key - hide dashboard or clear filter
	if keyCode == vim.keyCodes.escape then
		if state.activeFilter ~= "" then
			state.activeFilter = ""
			actions.render(state.cache)
			return true
		end
		actions.hide()
		return true
	end

	-- "s" activates search mode
	if char == "s" and vim.noModifiers(mods) then
		state.searchMode = "search"
		state.searchQuery = ""
		actions.render(state.cache)
		return true
	end

	-- "S" (shift+s) activates LLM search mode
	if char == "S" and mods.shift and vim.noModifiers(mods, true) then
		state.searchMode = "llm"
		state.searchQuery = ""
		actions.render(state.cache)
		return true
	end

	-- Handle shortcut keys for items
	if char and state.keyMap[char] then
		local itemIdx = state.keyMap[char]
		local item = state.clickableItems[itemIdx]
		if item then
			M.handleItemSelect(item, state, actions)
		end
		return true
	end

	-- Let unhandled keys pass through
	return false
end

--- Handle item selection from keyboard shortcut
--- @param item table The clickable item
--- @param state table The Attention state
--- @param actions table Available actions
function M.handleItemSelect(item, state, actions)
	if item.type == "calendar" then
		if item.data and item.data.meetingUrl then
			hs.urlevent.openURL(item.data.meetingUrl)
			actions.hide()
		end
	elseif item.type == "linear" then
		actions.showLoader()
		actions.fetchLinearDetail(item.data.identifier, function(issue, err)
			if issue then
				actions.renderLinearDetail(issue)
			else
				actions.render(state.cache)
				hs.alert.show("Failed to load issue")
			end
		end)
	elseif item.type == "notion" then
		actions.showLoader()
		local apiKey = item.data._apiKey
		if apiKey then
			actions.fetchNotionDetail(item.data.id, apiKey, function(task, err)
				if task then
					actions.renderNotionDetail(task)
				else
					actions.render(state.cache)
					hs.alert.show("Failed to load Notion page")
				end
			end)
		else
			actions.render(state.cache)
			hs.alert.show("No API key for Notion page")
		end
	elseif item.type == "slack" then
		local channelId = item.data.channel and item.data.channel.id
		local isDM = item.data.channel and item.data.channel.is_im
		state.currentSlackChannel = channelId
		state.currentSlackToken = item._token

		if isDM and channelId then
			state.slackViewMode = "history"
			actions.renderSlackDetail(item.data, {}, false, true)
			actions.fetchSlackHistory(channelId, { token = item._token }, function(messages, err)
				if err or not messages then
					actions.hide()
					hs.alert.show("Failed to load Slack history")
					return
				end
				actions.updateSlackMessages(messages)
			end)
		else
			state.slackViewMode = "thread"
			local threadTs = item.data.thread_ts or item.data.ts
			if channelId and threadTs then
				actions.renderSlackDetail(item.data, {}, false, true)
				actions.fetchSlackThread(channelId, threadTs, { token = item._token }, function(thread, err)
					if err or not thread then
						actions.hide()
						hs.alert.show("Failed to load Slack thread")
						return
					end
					actions.updateSlackMessages(thread)
				end)
			else
				actions.hide()
				hs.alert.show("Missing channel or thread info")
			end
		end
	elseif item.type == "llm-model" then
		state.currentLLMModel = item.data.id
		state.showModelSelector = false
		state.modelFilter = ""
		actions.render(state.cache)
	end
end

return M
