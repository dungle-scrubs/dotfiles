--- Attention.spoon
--- Unified dashboard for Linear issues and Slack messages

local obj = {}
obj.__index = obj

obj.name = "Attention"
obj.version = "1.0.0"
obj.author = "Kevin"
obj.license = "MIT"

-- Get spoon path for requires
local spoonPath = hs.spoons.scriptPath()
_G.AttentionSpoonPath = spoonPath
local utils = dofile(spoonPath .. "/utils.lua")
local linearApi = dofile(spoonPath .. "/api/linear.lua")
linearApi.getEnvVar = utils.getEnvVar
local slackApi = dofile(spoonPath .. "/api/slack.lua")
slackApi.getEnvVar = utils.getEnvVar
local styles = dofile(spoonPath .. "/ui/styles.lua")
-- Use built Preact UI for smooth updates
local slackUI = dofile(spoonPath .. "/ui/slack-built.lua")
slackUI.slackApi = slackApi  -- Share slackApi instance for user cache

-- State
obj.canvas = nil
obj.visible = false
obj.cache = { linear = nil, slack = nil }
obj.lastFetchDate = nil
obj.dailyTimer = nil
obj.clickableItems = {}
obj.currentView = "main" -- "main", "linear-detail", or "slack-detail"
obj.canvasFrame = nil
obj.hoveredIndex = nil
obj.hoverWatcher = nil
obj.lastCanvasSize = nil
obj.selectedIndex = nil
obj.keyMap = {}
obj.loadingTimer = nil
obj.loadingDots = 0
obj.scrollOffset = 0
obj.currentIssue = nil
obj.currentSlackMsg = nil
obj.currentSlackThread = nil
obj.currentSlackChannel = nil
obj.slackViewMode = "thread"
obj.slackHistoryCache = nil  -- Cache history when drilling into thread

-- Cursor stubs
local function setHandCursor() end
local function resetCursor() end

-- Fetch all sources
function obj:fetchAll(callback)
	local results = { linear = nil, slack = nil }
	local pending = 2

	local function checkDone()
		pending = pending - 1
		if pending == 0 then
			self.cache = results
			self.lastFetchDate = os.date("%Y-%m-%d")
			callback(results)
		end
	end

	linearApi.fetchIssues(function(data, err)
		results.linear = data or {}
		if err then print("Linear fetch error:", err) end
		checkDone()
	end)

	slackApi.fetchMentions(function(data, err)
		results.slack = data or {}
		if err then print("Slack fetch error:", err) end
		checkDone()
	end)
end

function obj:needsFetch()
	local today = os.date("%Y-%m-%d")
	return self.lastFetchDate ~= today
end

function obj:showLoader()
	if self.loadingTimer then
		self.loadingTimer:stop()
		self.loadingTimer = nil
	end

	local font = "CaskaydiaCove Nerd Font Mono"
	local fontSize = 14

	local screen = hs.screen.mainScreen()
	local screenFrame = screen:frame()

	local boxWidth, boxHeight
	if self.lastCanvasSize then
		boxWidth = self.lastCanvasSize.w
		boxHeight = self.lastCanvasSize.h
	else
		boxWidth = 300
		boxHeight = 100
	end

	local boxX = screenFrame.x + (screenFrame.w - boxWidth) / 2
	local boxY = screenFrame.y + (screenFrame.h - boxHeight) / 2

	if self.canvas then
		self.canvas:delete()
	end

	self.canvas = hs.canvas.new({ x = boxX, y = boxY, w = boxWidth, h = boxHeight })
	self.canvasFrame = { x = boxX, y = boxY, w = boxWidth, h = boxHeight }
	local c = self.canvas

	c[1] = { type = "rectangle", action = "fill", fillColor = { hex = "#1a1a1a", alpha = 0.95 }, roundedRectRadii = { xRadius = 10, yRadius = 10 } }
	c[2] = { type = "rectangle", action = "stroke", strokeColor = { hex = "#5e6ad2", alpha = 0.9 }, strokeWidth = 2, roundedRectRadii = { xRadius = 10, yRadius = 10 } }
	c[3] = { type = "text", text = "Loading.  ", textFont = font, textSize = fontSize, textColor = { hex = "#5e6ad2", alpha = 1 }, textAlignment = "center", frame = { x = 0, y = (boxHeight - fontSize) / 2, w = boxWidth, h = fontSize + 4 } }

	c:level(hs.canvas.windowLevels.overlay)
	c:clickActivating(false)
	c:show()
	self.visible = true

	self.loadingDots = 0
	local selfRef = self
	self.loadingTimer = hs.timer.doEvery(0.3, function()
		selfRef.loadingDots = (selfRef.loadingDots % 3) + 1
		local dots = string.rep(".", selfRef.loadingDots) .. string.rep(" ", 3 - selfRef.loadingDots)
		if selfRef.canvas and selfRef.canvas[3] then
			selfRef.canvas[3].text = "Loading" .. dots
		end
	end)
end

function obj:render(data)
	if self.loadingTimer then
		self.loadingTimer:stop()
		self.loadingTimer = nil
	end

	self.currentView = "main"
	self.clickableItems = {}
	self.hoveredIndex = nil
	self.keyMap = {}
	local itemIndex = 0

	local font = "CaskaydiaCove Nerd Font Mono"
	local fontSize = 14
	local lineHeight = fontSize + 10
	local sectionHeaderHeight = fontSize + 16
	local groupHeaderHeight = fontSize + 12
	local padding = 24
	local titleHeight = 36
	local sectionSpacing = 20
	local groupSpacing = 8

	-- Group Linear by project
	local linearProjects = {}
	local linearProjectOrder = {}
	for _, issue in ipairs(data.linear or {}) do
		local projectName = issue.project and issue.project.name or "No Project"
		if not linearProjects[projectName] then
			linearProjects[projectName] = {}
			table.insert(linearProjectOrder, projectName)
		end
		table.insert(linearProjects[projectName], issue)
	end

	local linearLines = #(data.linear or {})
	local linearGroups = #linearProjectOrder
	local slackDms = data.slack and data.slack.dms or {}
	local slackChannels = data.slack and data.slack.channels or {}
	local slackDmLines = math.min(#slackDms, 5)
	local slackChannelLines = math.min(#slackChannels, 5)

	local contentHeight = titleHeight + padding * 2 + 16
	if linearLines > 0 then
		contentHeight = contentHeight + sectionHeaderHeight + (linearLines * lineHeight) + (linearGroups * (groupHeaderHeight + groupSpacing)) + sectionSpacing
	end
	if slackChannelLines > 0 or slackDmLines > 0 then
		contentHeight = contentHeight + sectionHeaderHeight
		if slackChannelLines > 0 then
			contentHeight = contentHeight + groupHeaderHeight + (slackChannelLines * lineHeight) + groupSpacing
		end
		if slackDmLines > 0 then
			contentHeight = contentHeight + groupHeaderHeight + (slackDmLines * lineHeight)
		end
	end

	local boxWidth = 900

	local screen = hs.screen.mainScreen()
	local frame = screen:frame()
	local boxX = frame.x + (frame.w - boxWidth) / 2
	local boxY = frame.y + (frame.h - contentHeight) / 2

	if self.canvas then
		self.canvas:delete()
	end

	self.canvas = hs.canvas.new({ x = boxX, y = boxY, w = boxWidth, h = contentHeight })
	self.canvasFrame = { x = boxX, y = boxY, w = boxWidth, h = contentHeight }
	self.lastCanvasSize = { w = boxWidth, h = contentHeight }
	local c = self.canvas

	c[1] = { type = "rectangle", action = "fill", fillColor = { hex = "#1a1a1a", alpha = 0.95 }, roundedRectRadii = { xRadius = 10, yRadius = 10 } }
	c[2] = { type = "rectangle", action = "stroke", strokeColor = { hex = "#5e6ad2", alpha = 0.9 }, strokeWidth = 2, roundedRectRadii = { xRadius = 10, yRadius = 10 } }

	local totalItems = linearLines + slackChannelLines + slackDmLines
	c[3] = { type = "text", text = "Attention (" .. totalItems .. ")", textFont = font, textSize = fontSize + 4, textColor = { hex = "#5e6ad2", alpha = 1 }, textAlignment = "center", frame = { x = padding, y = padding, w = boxWidth - (padding * 2), h = titleHeight } }
	c[4] = { type = "rectangle", action = "fill", fillColor = { hex = "#444444", alpha = 1 }, frame = { x = padding, y = padding + titleHeight, w = boxWidth - (padding * 2), h = 1 } }
	c[5] = { type = "rectangle", action = "fill", fillColor = { hex = "#ffffff", alpha = 0 }, frame = { x = 0, y = 0, w = 0, h = 0 } }

	local yPos = padding + titleHeight + 16

	-- Linear section
	if #(data.linear or {}) > 0 then
		c[#c + 1] = { type = "text", text = "Linear", textFont = font, textSize = fontSize + 2, textColor = { hex = "#5e6ad2", alpha = 1 }, textAlignment = "left", frame = { x = padding, y = yPos, w = boxWidth - (padding * 2), h = sectionHeaderHeight } }
		yPos = yPos + sectionHeaderHeight

		for _, projectName in ipairs(linearProjectOrder) do
			c[#c + 1] = { type = "text", text = projectName, textFont = font, textSize = fontSize, textColor = { hex = "#f97316", alpha = 1 }, textAlignment = "left", frame = { x = padding + 12, y = yPos, w = boxWidth - (padding * 2), h = groupHeaderHeight } }
			yPos = yPos + groupHeaderHeight

			for _, issue in ipairs(linearProjects[projectName]) do
				itemIndex = itemIndex + 1
				local shortcut = utils.getShortcutKey(itemIndex)

				table.insert(self.clickableItems, {
					type = "linear",
					y = yPos,
					h = lineHeight,
					x = padding,
					w = boxWidth - padding * 2,
					data = issue,
					key = shortcut
				})
				if shortcut then self.keyMap[shortcut] = #self.clickableItems end

				c[#c + 1] = { type = "text", text = shortcut or "", textFont = font, textSize = fontSize, textColor = { hex = "#5e6ad2", alpha = 1 }, textAlignment = "center", frame = { x = padding, y = yPos, w = 20, h = lineHeight } }
				c[#c + 1] = { type = "text", text = issue.identifier, textFont = font, textSize = fontSize, textColor = { hex = "#8b8b8b", alpha = 1 }, textAlignment = "left", frame = { x = padding + 28, y = yPos, w = 100, h = lineHeight } }

				local title = issue.title
				local maxChars = 85
				if #title > maxChars then title = title:sub(1, maxChars - 1) .. "..." end
				c[#c + 1] = { type = "text", text = title, textFont = font, textSize = fontSize, textColor = { hex = "#ffffff", alpha = 1 }, textAlignment = "left", frame = { x = padding + 130, y = yPos, w = boxWidth - padding - 150, h = lineHeight } }

				yPos = yPos + lineHeight
			end
			yPos = yPos + groupSpacing
		end
		yPos = yPos + sectionSpacing - groupSpacing
	end

	-- Slack section
	if #slackChannels > 0 or #slackDms > 0 then
		c[#c + 1] = { type = "text", text = "Slack", textFont = font, textSize = fontSize + 2, textColor = { hex = "#e01e5a", alpha = 1 }, textAlignment = "left", frame = { x = padding, y = yPos, w = boxWidth - (padding * 2), h = sectionHeaderHeight } }
		yPos = yPos + sectionHeaderHeight

		if #slackChannels > 0 then
			c[#c + 1] = { type = "text", text = "Mentions", textFont = font, textSize = fontSize, textColor = { hex = "#f97316", alpha = 1 }, textAlignment = "left", frame = { x = padding + 12, y = yPos, w = boxWidth - (padding * 2), h = groupHeaderHeight } }
			yPos = yPos + groupHeaderHeight

			for i, msg in ipairs(slackChannels) do
				if i > 5 then break end
				itemIndex = itemIndex + 1
				local shortcut = utils.getShortcutKey(itemIndex)

				table.insert(self.clickableItems, {
					type = "slack",
					y = yPos,
					h = lineHeight,
					x = padding,
					w = boxWidth - padding * 2,
					data = msg,
					key = shortcut
				})
				if shortcut then self.keyMap[shortcut] = #self.clickableItems end

				local from = msg.username or "unknown"
				local channel = msg.channel and msg.channel.name or ""
				local text = msg.text or ""
				text = text:gsub("<@[^>]+[^>]*>", ""):gsub("<[^>]+>", ""):gsub("%s+", " "):gsub("^%s+", "")
				local maxChars = 65
				if #text > maxChars then text = text:sub(1, maxChars - 1) .. "..." end

				c[#c + 1] = { type = "text", text = shortcut or "", textFont = font, textSize = fontSize, textColor = { hex = "#e01e5a", alpha = 1 }, textAlignment = "center", frame = { x = padding, y = yPos, w = 20, h = lineHeight } }
				c[#c + 1] = { type = "text", text = "#" .. channel, textFont = font, textSize = fontSize, textColor = { hex = "#8b8b8b", alpha = 1 }, textAlignment = "left", frame = { x = padding + 28, y = yPos, w = 120, h = lineHeight } }
				c[#c + 1] = { type = "text", text = from .. ": " .. text, textFont = font, textSize = fontSize, textColor = { hex = "#ffffff", alpha = 1 }, textAlignment = "left", frame = { x = padding + 155, y = yPos, w = boxWidth - padding - 175, h = lineHeight } }

				yPos = yPos + lineHeight
			end
			yPos = yPos + groupSpacing
		end

		if #slackDms > 0 then
			c[#c + 1] = { type = "text", text = "DMs", textFont = font, textSize = fontSize, textColor = { hex = "#f97316", alpha = 1 }, textAlignment = "left", frame = { x = padding + 12, y = yPos, w = boxWidth - (padding * 2), h = groupHeaderHeight } }
			yPos = yPos + groupHeaderHeight

			for i, msg in ipairs(slackDms) do
				if i > 5 then break end
				itemIndex = itemIndex + 1
				local shortcut = utils.getShortcutKey(itemIndex)

				table.insert(self.clickableItems, {
					type = "slack",
					y = yPos,
					h = lineHeight,
					x = padding,
					w = boxWidth - padding * 2,
					data = msg,
					key = shortcut
				})
				if shortcut then self.keyMap[shortcut] = #self.clickableItems end

				local from = msg.username or "unknown"
				local text = msg.text or ""
				text = text:gsub("<@[^>]+[^>]*>", ""):gsub("<[^>]+>", ""):gsub("%s+", " "):gsub("^%s+", "")
				local maxChars = 70
				if #text > maxChars then text = text:sub(1, maxChars - 1) .. "..." end

				c[#c + 1] = { type = "text", text = shortcut or "", textFont = font, textSize = fontSize, textColor = { hex = "#e01e5a", alpha = 1 }, textAlignment = "center", frame = { x = padding, y = yPos, w = 20, h = lineHeight } }
				c[#c + 1] = { type = "text", text = from, textFont = font, textSize = fontSize, textColor = { hex = "#8b8b8b", alpha = 1 }, textAlignment = "left", frame = { x = padding + 28, y = yPos, w = 120, h = lineHeight } }
				c[#c + 1] = { type = "text", text = text, textFont = font, textSize = fontSize, textColor = { hex = "#ffffff", alpha = 1 }, textAlignment = "left", frame = { x = padding + 155, y = yPos, w = boxWidth - padding - 175, h = lineHeight } }

				yPos = yPos + lineHeight
			end
		end
	end

	c:level(hs.canvas.windowLevels.overlay)
	c:clickActivating(false)
	c:behaviorAsLabels({ "canJoinAllSpaces", "stationary" })
	c:show()
	self.visible = true
	self:setupEventHandlers()
end

function obj:renderLinearDetail(issue, resetScroll)
	if self.loadingTimer then
		self.loadingTimer:stop()
		self.loadingTimer = nil
	end

	if issue then
		self.currentIssue = issue
	else
		issue = self.currentIssue
	end
	if not issue then return end

	if resetScroll ~= false then
		self.scrollOffset = 0
	end

	self.currentView = "linear-detail"
	self.clickableItems = {}
	self.hoveredIndex = nil
	self.keyMap = {}
	self.keyMap["b"] = 1

	local font = "CaskaydiaCove Nerd Font Mono"
	local fontSize = 14
	local lineHeight = fontSize + 8
	local padding = 24
	local boxWidth = 900
	local boxHeight = 600
	local footerHeight = 36
	local contentTop = 60

	local screen = hs.screen.mainScreen()
	local frame = screen:frame()
	local boxX = frame.x + (frame.w - boxWidth) / 2
	local boxY = frame.y + (frame.h - boxHeight) / 2

	if self.canvas then
		self.canvas:delete()
	end

	self.canvas = hs.canvas.new({ x = boxX, y = boxY, w = boxWidth, h = boxHeight })
	self.canvasFrame = { x = boxX, y = boxY, w = boxWidth, h = boxHeight }
	self.lastCanvasSize = { w = boxWidth, h = boxHeight }
	local c = self.canvas

	c[1] = { type = "rectangle", action = "fill", fillColor = { hex = "#1a1a1a", alpha = 0.95 }, roundedRectRadii = { xRadius = 10, yRadius = 10 } }
	c[2] = { type = "rectangle", action = "stroke", strokeColor = { hex = "#5e6ad2", alpha = 0.9 }, strokeWidth = 2, roundedRectRadii = { xRadius = 10, yRadius = 10 } }

	table.insert(self.clickableItems, { type = "back", y = padding, h = 30, x = padding, w = 90, key = "b" })
	c[3] = { type = "text", text = "b", textFont = font, textSize = fontSize, textColor = { hex = "#5e6ad2", alpha = 1 }, textAlignment = "left", frame = { x = padding, y = padding, w = 16, h = 30 } }
	c[4] = { type = "text", text = "<- Back", textFont = font, textSize = fontSize, textColor = { hex = "#888888", alpha = 1 }, textAlignment = "left", frame = { x = padding + 20, y = padding, w = 70, h = 30 } }
	c[5] = { type = "rectangle", action = "fill", fillColor = { hex = "#ffffff", alpha = 0 }, frame = { x = 0, y = 0, w = 0, h = 0 } }

	local titleY = padding + 10
	c[#c + 1] = { type = "text", text = issue.identifier, textFont = font, textSize = fontSize + 2, textColor = { hex = "#8b8b8b", alpha = 1 }, textAlignment = "center", frame = { x = padding, y = titleY, w = boxWidth - (padding * 2), h = 30 } }

	local clipTop = padding + 45
	local clipHeight = boxHeight - clipTop - footerHeight - 8
	c[#c + 1] = { type = "rectangle", action = "clip", frame = { x = 0, y = clipTop, w = boxWidth, h = clipHeight } }

	local scrollY = -self.scrollOffset
	local yPos = clipTop + 5 + scrollY

	c[#c + 1] = { type = "text", text = issue.title or "Untitled", textFont = font, textSize = fontSize + 6, textColor = { hex = "#ffffff", alpha = 1 }, textAlignment = "left", frame = { x = padding, y = yPos, w = boxWidth - (padding * 2), h = 36 } }
	yPos = yPos + 44

	local status = issue.state and issue.state.name or "Unknown"
	local project = issue.project and issue.project.name or "No Project"
	c[#c + 1] = { type = "text", text = status .. "  *  " .. project, textFont = font, textSize = fontSize, textColor = { hex = "#f97316", alpha = 1 }, textAlignment = "left", frame = { x = padding, y = yPos, w = boxWidth - (padding * 2), h = lineHeight } }
	yPos = yPos + lineHeight + 16

	c[#c + 1] = { type = "rectangle", action = "fill", fillColor = { hex = "#444444", alpha = 1 }, frame = { x = padding, y = yPos, w = boxWidth - (padding * 2), h = 1 } }
	yPos = yPos + 20

	c[#c + 1] = { type = "text", text = "Description", textFont = font, textSize = fontSize, textColor = { hex = "#5e6ad2", alpha = 1 }, textAlignment = "left", frame = { x = padding, y = yPos, w = boxWidth - (padding * 2), h = lineHeight } }
	yPos = yPos + lineHeight + 4

	local desc = issue.description or "(No description)"
	if #desc > 2000 then desc = desc:sub(1, 2000) .. "..." end
	local descLines = math.ceil(#desc / 80)
	local descHeight = math.max(50, descLines * 18)
	c[#c + 1] = { type = "text", text = desc, textFont = font, textSize = fontSize - 1, textColor = { hex = "#cccccc", alpha = 1 }, textAlignment = "left", frame = { x = padding, y = yPos, w = boxWidth - (padding * 2), h = descHeight } }
	yPos = yPos + descHeight + 20

	local comments = issue.comments and issue.comments.nodes or {}
	if #comments > 0 then
		c[#c + 1] = { type = "rectangle", action = "fill", fillColor = { hex = "#444444", alpha = 1 }, frame = { x = padding, y = yPos, w = boxWidth - (padding * 2), h = 1 } }
		yPos = yPos + 20

		c[#c + 1] = { type = "text", text = "Comments (" .. #comments .. ")", textFont = font, textSize = fontSize, textColor = { hex = "#5e6ad2", alpha = 1 }, textAlignment = "left", frame = { x = padding, y = yPos, w = boxWidth - (padding * 2), h = lineHeight } }
		yPos = yPos + lineHeight + 8

		for _, comment in ipairs(comments) do
			local author = comment.user and comment.user.name or "Unknown"
			local body = comment.body or ""
			if #body > 500 then body = body:sub(1, 500) .. "..." end
			local commentLines = math.ceil(#body / 80)
			local commentHeight = math.max(30, commentLines * 18)

			c[#c + 1] = { type = "text", text = author, textFont = font, textSize = fontSize - 1, textColor = { hex = "#f97316", alpha = 1 }, textAlignment = "left", frame = { x = padding, y = yPos, w = boxWidth - (padding * 2), h = lineHeight } }
			yPos = yPos + lineHeight

			c[#c + 1] = { type = "text", text = body, textFont = font, textSize = fontSize - 1, textColor = { hex = "#aaaaaa", alpha = 1 }, textAlignment = "left", frame = { x = padding + 12, y = yPos, w = boxWidth - (padding * 2) - 12, h = commentHeight } }
			yPos = yPos + commentHeight + 12
		end
	end

	self.contentHeight = yPos + self.scrollOffset - padding
	self.viewHeight = boxHeight - contentTop - footerHeight - 8

	c[#c + 1] = { type = "resetClip" }

	local footerY = boxHeight - footerHeight
	c[#c + 1] = { type = "rectangle", action = "fill", fillColor = { hex = "#252525", alpha = 1 }, frame = { x = 0, y = footerY, w = boxWidth, h = footerHeight } }
	c[#c + 1] = { type = "rectangle", action = "fill", fillColor = { hex = "#444444", alpha = 1 }, frame = { x = padding, y = footerY, w = boxWidth - (padding * 2), h = 1 } }

	local hintY = footerY + 10
	local hintSize = fontSize - 2
	local keyColor = { hex = "#5e6ad2", alpha = 1 }
	local textColor = { hex = "#666666", alpha = 1 }

	local canScrollUp = self.scrollOffset > 0
	local canScrollDown = self.contentHeight > self.viewHeight + self.scrollOffset
	local scrollHint = ""
	if canScrollUp and canScrollDown then scrollHint = "^v"
	elseif canScrollUp then scrollHint = "^"
	elseif canScrollDown then scrollHint = "v"
	end

	local xPos = padding
	c[#c + 1] = { type = "text", text = "j/k", textFont = font, textSize = hintSize, textColor = keyColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 30, h = 20 } }
	xPos = xPos + 32
	c[#c + 1] = { type = "text", text = "scroll " .. scrollHint, textFont = font, textSize = hintSize, textColor = textColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 80, h = 20 } }
	xPos = xPos + 90
	c[#c + 1] = { type = "text", text = "^d/^u", textFont = font, textSize = hintSize, textColor = keyColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 50, h = 20 } }
	xPos = xPos + 52
	c[#c + 1] = { type = "text", text = "page", textFont = font, textSize = hintSize, textColor = textColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 40, h = 20 } }
	xPos = xPos + 60
	c[#c + 1] = { type = "text", text = "b", textFont = font, textSize = hintSize, textColor = keyColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 14, h = 20 } }
	xPos = xPos + 16
	c[#c + 1] = { type = "text", text = "back", textFont = font, textSize = hintSize, textColor = textColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 40, h = 20 } }
	xPos = xPos + 60
	c[#c + 1] = { type = "text", text = "esc", textFont = font, textSize = hintSize, textColor = keyColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 30, h = 20 } }
	xPos = xPos + 32
	c[#c + 1] = { type = "text", text = "close", textFont = font, textSize = hintSize, textColor = textColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 50, h = 20 } }

	c:level(hs.canvas.windowLevels.overlay)
	c:clickActivating(false)
	c:show()
	self.visible = true
	self:setupEventHandlers()
end

function obj:renderSlackDetail(msg, thread, resetScroll, isInitialLoading)
	print("[Attention] renderSlackDetail called - THIS CREATES NEW WEBVIEW")
	print("[Attention] Stack trace: " .. debug.traceback())
	-- Prevent re-render during pagination
	if self.paginationInProgress then
		print("[Attention] BLOCKED - pagination in progress, skipping re-render")
		return
	end
	if self.loadingTimer then
		self.loadingTimer:stop()
		self.loadingTimer = nil
	end

	local selfRef = self
	local keepScroll = (resetScroll == false)

	slackUI.renderWebview(self, msg, thread, keepScroll, isInitialLoading, {
		onBack = function()
			-- If we have cached history (came from history view into thread), go back to history
			if selfRef.slackHistoryCache and selfRef.slackViewMode == "thread" then
				selfRef.slackViewMode = "history"
				local cachedHistory = selfRef.slackHistoryCache
				selfRef.slackHistoryCache = nil
				selfRef:renderSlackDetail(selfRef.currentSlackMsg, cachedHistory)
			else
				slackUI.closeWebview(selfRef)
				selfRef:render(selfRef.cache)
			end
		end,
		onClose = function()
			selfRef:hide()
		end,
		onOpenSlack = function(permalink)
			if permalink then
				hs.urlevent.openURL(permalink)
			end
		end,
		onChannelUp = function()
			-- Switch to history mode in-place
			if selfRef.currentSlackChannel then
				-- Use cached history if available for instant switch
				if selfRef.slackHistoryCache and #selfRef.slackHistoryCache > 0 then
					slackUI.switchView(selfRef, "history", selfRef.slackHistoryCache)
				else
					slackApi.fetchHistory(selfRef.currentSlackChannel, function(messages, err)
						slackUI.switchView(selfRef, "history", messages)
					end)
				end
			end
		end,
		onThreadClick = function(threadTs)
			-- Cache current history before switching to thread view
			if selfRef.slackViewMode == "history" and selfRef.currentSlackThread then
				selfRef.slackHistoryCache = selfRef.currentSlackThread
			end
			-- Switch to thread mode in-place
			local channelId = selfRef.currentSlackMsg.channel and selfRef.currentSlackMsg.channel.id
			if channelId and threadTs then
				slackApi.fetchThread(channelId, threadTs, function(threadMsgs, err)
					slackUI.switchView(selfRef, "thread", threadMsgs)
				end)
			end
		end,
		onLoadMore = function()
			print("[Attention] onLoadMore callback triggered")
			-- Set pagination flag to prevent re-renders
			selfRef.paginationInProgress = true

			-- Pagination - load older messages (inject without re-rendering)
			local channelId = selfRef.currentSlackChannel
			if not channelId then
				print("[Attention] No channel ID, aborting loadMore")
				selfRef.paginationInProgress = false
				slackUI.resetLoadingFlag(selfRef)
				return
			end

			local oldestTs = nil
			if selfRef.currentSlackThread and #selfRef.currentSlackThread > 0 then
				oldestTs = selfRef.currentSlackThread[1].ts
			end
			print("[Attention] Fetching history for channel: " .. channelId .. ", oldest: " .. tostring(oldestTs))

			slackApi.fetchHistory(channelId, function(olderMessages, err)
				print("[Attention] fetchHistory returned, count: " .. tostring(olderMessages and #olderMessages or 0))
				if olderMessages and #olderMessages > 0 then
					-- Update state with combined messages
					local combined = {}
					for _, m in ipairs(olderMessages) do
						table.insert(combined, m)
					end
					for _, m in ipairs(selfRef.currentSlackThread or {}) do
						table.insert(combined, m)
					end
					selfRef.currentSlackThread = combined
					selfRef.slackViewMode = "history"

					-- Inject messages into existing webview (no flash)
					print("[Attention] Calling prependMessages with " .. #olderMessages .. " messages")
					slackUI.prependMessages(selfRef, olderMessages)
				else
					print("[Attention] No older messages, resetting loading flag")
					slackUI.resetLoadingFlag(selfRef)
				end
				-- Clear pagination flag after operation completes
				selfRef.paginationInProgress = false
			end, oldestTs)
		end,
	})
end

function obj:updateHover(index)
	if self.hoveredIndex == index then return end
	self.hoveredIndex = index

	if not self.canvas then return end

	if index and self.clickableItems[index] then
		local item = self.clickableItems[index]
		self.canvas[5] = {
			type = "rectangle",
			action = "fill",
			fillColor = { hex = "#ffffff", alpha = 0.08 },
			roundedRectRadii = { xRadius = 4, yRadius = 4 },
			frame = { x = item.x or 24, y = item.y, w = item.w or 852, h = item.h }
		}
		setHandCursor()
	else
		self.canvas[5] = {
			type = "rectangle",
			action = "fill",
			fillColor = { hex = "#ffffff", alpha = 0 },
			frame = { x = 0, y = 0, w = 0, h = 0 }
		}
		resetCursor()
	end
end

function obj:setupEventHandlers()
	if self.escapeWatcher then
		self.escapeWatcher:stop()
	end
	if self.clickWatcher then
		self.clickWatcher:stop()
	end
	if self.hoverWatcher then
		self.hoverWatcher:stop()
	end

	local selfRef = self

	self.escapeWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
		local keyCode = event:getKeyCode()
		local char = event:getCharacters()
		local mods = event:getFlags()

		if keyCode == 53 then
			if selfRef.currentView == "linear-detail" or selfRef.currentView == "slack-detail" then
				selfRef.scrollOffset = 0
				selfRef:render(selfRef.cache)
			else
				selfRef:hide()
			end
			return true
		end

		-- Only handle scroll keys for canvas-based linear-detail view
		-- slack-detail uses webview which handles its own scrolling via JavaScript
		if selfRef.currentView == "linear-detail" then
			local scrollDown = (mods.ctrl and keyCode == 2) or (keyCode == 38)
			local scrollUp = (mods.ctrl and keyCode == 32) or (keyCode == 40)

			if scrollDown then
				local maxScroll = math.max(0, (selfRef.contentHeight or 0) - (selfRef.viewHeight or 400))
				selfRef.scrollOffset = math.min(selfRef.scrollOffset + 100, maxScroll)
				selfRef:renderLinearDetail(nil, false)
				return true
			end

			if scrollUp then
				selfRef.scrollOffset = math.max(0, selfRef.scrollOffset - 100)
				selfRef:renderLinearDetail(nil, false)
				return true
			end
		end

		if char and selfRef.keyMap[char] then
			local itemIdx = selfRef.keyMap[char]
			local item = selfRef.clickableItems[itemIdx]
			if item then
				if item.type == "linear" then
					selfRef:showLoader()
					linearApi.fetchDetail(item.data.identifier, function(issue, err)
						if issue then
							selfRef:renderLinearDetail(issue)
						else
							selfRef:render(selfRef.cache)
							hs.alert.show("Failed to load issue")
						end
					end)
				elseif item.type == "slack" then
					-- Immediately show webview with loading state (no showLoader gap)
					local channelId = item.data.channel and item.data.channel.id
					local isDM = item.data.channel and item.data.channel.is_im
					selfRef.currentSlackChannel = channelId

					if isDM and channelId then
						selfRef.slackViewMode = "history"
						-- Show webview immediately with empty messages (loading state)
						selfRef:renderSlackDetail(item.data, {}, false, true)
						slackApi.fetchHistory(channelId, function(messages, err)
							-- Update the existing webview with messages
							slackUI.updateInitialMessages(selfRef, messages)
						end)
					else
						selfRef.slackViewMode = "thread"
						local threadTs = item.data.thread_ts or item.data.ts
						if channelId and threadTs then
							-- Show webview immediately with empty messages (loading state)
							selfRef:renderSlackDetail(item.data, {}, false, true)
							slackApi.fetchThread(channelId, threadTs, function(thread, err)
								-- Update the existing webview with messages
								slackUI.updateInitialMessages(selfRef, thread)
							end)
						else
							selfRef:renderSlackDetail(item.data, {})
						end
					end
				elseif item.type == "back" then
					selfRef.scrollOffset = 0
					selfRef:render(selfRef.cache)
				elseif item.type == "open-slack" then
					if item.data and item.data.permalink then
						hs.urlevent.openURL(item.data.permalink)
					end
					selfRef:hide()
				elseif item.type == "channel-up" then
					if selfRef.currentSlackChannel then
						selfRef:showLoader()
						selfRef.slackViewMode = "history"
						slackApi.fetchHistory(selfRef.currentSlackChannel, function(messages, err)
							selfRef:renderSlackDetail(selfRef.currentSlackMsg, messages)
						end)
					end
				end
			end
			return true
		end

		return true
	end)
	self.escapeWatcher:start()

	self.hoverWatcher = hs.eventtap.new({ hs.eventtap.event.types.mouseMoved }, function(event)
		local pos = hs.mouse.absolutePosition()
		local f = selfRef.canvasFrame
		if not f then return false end

		if pos.x >= f.x and pos.x <= f.x + f.w and pos.y >= f.y and pos.y <= f.y + f.h then
			local relY = pos.y - f.y
			local relX = pos.x - f.x

			local foundIndex = nil
			for i, item in ipairs(selfRef.clickableItems) do
				local itemX = item.x or 0
				local itemW = item.w or f.w
				if relY >= item.y and relY <= item.y + item.h then
					if item.type == "back" or item.type == "open-slack" or item.type == "channel-up" then
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

			selfRef:updateHover(foundIndex)
		else
			selfRef:updateHover(nil)
		end
		return false
	end)
	self.hoverWatcher:start()

	self.clickWatcher = hs.eventtap.new({ hs.eventtap.event.types.leftMouseDown }, function(event)
		local pos = hs.mouse.absolutePosition()
		local f = selfRef.canvasFrame
		if not f then return false end

		if pos.x >= f.x and pos.x <= f.x + f.w and pos.y >= f.y and pos.y <= f.y + f.h then
			local relY = pos.y - f.y
			local relX = pos.x - f.x

			for _, item in ipairs(selfRef.clickableItems) do
				if relY >= item.y and relY <= item.y + item.h then
					if item.type == "back" then
						if relX >= item.x and relX <= item.x + item.w then
							selfRef.scrollOffset = 0
							selfRef:render(selfRef.cache)
							return true
						end
					elseif item.type == "open-slack" then
						if relX >= item.x and relX <= item.x + item.w then
							if item.data and item.data.permalink then
								hs.urlevent.openURL(item.data.permalink)
							end
							selfRef:hide()
							return true
						end
					elseif item.type == "linear" then
						selfRef:showLoader()
						linearApi.fetchDetail(item.data.identifier, function(issue, err)
							if issue then
								selfRef:renderLinearDetail(issue)
							else
								selfRef:render(selfRef.cache)
								hs.alert.show("Failed to load issue")
							end
						end)
						return true
					elseif item.type == "slack" then
						selfRef:showLoader()
						local channelId = item.data.channel and item.data.channel.id
						local isDM = item.data.channel and item.data.channel.is_im
						selfRef.currentSlackChannel = channelId

						if isDM and channelId then
							selfRef.slackViewMode = "history"
							slackApi.fetchHistory(channelId, function(messages, err)
								selfRef:renderSlackDetail(item.data, messages)
							end)
						else
							selfRef.slackViewMode = "thread"
							local threadTs = item.data.thread_ts or item.data.ts
							if channelId and threadTs then
								slackApi.fetchThread(channelId, threadTs, function(thread, err)
									selfRef:renderSlackDetail(item.data, thread)
								end)
							else
								selfRef:renderSlackDetail(item.data, {})
							end
						end
						return true
					elseif item.type == "channel-up" then
						if relX >= item.x and relX <= item.x + item.w then
							if selfRef.currentSlackChannel then
								selfRef:showLoader()
								selfRef.slackViewMode = "history"
								slackApi.fetchHistory(selfRef.currentSlackChannel, function(messages, err)
									selfRef:renderSlackDetail(selfRef.currentSlackMsg, messages)
								end)
							end
							return true
						end
					end
				end
			end

			if selfRef.currentView == "main" then
				selfRef:hide()
			end
			return true
		else
			selfRef:hide()
		end
		return false
	end)
	self.clickWatcher:start()

	-- Block scroll events from passing through to background apps (but not inside our window)
	self.scrollWatcher = hs.eventtap.new({ hs.eventtap.event.types.scrollWheel }, function(event)
		local mousePos = hs.mouse.absolutePosition()
		local frame = selfRef.canvasFrame
		if frame then
			-- Check if mouse is inside our window
			local inside = mousePos.x >= frame.x and mousePos.x <= frame.x + frame.w
				and mousePos.y >= frame.y and mousePos.y <= frame.y + frame.h
			if inside then
				-- Let the webview handle scrolling
				return false
			end
		end
		-- Block scroll events outside the window
		return true
	end)
	self.scrollWatcher:start()
end

function obj:show()
	self:showLoader()
	if self.cache.linear and self.cache.slack and not self:needsFetch() then
		self:render(self.cache)
	else
		self:fetchAll(function(data)
			self:render(data)
		end)
	end
end

function obj:hide()
	print("[Attention] hide() called")
	print("[Attention] Stack trace: " .. debug.traceback())
	resetCursor()
	if self.loadingTimer then
		self.loadingTimer:stop()
		self.loadingTimer = nil
	end
	-- Clean up webview if present
	slackUI.closeWebview(self)
	if self.canvas then
		self.canvas:hide()
		self.canvas:delete()
		self.canvas = nil
	end
	self.visible = false
	if self.escapeWatcher then
		self.escapeWatcher:stop()
		self.escapeWatcher = nil
	end
	if self.clickWatcher then
		self.clickWatcher:stop()
		self.clickWatcher = nil
	end
	if self.hoverWatcher then
		self.hoverWatcher:stop()
		self.hoverWatcher = nil
	end
	if self.scrollWatcher then
		self.scrollWatcher:stop()
		self.scrollWatcher = nil
	end
	self.currentView = "main"
	self.clickableItems = {}
	self.canvasFrame = nil
	self.hoveredIndex = nil
	self.scrollOffset = 0
	self.currentIssue = nil
	self.currentSlackMsg = nil
	self.currentSlackThread = nil
	self.slackHistoryCache = nil
end

function obj:toggle()
	if self.visible then
		self:hide()
	else
		self:show()
	end
end

function obj:refresh()
	self:fetchAll(function()
		print("Attention dashboard refreshed at " .. os.date("%Y-%m-%d %H:%M"))
	end)
end

function obj:scheduleDailyRefresh()
	if self.dailyTimer then
		self.dailyTimer:stop()
	end
	self.dailyTimer = hs.timer.doAt("06:00", "1d", function()
		self:refresh()
	end)
end

function obj:init()
	self:scheduleDailyRefresh()
	if self:needsFetch() then
		self:refresh()
	end
	return self
end

return obj
