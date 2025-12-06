--- Attention.spoon
--- A unified dashboard for Linear issues and Slack messages
---
--- This Spoon provides a modal overlay that displays:
--- - Linear issues assigned to you (not completed/canceled)
--- - Slack DMs and @mentions
---
--- Features:
--- - Keyboard-driven navigation (a-z to select items)
--- - Detail views for Linear issues (with comments) and Slack threads
--- - Infinite scroll for loading older messages
--- - Clickable links and @mentions
---
--- @module Attention
--- @author Kevin
--- @license MIT

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "Attention"
obj.version = "1.0.0"
obj.author = "Kevin"
obj.license = "MIT"

-- Load submodules
local utils = require("Spoons.Attention.spoon.utils")
local stateModule = require("Spoons.Attention.spoon.state")
local linearApi = require("Spoons.Attention.spoon.api.linear")
local slackApi = require("Spoons.Attention.spoon.api.slack")
local styles = require("Spoons.Attention.spoon.ui.styles")

-- Internal state
local state = stateModule.init()

--- Bind a hotkey to toggle the Attention dashboard
--- @param mods table Modifier keys (e.g., {"ctrl", "shift"})
--- @param key string The key to bind
--- @return Attention self
--- @example
---   spoon.Attention:bindHotkey({"ctrl", "shift"}, "a")
function obj:bindHotkey(mods, key)
	hs.hotkey.bind(mods, key, function()
		self:toggle()
	end)
	return self
end

--- Toggle the dashboard visibility
--- Shows the dashboard if hidden, hides if visible
--- @return Attention self
function obj:toggle()
	if state.visible then
		self:hide()
	else
		self:show()
	end
	return self
end

--- Show the Attention dashboard
--- Fetches fresh data if cache is stale (different day)
--- @return Attention self
function obj:show()
	-- Will be implemented by migrating from init.lua
	-- For now, this is a placeholder
	hs.alert.show("Attention.spoon loaded - migration in progress")
	return self
end

--- Hide the Attention dashboard
--- Cleans up UI elements and event watchers
--- @return Attention self
function obj:hide()
	-- Stop timers
	if state.loadingTimer then
		state.loadingTimer:stop()
		state.loadingTimer = nil
	end

	-- Stop event watchers
	if state.webviewKeyWatcher then
		state.webviewKeyWatcher:stop()
		state.webviewKeyWatcher = nil
	end
	if state.escapeWatcher then
		state.escapeWatcher:stop()
		state.escapeWatcher = nil
	end
	if state.clickWatcher then
		state.clickWatcher:stop()
		state.clickWatcher = nil
	end
	if state.hoverWatcher then
		state.hoverWatcher:stop()
		state.hoverWatcher = nil
	end

	-- Clean up UI
	if state.webview then
		state.webview:delete()
		state.webview = nil
	end
	if state.canvas then
		state.canvas:hide()
		state.canvas:delete()
		state.canvas = nil
	end

	-- Reset state
	state.visible = false
	stateModule.resetForClose(state)

	return self
end

--- Fetch all data (Linear issues and Slack messages)
--- @param callback function Callback function(data) with {linear, slack}
--- @return Attention self
function obj:fetchAll(callback)
	local results = { linear = nil, slack = nil }
	local pending = 2

	local function checkComplete()
		pending = pending - 1
		if pending == 0 then
			state.cache = results
			state.lastFetchDate = os.date("%Y-%m-%d")
			callback(results)
		end
	end

	linearApi.fetchIssues(function(issues, err)
		results.linear = issues or {}
		checkComplete()
	end)

	slackApi.fetchMentions(function(messages, err)
		results.slack = messages or {}
		checkComplete()
	end)

	return self
end

--- Check if cached data needs refresh
--- @return boolean needsFetch True if data should be refetched
function obj:needsFetch()
	return utils.needsFetch(state.lastFetchDate)
end

--- Get the current state (for debugging)
--- @return table state The current state table
function obj:getState()
	return state
end

--- Get the styles module (for UI components)
--- @return table styles The styles module
function obj:getStyles()
	return styles
end

--- Get the API modules (for custom integrations)
--- @return table apis Table with {linear, slack} API modules
function obj:getApis()
	return {
		linear = linearApi,
		slack = slackApi,
	}
end

return obj
