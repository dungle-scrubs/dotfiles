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

---@class Attention
local obj = {}
obj.__index = obj

-- Metadata
obj.name = "Attention"
obj.version = "1.0.0"
obj.author = "Kevin"
obj.license = "MIT"

-- Spoon path for loading submodules
local spoonPath = hs.spoons.scriptPath()

-- Set global for submodules to use
_G.AttentionSpoonPath = spoonPath

-- Helper to load modules relative to spoon
local function loadModule(path)
	return dofile(spoonPath .. "/" .. path)
end

-- Load submodules
local utils = loadModule("utils.lua")
local stateModule = loadModule("state.lua")
local styles = loadModule("ui/styles.lua")
local linearApi = loadModule("api/linear.lua")
local slackApi = loadModule("api/slack.lua")
local mainUI = loadModule("ui/main.lua")
local linearUI = loadModule("ui/linear.lua")
local slackUI = loadModule("ui/slack.lua")

-- Internal state
local state = stateModule.init()

-- Forward declarations for callbacks
local setupEventHandlers, showLoader, renderMain

--- Show a loading indicator
local function showLoader()
	if state.loadingTimer then
		state.loadingTimer:stop()
		state.loadingTimer = nil
	end

	local f = styles.fonts
	local c = styles.colors
	local screen = hs.screen.mainScreen()
	local screenFrame = screen:frame()

	local boxWidth = state.lastCanvasSize and state.lastCanvasSize.w or 300
	local boxHeight = state.lastCanvasSize and state.lastCanvasSize.h or 100
	local boxX = screenFrame.x + (screenFrame.w - boxWidth) / 2
	local boxY = screenFrame.y + (screenFrame.h - boxHeight) / 2

	if state.canvas then
		state.canvas:delete()
	end

	state.canvas = hs.canvas.new({ x = boxX, y = boxY, w = boxWidth, h = boxHeight })
	state.canvasFrame = { x = boxX, y = boxY, w = boxWidth, h = boxHeight }
	local canvas = state.canvas

	canvas[1] = {
		type = "rectangle",
		action = "fill",
		fillColor = { hex = c.bgPrimary, alpha = 0.95 },
		roundedRectRadii = { xRadius = 10, yRadius = 10 },
	}
	canvas[2] = {
		type = "rectangle",
		action = "stroke",
		strokeColor = { hex = c.accentLinear, alpha = 0.9 },
		strokeWidth = 2,
		roundedRectRadii = { xRadius = 10, yRadius = 10 },
	}
	canvas[3] = {
		type = "text",
		text = "Loading.  ",
		textFont = f.mono,
		textSize = f.size,
		textColor = { hex = c.accentLinear, alpha = 1 },
		textAlignment = "center",
		frame = { x = 0, y = (boxHeight - f.size) / 2, w = boxWidth, h = f.size + 4 },
	}

	canvas:level(hs.canvas.windowLevels.overlay)
	canvas:clickActivating(false)
	canvas:show()
	state.visible = true

	-- Animate loading dots
	state.loadingDots = 0
	state.loadingTimer = hs.timer.doEvery(0.3, function()
		state.loadingDots = (state.loadingDots % 3) + 1
		local dots = string.rep(".", state.loadingDots) .. string.rep(" ", 3 - state.loadingDots)
		if state.canvas and state.canvas[3] then
			state.canvas[3].text = "Loading" .. dots
		end
	end)
end

--- Render the main dashboard
local function renderMain()
	if state.loadingTimer then
		state.loadingTimer:stop()
		state.loadingTimer = nil
	end
	mainUI.render(state)
	setupEventHandlers()
end

--- Setup event handlers for keyboard and mouse
function setupEventHandlers()
	if state.escapeWatcher then
		state.escapeWatcher:stop()
	end
	if state.clickWatcher then
		state.clickWatcher:stop()
	end
	if state.hoverWatcher then
		state.hoverWatcher:stop()
	end

	state.escapeWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
		local keyCode = event:getKeyCode()
		local char = event:getCharacters()
		local mods = event:getFlags()

		-- Escape - go back or close
		if keyCode == 53 then
			if state.currentView == "linear-detail" or state.currentView == "slack-detail" then
				state.scrollOffset = 0
				renderMain()
			else
				obj:hide()
			end
			return true
		end

		-- Scroll in detail views
		if state.currentView == "linear-detail" then
			local scrollDown = (mods.ctrl and keyCode == 2) or (keyCode == 38)
			local scrollUp = (mods.ctrl and keyCode == 32) or (keyCode == 40)

			if scrollDown then
				local maxScroll = math.max(0, (state.contentHeight or 0) - (state.viewHeight or 400))
				state.scrollOffset = math.min(state.scrollOffset + 100, maxScroll)
				linearUI.renderDetail(state, nil, false)
				setupEventHandlers()
				return true
			end

			if scrollUp then
				state.scrollOffset = math.max(0, state.scrollOffset - 100)
				linearUI.renderDetail(state, nil, false)
				setupEventHandlers()
				return true
			end
		end

		-- Check if it's a shortcut key
		if char and state.keyMap[char] then
			local itemIdx = state.keyMap[char]
			local item = state.clickableItems[itemIdx]
			if item then
				if item.type == "linear" then
					showLoader()
					linearApi.fetchDetail(item.data.identifier, function(issue, err)
						if issue then
							linearUI.renderDetail(state, issue)
							setupEventHandlers()
						else
							renderMain()
							hs.alert.show("Failed to load issue")
						end
					end)
				elseif item.type == "slack" then
					showLoader()
					local channelId = item.data.channel and item.data.channel.id
					local isDM = item.data.channel and item.data.channel.is_im
					state.currentSlackChannel = channelId

					local callbacks = {
						onBack = function()
							slackUI.closeWebview(state)
							state.scrollOffset = 0
							renderMain()
						end,
						onClose = function()
							obj:hide()
						end,
						onOpenSlack = function(permalink)
							if permalink then
								hs.urlevent.openURL(permalink)
							end
							obj:hide()
						end,
						onChannelUp = function()
							slackUI.closeWebview(state)
							showLoader()
							state.slackViewMode = "history"
							slackApi.fetchHistory(state.currentSlackChannel, function(messages, err)
								slackUI.renderWebview(state, state.currentSlackMsg, messages, false, callbacks)
							end)
						end,
						onThreadClick = function(threadTs)
							slackUI.closeWebview(state)
							showLoader()
							state.slackViewMode = "thread"
							state.slackThreadTs = threadTs
							slackApi.fetchThread(state.currentSlackChannel, threadTs, function(threadMsgs, err)
								slackUI.renderWebview(state, state.currentSlackMsg, threadMsgs, false, callbacks)
							end)
						end,
						onLoadMore = function()
							if state.slackOldestTs and state.currentSlackChannel then
								if state.slackViewMode == "history" then
									slackApi.fetchHistory(state.currentSlackChannel, function(olderMessages, err)
										if olderMessages and #olderMessages > 0 then
											local combined = {}
											for _, m in ipairs(olderMessages) do
												table.insert(combined, m)
											end
											for _, m in ipairs(state.currentSlackThread or {}) do
												table.insert(combined, m)
											end
											state.currentSlackThread = combined
											if combined[1] and combined[1].ts then
												state.slackOldestTs = combined[1].ts
											end
											slackUI.renderWebview(state, nil, nil, true, callbacks)
										else
											slackUI.resetLoadingFlag(state)
										end
									end, state.slackOldestTs)
								else
									slackApi.fetchThread(state.currentSlackChannel, state.slackThreadTs, function(olderMessages, err)
										if olderMessages and #olderMessages > 0 then
											local combined = {}
											local existingFirst = state.currentSlackThread and state.currentSlackThread[1]
											for _, m in ipairs(olderMessages) do
												if not (existingFirst and m.ts == existingFirst.ts) then
													table.insert(combined, m)
												end
											end
											for _, m in ipairs(state.currentSlackThread or {}) do
												table.insert(combined, m)
											end
											state.currentSlackThread = combined
											if combined[1] and combined[1].ts then
												state.slackOldestTs = combined[1].ts
											end
											slackUI.renderWebview(state, nil, nil, true, callbacks)
										else
											slackUI.resetLoadingFlag(state)
										end
									end, state.slackOldestTs)
								end
							else
								slackUI.resetLoadingFlag(state)
							end
						end,
					}

					if isDM and channelId then
						state.slackViewMode = "history"
						slackApi.fetchHistory(channelId, function(messages, err)
							slackUI.renderWebview(state, item.data, messages, false, callbacks)
						end)
					else
						state.slackViewMode = "thread"
						local threadTs = item.data.thread_ts or item.data.ts
						if channelId and threadTs then
							slackApi.fetchThread(channelId, threadTs, function(thread, err)
								slackUI.renderWebview(state, item.data, thread, false, callbacks)
							end)
						else
							slackUI.renderWebview(state, item.data, {}, false, callbacks)
						end
					end
				elseif item.type == "back" then
					state.scrollOffset = 0
					renderMain()
				end
			end
			return true
		end

		return true
	end)
	state.escapeWatcher:start()

	-- Hover tracking
	state.hoverWatcher = hs.eventtap.new({ hs.eventtap.event.types.mouseMoved }, function(event)
		local pos = hs.mouse.absolutePosition()
		local f = state.canvasFrame
		if not f then
			return false
		end

		if pos.x >= f.x and pos.x <= f.x + f.w and pos.y >= f.y and pos.y <= f.y + f.h then
			local relY = pos.y - f.y
			local relX = pos.x - f.x

			local foundIndex = nil
			for i, item in ipairs(state.clickableItems) do
				local itemX = item.x or 0
				local itemW = item.w or f.w
				if relY >= item.y and relY <= item.y + item.h then
					if item.type == "back" then
						if relX >= itemX and relX <= itemX + itemW then
							foundIndex = i
							break
						end
					else
						foundIndex = i
						break
					end
				end
			end

			if state.currentView == "main" then
				mainUI.updateHover(state, foundIndex)
			elseif state.currentView == "linear-detail" then
				linearUI.updateHover(state, foundIndex)
			end
		else
			if state.currentView == "main" then
				mainUI.updateHover(state, nil)
			elseif state.currentView == "linear-detail" then
				linearUI.updateHover(state, nil)
			end
		end
		return false
	end)
	state.hoverWatcher:start()

	state.clickWatcher = hs.eventtap.new({ hs.eventtap.event.types.leftMouseDown }, function(event)
		local pos = hs.mouse.absolutePosition()
		local f = state.canvasFrame
		if not f then
			return false
		end

		if pos.x >= f.x and pos.x <= f.x + f.w and pos.y >= f.y and pos.y <= f.y + f.h then
			local relY = pos.y - f.y

			for _, item in ipairs(state.clickableItems) do
				if relY >= item.y and relY <= item.y + item.h then
					if item.key and state.keyMap[item.key] then
						-- Simulate key press
						local fakeEvent = { getCharacters = function() return item.key end }
						state.escapeWatcher:callback()(fakeEvent)
						return true
					end
				end
			end

			if state.currentView == "main" then
				obj:hide()
			end
			return true
		else
			obj:hide()
		end
		return false
	end)
	state.clickWatcher:start()
end

--- Bind a hotkey to toggle the Attention dashboard
--- @param mods table Modifier keys (e.g., {"ctrl", "shift"})
--- @param key string The key to bind
--- @return Attention self
function obj:bindHotkey(mods, key)
	hs.hotkey.bind(mods, key, function()
		self:toggle()
	end)
	return self
end

--- Toggle the dashboard visibility
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
--- @return Attention self
function obj:show()
	showLoader()
	local hasCache = state.cache.linear and state.cache.slack
		and (state.cache.slack.dms or state.cache.slack.channels)
	if hasCache and not self:needsFetch() then
		renderMain()
	else
		self:fetchAll(function(data)
			renderMain()
		end)
	end
	return self
end

--- Hide the Attention dashboard
--- @return Attention self
function obj:hide()
	if state.loadingTimer then
		state.loadingTimer:stop()
		state.loadingTimer = nil
	end

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

	if state.webview then
		state.webview:delete()
		state.webview = nil
	end
	if state.canvas then
		state.canvas:hide()
		state.canvas:delete()
		state.canvas = nil
	end

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
		-- Split messages into DMs and channel mentions
		local dms = {}
		local channels = {}
		for _, msg in ipairs(messages or {}) do
			if msg.isDM or (msg.channel and msg.channel.is_im) then
				table.insert(dms, msg)
			else
				table.insert(channels, msg)
			end
		end
		results.slack = { dms = dms, channels = channels }
		checkComplete()
	end)

	return self
end

--- Check if cached data needs refresh
--- @return boolean needsFetch True if data should be refetched
function obj:needsFetch()
	return utils.needsFetch(state.lastFetchDate)
end

--- Refresh data from APIs
--- @return Attention self
function obj:refresh()
	self:fetchAll(function()
		print("Attention dashboard refreshed at " .. os.date("%Y-%m-%d %H:%M"))
	end)
	return self
end

--- Schedule daily refresh at 6am
--- @return Attention self
function obj:scheduleDailyRefresh()
	if state.dailyTimer then
		state.dailyTimer:stop()
	end
	state.dailyTimer = hs.timer.doAt("06:00", "1d", function()
		self:refresh()
	end)
	return self
end

--- Initialize the Spoon
--- @return Attention self
function obj:init()
	self:scheduleDailyRefresh()
	if self:needsFetch() then
		self:refresh()
	end
	return self
end

--- Get the current state (for debugging)
--- @return table state The current state table
function obj:getState()
	return state
end

return obj
