--- Attention.spoon
--- Unified dashboard for Linear issues and Slack messages
--- Organized by Project with search bar

local obj = {}
obj.__index = obj

obj.name = "Attention"
obj.version = "2.0.0"
obj.author = "Kevin"
obj.license = "MIT"

-- Get spoon path for requires
local spoonPath = hs.spoons.scriptPath()
_G.AttentionSpoonPath = spoonPath

-- Load modules
local utils = dofile(spoonPath .. "/utils.lua")
local config = dofile(spoonPath .. "/config.lua")
local linearApi = dofile(spoonPath .. "/api/linear.lua")
linearApi.getEnvVar = utils.getEnvVar
local slackApi = dofile(spoonPath .. "/api/slack.lua")
slackApi.getEnvVar = utils.getEnvVar
local calendarApi = dofile(spoonPath .. "/api/calendar.lua")
local notionApi = dofile(spoonPath .. "/api/notion.lua")
notionApi.getEnvVar = utils.getEnvVar
local fetch = dofile(spoonPath .. "/fetch.lua")
local search = dofile(spoonPath .. "/search.lua")
local styles = dofile(spoonPath .. "/ui/styles.lua")
local slackUI = dofile(spoonPath .. "/ui/slack.lua")
slackUI.slackApi = slackApi
local openaiApi = dofile(spoonPath .. "/api/openai.lua")
openaiApi.getEnvVar = utils.getEnvVar
local aiChatUI = dofile(spoonPath .. "/ui/ai-chat.lua")
aiChatUI.openaiApi = openaiApi
aiChatUI.getEnvVar = utils.getEnvVar

-- Wire up fetch module dependencies
fetch.config = config
fetch.linearApi = linearApi
fetch.slackApi = slackApi
fetch.calendarApi = calendarApi
fetch.notionApi = notionApi

-- State
obj.canvas = nil
obj.visible = false
obj.cache = { projects = {}, calendar = {} }
obj.lastFetchDate = nil
obj.dailyTimer = nil
obj.clickableItems = {}
obj.currentView = "main"
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
obj.currentNotionTask = nil
obj.currentSlackMsg = nil
obj.currentSlackThread = nil
obj.currentSlackChannel = nil
obj.slackViewMode = "thread"
obj.slackHistoryCache = nil
obj.previousWindow = nil

-- Search state
obj.searchQuery = ""
obj.activeFilter = ""
obj.searchMode = nil  -- nil = default, "search" = fuzzy search, "llm" = LLM webview search

-- LLM model state
obj.currentLLMModel = "openai/gpt-4o-mini"
obj.showModelSelector = false
obj.modelFilter = ""

-- Available LLM models (synced with ai-chat.tsx)
local LLM_MODELS = {
	{ id = "openrouter/auto", name = "Auto (Best)", key = "a" },
	{ id = "openai/gpt-4o-mini", name = "GPT-4o Mini", key = "b" },
	{ id = "openai/gpt-4o", name = "GPT-4o", key = "c" },
	{ id = "anthropic/claude-3.5-haiku", name = "Claude 3.5 Haiku", key = "d" },
	{ id = "anthropic/claude-sonnet-4", name = "Claude Sonnet 4", key = "e" },
	{ id = "x-ai/grok-4.1-fast", name = "Grok 4.1 Fast", key = "f" },
	{ id = "google/gemini-2.0-flash-exp:free", name = "Gemini 2.0 Flash", key = "g" },
	{ id = "meta-llama/llama-3.3-70b-instruct", name = "Llama 3.3 70B", key = "h" },
	{ id = "deepseek/deepseek-chat", name = "DeepSeek V3", key = "i" },
	{ id = "qwen/qwen-2.5-72b-instruct", name = "Qwen 2.5 72B", key = "j" },
}

-- Helper to get model display name
local function getModelDisplayName(modelId)
	for _, m in ipairs(LLM_MODELS) do
		if m.id == modelId then
			return m.name
		end
	end
	return modelId:match("/(.+)") or modelId
end

-- Helper for fuzzy matching
local function fuzzyMatch(text, query)
	if not query or query == "" then return true end
	local lowerText = text:lower()
	local lowerQuery = query:lower()
	local queryIndex = 1
	for i = 1, #lowerText do
		if lowerText:sub(i, i) == lowerQuery:sub(queryIndex, queryIndex) then
			queryIndex = queryIndex + 1
		end
		if queryIndex > #lowerQuery then
			return true
		end
	end
	return false
end

-- Filter models by search query
local function filterModels(query)
	local filtered = {}
	for _, m in ipairs(LLM_MODELS) do
		if fuzzyMatch(m.name, query) or fuzzyMatch(m.id, query) then
			table.insert(filtered, m)
		end
	end
	return filtered
end

-- Cursor stubs
local function setHandCursor() end
local function resetCursor() end

-- Fetch all sources using new orchestrator
function obj:fetchAll(callback)
	fetch.fetchAll(function(data)
		self.cache = data
		self.lastFetchDate = os.date("%Y-%m-%d")
		callback(data)
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
	local searchBarHeight = 40
	local sectionSpacing = 16
	local groupSpacing = 8

	-- Apply search filter if active
	local displayData = data
	if self.activeFilter and self.activeFilter ~= "" then
		displayData = search.filterAll(data, self.activeFilter)
	end

	-- Get projects in order from config
	local projects = fetch.getProjectsInOrder(displayData)
	local calendarEvents = displayData.calendar or {}

	-- Group calendar events by date
	local calendarByDate, calendarDateOrder = calendarApi.groupByDate(calendarEvents)

	-- Two-column layout setup
	local boxWidth = 1400
	local columnGap = 32
	local columnWidth = (boxWidth - padding * 2 - columnGap) / 2
	local integrationHeaderHeight = fontSize + 12  -- H3 level
	local subHeaderHeight = fontSize + 8  -- H4 level

	-- Helper to calculate height for a project
	local function calcProjectHeight(project)
		local h = sectionHeaderHeight + 6  -- H2: Project name + margin
		local linearCount = #(project.data.linear or {})
		local notionCount = #(project.data.notion or {})
		local slackChannels = project.data.slack and project.data.slack.channels or {}
		local slackDms = project.data.slack and project.data.slack.dms or {}
		local slackCount = #slackChannels + #slackDms

		if linearCount > 0 then
			h = h + integrationHeaderHeight + (linearCount * lineHeight) + groupSpacing
		end
		if notionCount > 0 then
			h = h + integrationHeaderHeight + (notionCount * lineHeight) + groupSpacing
		end
		if slackCount > 0 then
			h = h + integrationHeaderHeight
			if #slackChannels > 0 then
				h = h + subHeaderHeight + (math.min(#slackChannels, 5) * lineHeight) + groupSpacing
			end
			if #slackDms > 0 then
				h = h + subHeaderHeight + (math.min(#slackDms, 5) * lineHeight) + groupSpacing
			end
		end
		if linearCount == 0 and notionCount == 0 and slackCount == 0 then
			h = h + lineHeight
		end
		h = h + sectionSpacing
		return h
	end

	-- Split projects into two columns
	-- When filtering: distribute evenly for natural flow
	-- When not filtering: Fuse on left, others on right
	local leftProjects = {}
	local rightProjects = {}
	local hasActiveFilter = self.activeFilter and self.activeFilter ~= ""

	if hasActiveFilter then
		-- Collect only projects with items, then distribute evenly
		local activeProjects = {}
		for _, project in ipairs(projects) do
			if search.projectHasItems(project.data) then
				table.insert(activeProjects, project)
			end
		end
		-- Distribute evenly between columns
		for i, project in ipairs(activeProjects) do
			if i % 2 == 1 then
				table.insert(leftProjects, project)
			else
				table.insert(rightProjects, project)
			end
		end
	else
		-- Default: Fuse on left, others on right
		for _, project in ipairs(projects) do
			if project.id == "fuse" then
				table.insert(leftProjects, project)
			else
				table.insert(rightProjects, project)
			end
		end
	end

	-- Calculate column heights
	local leftHeight = 0
	for _, project in ipairs(leftProjects) do
		leftHeight = leftHeight + calcProjectHeight(project)
	end
	local rightHeight = 0
	for _, project in ipairs(rightProjects) do
		rightHeight = rightHeight + calcProjectHeight(project)
	end

	-- Calculate content height
	local contentHeight = padding + searchBarHeight + sectionSpacing

	-- Calendar section height (full width)
	if #calendarEvents > 0 then
		contentHeight = contentHeight + sectionHeaderHeight
		for _, dateStr in ipairs(calendarDateOrder) do
			contentHeight = contentHeight + groupHeaderHeight
			contentHeight = contentHeight + (#calendarByDate[dateStr] * lineHeight)
		end
		contentHeight = contentHeight + sectionSpacing
	end

	-- Projects in two columns - use max height
	contentHeight = contentHeight + math.max(leftHeight, rightHeight)
	contentHeight = contentHeight + padding
	local screen = hs.screen.mainScreen()
	local frame = screen:frame()
	local maxHeight = frame.h - 100
	contentHeight = math.min(contentHeight, maxHeight)

	local boxX = frame.x + (frame.w - boxWidth) / 2
	local boxY = frame.y + (frame.h - contentHeight) / 2

	if self.canvas then
		self.canvas:delete()
	end

	self.canvas = hs.canvas.new({ x = boxX, y = boxY, w = boxWidth, h = contentHeight })
	self.canvasFrame = { x = boxX, y = boxY, w = boxWidth, h = contentHeight }
	self.lastCanvasSize = { w = boxWidth, h = contentHeight }
	local c = self.canvas

	-- Background
	c[1] = { type = "rectangle", action = "fill", fillColor = { hex = "#1a1a1a", alpha = 0.95 }, roundedRectRadii = { xRadius = 10, yRadius = 10 } }
	c[2] = { type = "rectangle", action = "stroke", strokeColor = { hex = "#5e6ad2", alpha = 0.9 }, strokeWidth = 2, roundedRectRadii = { xRadius = 10, yRadius = 10 } }

	-- Search bar
	local searchY = padding
	local searchText = self.searchQuery ~= "" and self.searchQuery or (self.activeFilter ~= "" and self.activeFilter or "")
	local searchPlaceholder, searchColor, borderColor
	local modelIndicatorWidth = 180  -- Width for model indicator when in LLM mode
	local searchBarWidth = boxWidth - padding * 2
	local showModelIndicator = false

	if self.searchMode == "search" then
		searchPlaceholder = searchText ~= "" and searchText or ""
		searchColor = "#e0e0e0"
		borderColor = "#f97316"  -- Orange when search mode active
	elseif self.searchMode == "llm" then
		searchPlaceholder = self.showModelSelector and (self.modelFilter ~= "" and self.modelFilter or "Search models...") or (searchText ~= "" and searchText or "Ask AI...")
		searchColor = "#e0e0e0"
		borderColor = "#8b5cf6"  -- Purple for LLM mode
		showModelIndicator = true
		searchBarWidth = boxWidth - padding * 2 - modelIndicatorWidth - 8  -- Make room for model indicator
	elseif self.activeFilter ~= "" then
		searchPlaceholder = self.activeFilter
		searchColor = "#f97316"  -- Orange for active filter text
		borderColor = "#f97316"
	else
		searchPlaceholder = "[s] search  /  [S] AI"
		searchColor = "#555555"
		borderColor = "#333333"
	end

	-- Search bar background
	c[#c + 1] = { type = "rectangle", action = "fill", fillColor = { hex = "#252525", alpha = 1 }, roundedRectRadii = { xRadius = 6, yRadius = 6 }, frame = { x = padding, y = searchY, w = searchBarWidth, h = searchBarHeight - 8 } }
	c[#c + 1] = { type = "rectangle", action = "stroke", strokeColor = { hex = borderColor, alpha = 0.6 }, strokeWidth = 1, roundedRectRadii = { xRadius = 6, yRadius = 6 }, frame = { x = padding, y = searchY, w = searchBarWidth, h = searchBarHeight - 8 } }
	c[#c + 1] = { type = "text", text = searchPlaceholder, textFont = font, textSize = fontSize, textColor = { hex = searchColor, alpha = 1 }, textAlignment = "left", frame = { x = padding + 12, y = searchY + 6, w = searchBarWidth - 24, h = fontSize + 4 } }

	-- Model indicator (shown when in LLM mode)
	if showModelIndicator then
		local modelIndicatorX = padding + searchBarWidth + 8
		local modelName = getModelDisplayName(self.currentLLMModel)
		local hotkeyBadgeWidth = 32
		local modelNameWidth = modelIndicatorWidth - hotkeyBadgeWidth - 20

		-- Model indicator background
		c[#c + 1] = { type = "rectangle", action = "fill", fillColor = { hex = "#2a2a2a", alpha = 1 }, roundedRectRadii = { xRadius = 6, yRadius = 6 }, frame = { x = modelIndicatorX, y = searchY, w = modelIndicatorWidth, h = searchBarHeight - 8 } }
		c[#c + 1] = { type = "rectangle", action = "stroke", strokeColor = { hex = "#8b5cf6", alpha = 0.4 }, strokeWidth = 1, roundedRectRadii = { xRadius = 6, yRadius = 6 }, frame = { x = modelIndicatorX, y = searchY, w = modelIndicatorWidth, h = searchBarHeight - 8 } }

		-- Model name
		c[#c + 1] = { type = "text", text = modelName, textFont = font, textSize = fontSize - 1, textColor = { hex = "#888888", alpha = 1 }, textAlignment = "left", frame = { x = modelIndicatorX + 8, y = searchY + 7, w = modelNameWidth, h = fontSize + 2 } }

		-- Shift+Space hotkey badge
		c[#c + 1] = { type = "rectangle", action = "fill", fillColor = { hex = "#333333", alpha = 1 }, roundedRectRadii = { xRadius = 4, yRadius = 4 }, frame = { x = modelIndicatorX + modelIndicatorWidth - hotkeyBadgeWidth - 6, y = searchY + 4, w = hotkeyBadgeWidth, h = searchBarHeight - 16 } }
		c[#c + 1] = { type = "text", text = "⇧␣", textFont = font, textSize = fontSize - 2, textColor = { hex = "#8b5cf6", alpha = 1 }, textAlignment = "center", frame = { x = modelIndicatorX + modelIndicatorWidth - hotkeyBadgeWidth - 6, y = searchY + 6, w = hotkeyBadgeWidth, h = fontSize } }
	end

	-- Hover placeholder
	c[#c + 1] = { type = "rectangle", action = "fill", fillColor = { hex = "#ffffff", alpha = 0 }, frame = { x = 0, y = 0, w = 0, h = 0 } }

	local yPos = padding + searchBarHeight + sectionSpacing

	-- Model selector list (replaces content when active)
	if self.showModelSelector and self.searchMode == "llm" then
		local filteredModels = filterModels(self.modelFilter)
		local modelLineHeight = lineHeight + 8

		if #filteredModels > 0 then
			for i, model in ipairs(filteredModels) do
				local isActive = model.id == self.currentLLMModel

				-- Model item background (highlight if active)
				if isActive then
					c[#c + 1] = { type = "rectangle", action = "fill", fillColor = { hex = "#2a2a2a", alpha = 1 }, roundedRectRadii = { xRadius = 6, yRadius = 6 }, frame = { x = padding, y = yPos, w = boxWidth - padding * 2, h = modelLineHeight } }
					c[#c + 1] = { type = "rectangle", action = "stroke", strokeColor = { hex = "#8b5cf6", alpha = 0.6 }, strokeWidth = 1, roundedRectRadii = { xRadius = 6, yRadius = 6 }, frame = { x = padding, y = yPos, w = boxWidth - padding * 2, h = modelLineHeight } }
				end

				-- Hotkey badge
				c[#c + 1] = { type = "rectangle", action = "fill", fillColor = { hex = "#333333", alpha = 1 }, roundedRectRadii = { xRadius = 4, yRadius = 4 }, frame = { x = padding + 12, y = yPos + 6, w = 28, h = modelLineHeight - 12 } }
				c[#c + 1] = { type = "text", text = model.key, textFont = font, textSize = fontSize - 1, textColor = { hex = "#8b5cf6", alpha = 1 }, textAlignment = "center", frame = { x = padding + 12, y = yPos + 8, w = 28, h = fontSize } }

				-- Model name
				c[#c + 1] = { type = "text", text = model.name, textFont = font, textSize = fontSize, textColor = { hex = "#e0e0e0", alpha = 1 }, textAlignment = "left", frame = { x = padding + 52, y = yPos + 8, w = boxWidth - padding * 2 - 100, h = fontSize + 4 } }

				-- Active indicator
				if isActive then
					c[#c + 1] = { type = "text", text = "*", textFont = font, textSize = fontSize + 2, textColor = { hex = "#8b5cf6", alpha = 1 }, textAlignment = "right", frame = { x = boxWidth - padding - 30, y = yPos + 6, w = 20, h = fontSize + 4 } }
				end

				-- Add clickable item for this model
				table.insert(self.clickableItems, {
					type = "llm-model",
					y = yPos,
					h = modelLineHeight,
					x = padding,
					w = boxWidth - padding * 2,
					data = model,
					key = model.key
				})
				self.keyMap[model.key] = #self.clickableItems

				yPos = yPos + modelLineHeight + 4
			end
		else
			-- No models match filter
			c[#c + 1] = { type = "text", text = "No models match \"" .. self.modelFilter .. "\"", textFont = font, textSize = fontSize, textColor = { hex = "#666666", alpha = 1 }, textAlignment = "center", frame = { x = padding, y = yPos + 20, w = boxWidth - padding * 2, h = fontSize + 4 } }
		end

		-- Skip the rest of the content rendering
		c:level(hs.canvas.windowLevels.overlay)
		c:clickActivating(false)
		c:behaviorAsLabels({ "canJoinAllSpaces", "stationary" })
		c:show()
		self.visible = true
		if not self.escapeWatcher then
			self:setupEventHandlers()
		end
		return
	end

	-- Calendar section
	if #calendarEvents > 0 then
		c[#c + 1] = { type = "text", text = "Calendar", textFont = font, textSize = fontSize + 2, textColor = { hex = "#10b981", alpha = 1 }, textAlignment = "left", frame = { x = padding, y = yPos, w = boxWidth - padding * 2, h = sectionHeaderHeight } }
		yPos = yPos + sectionHeaderHeight

		for _, dateStr in ipairs(calendarDateOrder) do
			local dateLabel = calendarApi.formatDate(dateStr)
			c[#c + 1] = { type = "text", text = dateLabel, textFont = font, textSize = fontSize, textColor = { hex = "#f97316", alpha = 1 }, textAlignment = "left", frame = { x = padding + 12, y = yPos, w = boxWidth - padding * 2, h = groupHeaderHeight } }
			yPos = yPos + groupHeaderHeight

			for _, event in ipairs(calendarByDate[dateStr]) do
				itemIndex = itemIndex + 1
				local shortcut = utils.getShortcutKey(itemIndex)

				if event.meetingUrl then
					table.insert(self.clickableItems, {
						type = "calendar",
						y = yPos,
						h = lineHeight,
						x = padding,
						w = boxWidth - padding * 2,
						data = event,
						key = shortcut
					})
					if shortcut then self.keyMap[shortcut] = #self.clickableItems end
				end

				local timeDisplay = event.displayTime or ""
				local title = event.title or ""
				local maxTitleChars = 50
				if #title > maxTitleChars then title = title:sub(1, maxTitleChars - 1) .. "..." end

				local shortcutDisplay = event.meetingUrl and (shortcut or "") or ""
				local shortcutColor = event.meetingUrl and "#10b981" or "#666666"
				local titleColor = event.isToday and "#ffffff" or "#aaaaaa"

				c[#c + 1] = { type = "text", text = shortcutDisplay, textFont = font, textSize = fontSize, textColor = { hex = shortcutColor, alpha = 1 }, textAlignment = "center", frame = { x = padding, y = yPos, w = 20, h = lineHeight } }
				c[#c + 1] = { type = "text", text = timeDisplay, textFont = font, textSize = fontSize, textColor = { hex = "#8b8b8b", alpha = 1 }, textAlignment = "left", frame = { x = padding + 28, y = yPos, w = 110, h = lineHeight } }
				c[#c + 1] = { type = "text", text = title, textFont = font, textSize = fontSize, textColor = { hex = titleColor, alpha = 1 }, textAlignment = "left", frame = { x = padding + 145, y = yPos, w = boxWidth - padding * 2 - 165, h = lineHeight } }

				if event.meetingUrl then
					c[#c + 1] = { type = "text", text = "video", textFont = font, textSize = fontSize - 2, textColor = { hex = "#10b981", alpha = 1 }, textAlignment = "right", frame = { x = boxWidth - padding - 50, y = yPos, w = 45, h = lineHeight } }
				end

				yPos = yPos + lineHeight
			end
		end
		yPos = yPos + sectionSpacing
	end

	-- Two-column project rendering
	local leftColX = padding
	local rightColX = padding + columnWidth + columnGap
	local projectsStartY = yPos

	-- Helper function to render a project at a given x position
	local function renderProject(project, colX, colY)
		local localY = colY
		local linearIssues = project.data.linear or {}
		local notionTasks = project.data.notion or {}
		local slackChannels = project.data.slack and project.data.slack.channels or {}
		local slackDms = project.data.slack and project.data.slack.dms or {}
		local slackToken = project.data.slack and project.data.slack._token or nil
		local slackCount = #slackChannels + #slackDms

		-- H2: Project header with color indicator
		c[#c + 1] = { type = "rectangle", action = "fill", fillColor = { hex = project.color, alpha = 1 }, frame = { x = colX, y = localY + 4, w = 4, h = fontSize } }
		c[#c + 1] = { type = "text", text = project.name, textFont = font, textSize = fontSize + 4, textColor = { hex = "#ffffff", alpha = 1 }, textAlignment = "left", frame = { x = colX + 12, y = localY, w = columnWidth - 12, h = sectionHeaderHeight } }
		localY = localY + sectionHeaderHeight + 6  -- Added margin under project name

		-- Show "No items" if no data
		if #linearIssues == 0 and #notionTasks == 0 and slackCount == 0 then
			c[#c + 1] = { type = "text", text = "No items", textFont = font, textSize = fontSize, textColor = { hex = "#666666", alpha = 1 }, textAlignment = "left", frame = { x = colX, y = localY, w = columnWidth, h = lineHeight } }
			localY = localY + lineHeight
		end

		-- H3: Linear integration
		if #linearIssues > 0 then
			c[#c + 1] = { type = "text", text = "Linear", textFont = font, textSize = fontSize + 1, textColor = { hex = "#5e6ad2", alpha = 1 }, textAlignment = "left", frame = { x = colX, y = localY, w = columnWidth, h = integrationHeaderHeight } }
			localY = localY + integrationHeaderHeight

			for _, issue in ipairs(linearIssues) do
				itemIndex = itemIndex + 1
				local shortcut = utils.getShortcutKey(itemIndex)

				table.insert(self.clickableItems, {
					type = "linear",
					y = localY,
					h = lineHeight,
					x = colX,
					w = columnWidth,
					data = issue,
					key = shortcut
				})
				if shortcut then self.keyMap[shortcut] = #self.clickableItems end

				local title = issue.title or ""
				local maxChars = 45
				if #title > maxChars then title = title:sub(1, maxChars - 1) .. "..." end

				c[#c + 1] = { type = "text", text = shortcut or "", textFont = font, textSize = fontSize, textColor = { hex = "#5e6ad2", alpha = 1 }, textAlignment = "center", frame = { x = colX, y = localY, w = 20, h = lineHeight } }
				c[#c + 1] = { type = "text", text = issue.identifier, textFont = font, textSize = fontSize, textColor = { hex = "#8b8b8b", alpha = 1 }, textAlignment = "left", frame = { x = colX + 24, y = localY, w = 80, h = lineHeight } }
				c[#c + 1] = { type = "text", text = title, textFont = font, textSize = fontSize, textColor = { hex = "#ffffff", alpha = 1 }, textAlignment = "left", frame = { x = colX + 108, y = localY, w = columnWidth - 120, h = lineHeight } }

				localY = localY + lineHeight
			end
			localY = localY + groupSpacing
		end

		-- H3: Notion integration
		if #notionTasks > 0 then
			c[#c + 1] = { type = "text", text = "Notion", textFont = font, textSize = fontSize + 1, textColor = { hex = "#c9a67a", alpha = 1 }, textAlignment = "left", frame = { x = colX, y = localY, w = columnWidth, h = integrationHeaderHeight } }
			localY = localY + integrationHeaderHeight

			for _, task in ipairs(notionTasks) do
				itemIndex = itemIndex + 1
				local shortcut = utils.getShortcutKey(itemIndex)

				table.insert(self.clickableItems, {
					type = "notion",
					y = localY,
					h = lineHeight,
					x = colX,
					w = columnWidth,
					data = task,
					key = shortcut
				})
				if shortcut then self.keyMap[shortcut] = #self.clickableItems end

				local title = task.title or ""
				local maxChars = 45
				if #title > maxChars then title = title:sub(1, maxChars - 1) .. "..." end

				c[#c + 1] = { type = "text", text = shortcut or "", textFont = font, textSize = fontSize, textColor = { hex = "#c9a67a", alpha = 1 }, textAlignment = "center", frame = { x = colX, y = localY, w = 20, h = lineHeight } }
				c[#c + 1] = { type = "text", text = task.identifier, textFont = font, textSize = fontSize, textColor = { hex = "#8b8b8b", alpha = 1 }, textAlignment = "left", frame = { x = colX + 24, y = localY, w = 80, h = lineHeight } }
				c[#c + 1] = { type = "text", text = title, textFont = font, textSize = fontSize, textColor = { hex = "#ffffff", alpha = 1 }, textAlignment = "left", frame = { x = colX + 108, y = localY, w = columnWidth - 120, h = lineHeight } }

				localY = localY + lineHeight
			end
			localY = localY + groupSpacing
		end

		-- H3: Slack integration
		if slackCount > 0 then
			c[#c + 1] = { type = "text", text = "Slack", textFont = font, textSize = fontSize + 1, textColor = { hex = "#e01e5a", alpha = 1 }, textAlignment = "left", frame = { x = colX, y = localY, w = columnWidth, h = integrationHeaderHeight } }
			localY = localY + integrationHeaderHeight

			-- H4: Mentions
			if #slackChannels > 0 then
				c[#c + 1] = { type = "text", text = "Mentions (" .. #slackChannels .. ")", textFont = font, textSize = fontSize - 1, textColor = { hex = "#888888", alpha = 1 }, textAlignment = "left", frame = { x = colX, y = localY, w = columnWidth, h = subHeaderHeight } }
				localY = localY + subHeaderHeight

				for i, msg in ipairs(slackChannels) do
					if i > 5 then break end
					itemIndex = itemIndex + 1
					local shortcut = utils.getShortcutKey(itemIndex)

					table.insert(self.clickableItems, {
						type = "slack",
						y = localY,
						h = lineHeight,
						x = colX,
						w = columnWidth,
						data = msg,
						key = shortcut,
						_token = slackToken
					})
					if shortcut then self.keyMap[shortcut] = #self.clickableItems end

					local from = msg.username or "unknown"
					local channel = msg.channel and msg.channel.name or ""
					local text = msg.text or ""
					text = text:gsub("<@[^>]+[^>]*>", ""):gsub("<[^>]+>", ""):gsub("%s+", " "):gsub("^%s+", "")
					local maxChars = 35
					if #text > maxChars then text = text:sub(1, maxChars - 1) .. "..." end

					c[#c + 1] = { type = "text", text = shortcut or "", textFont = font, textSize = fontSize, textColor = { hex = "#e01e5a", alpha = 1 }, textAlignment = "center", frame = { x = colX, y = localY, w = 20, h = lineHeight } }
					c[#c + 1] = { type = "text", text = "#" .. channel, textFont = font, textSize = fontSize, textColor = { hex = "#8b8b8b", alpha = 1 }, textAlignment = "left", frame = { x = colX + 24, y = localY, w = 80, h = lineHeight } }
					c[#c + 1] = { type = "text", text = from .. ": " .. text, textFont = font, textSize = fontSize, textColor = { hex = "#ffffff", alpha = 1 }, textAlignment = "left", frame = { x = colX + 108, y = localY, w = columnWidth - 120, h = lineHeight } }

					localY = localY + lineHeight
				end
				localY = localY + groupSpacing
			end

			-- H4: DMs
			if #slackDms > 0 then
				c[#c + 1] = { type = "text", text = "DMs (" .. #slackDms .. ")", textFont = font, textSize = fontSize - 1, textColor = { hex = "#888888", alpha = 1 }, textAlignment = "left", frame = { x = colX, y = localY, w = columnWidth, h = subHeaderHeight } }
				localY = localY + subHeaderHeight

				for i, msg in ipairs(slackDms) do
					if i > 5 then break end
					itemIndex = itemIndex + 1
					local shortcut = utils.getShortcutKey(itemIndex)

					table.insert(self.clickableItems, {
						type = "slack",
						y = localY,
						h = lineHeight,
						x = colX,
						w = columnWidth,
						data = msg,
						key = shortcut,
						_token = slackToken
					})
					if shortcut then self.keyMap[shortcut] = #self.clickableItems end

					local from = msg.username or "unknown"
					local text = msg.text or ""
					text = text:gsub("<@[^>]+[^>]*>", ""):gsub("<[^>]+>", ""):gsub("%s+", " "):gsub("^%s+", "")
					local maxChars = 40
					if #text > maxChars then text = text:sub(1, maxChars - 1) .. "..." end

					c[#c + 1] = { type = "text", text = shortcut or "", textFont = font, textSize = fontSize, textColor = { hex = "#e01e5a", alpha = 1 }, textAlignment = "center", frame = { x = colX, y = localY, w = 20, h = lineHeight } }
					c[#c + 1] = { type = "text", text = from, textFont = font, textSize = fontSize, textColor = { hex = "#8b8b8b", alpha = 1 }, textAlignment = "left", frame = { x = colX + 24, y = localY, w = 80, h = lineHeight } }
					c[#c + 1] = { type = "text", text = text, textFont = font, textSize = fontSize, textColor = { hex = "#ffffff", alpha = 1 }, textAlignment = "left", frame = { x = colX + 108, y = localY, w = columnWidth - 120, h = lineHeight } }

					localY = localY + lineHeight
				end
				localY = localY + groupSpacing
			end
		end

		return localY + sectionSpacing
	end

	-- Render left column projects
	local leftY = projectsStartY
	for _, project in ipairs(leftProjects) do
		leftY = renderProject(project, leftColX, leftY)
	end

	-- Render right column projects
	local rightY = projectsStartY
	for _, project in ipairs(rightProjects) do
		rightY = renderProject(project, rightColX, rightY)
	end

	yPos = math.max(leftY, rightY)

	c:level(hs.canvas.windowLevels.overlay)
	c:clickActivating(false)
	c:behaviorAsLabels({ "canJoinAllSpaces", "stationary" })
	c:show()
	self.visible = true
	-- Only setup handlers if not already active (avoid recreating during typing)
	if not self.escapeWatcher then
		self:setupEventHandlers()
	end
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
	if canScrollUp and canScrollDown then scrollHint = "↑↓"
	elseif canScrollUp then scrollHint = "↑"
	elseif canScrollDown then scrollHint = "↓"
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

function obj:renderNotionDetail(task, resetScroll)
	if self.loadingTimer then
		self.loadingTimer:stop()
		self.loadingTimer = nil
	end

	if task then
		self.currentNotionTask = task
	else
		task = self.currentNotionTask
	end
	if not task then return end

	if resetScroll ~= false then
		self.scrollOffset = 0
	end

	self.currentView = "notion-detail"
	self.clickableItems = {}
	self.hoveredIndex = nil
	self.keyMap = {}
	self.keyMap["b"] = 1
	self.keyMap["o"] = 2

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
	c[2] = { type = "rectangle", action = "stroke", strokeColor = { hex = "#c9a67a", alpha = 0.9 }, strokeWidth = 2, roundedRectRadii = { xRadius = 10, yRadius = 10 } }

	table.insert(self.clickableItems, { type = "back", y = padding, h = 30, x = padding, w = 90, key = "b" })
	c[3] = { type = "text", text = "b", textFont = font, textSize = fontSize, textColor = { hex = "#c9a67a", alpha = 1 }, textAlignment = "left", frame = { x = padding, y = padding, w = 16, h = 30 } }
	c[4] = { type = "text", text = "<- Back", textFont = font, textSize = fontSize, textColor = { hex = "#888888", alpha = 1 }, textAlignment = "left", frame = { x = padding + 20, y = padding, w = 70, h = 30 } }

	-- Open in Notion button
	table.insert(self.clickableItems, { type = "open-notion", y = padding, h = 30, x = boxWidth - padding - 140, w = 140, data = task, key = "o" })
	c[5] = { type = "text", text = "o", textFont = font, textSize = fontSize, textColor = { hex = "#c9a67a", alpha = 1 }, textAlignment = "right", frame = { x = boxWidth - padding - 140, y = padding, w = 16, h = 30 } }
	c[6] = { type = "text", text = "Open in Notion ->", textFont = font, textSize = fontSize, textColor = { hex = "#888888", alpha = 1 }, textAlignment = "right", frame = { x = boxWidth - padding - 120, y = padding, w = 120, h = 30 } }

	c[7] = { type = "rectangle", action = "fill", fillColor = { hex = "#ffffff", alpha = 0 }, frame = { x = 0, y = 0, w = 0, h = 0 } }

	local titleY = padding + 10
	c[#c + 1] = { type = "text", text = task.identifier, textFont = font, textSize = fontSize + 2, textColor = { hex = "#8b8b8b", alpha = 1 }, textAlignment = "center", frame = { x = padding, y = titleY, w = boxWidth - (padding * 2), h = 30 } }

	local clipTop = padding + 45
	local clipHeight = boxHeight - clipTop - footerHeight - 8
	c[#c + 1] = { type = "rectangle", action = "clip", frame = { x = 0, y = clipTop, w = boxWidth, h = clipHeight } }

	local scrollY = -self.scrollOffset
	local yPos = clipTop + 5 + scrollY

	c[#c + 1] = { type = "text", text = task.title or "Untitled", textFont = font, textSize = fontSize + 6, textColor = { hex = "#ffffff", alpha = 1 }, textAlignment = "left", frame = { x = padding, y = yPos, w = boxWidth - (padding * 2), h = 36 } }
	yPos = yPos + 40

	-- Render badges (domain + tags) inline
	local hasBadges = task.domain or (task.tags and #task.tags > 0)
	if hasBadges then
		local badgeX = padding
		local badgeFontSize = 11
		local badgePadding = 8
		local badgeGap = 6
		local badgeHeight = 18

		-- Collect all badges (domain first, then tags)
		local allBadges = {}
		if task.domain then
			table.insert(allBadges, task.domain)
		end
		for _, tag in ipairs(task.tags or {}) do
			table.insert(allBadges, tag)
		end

		-- Render each badge
		for _, badge in ipairs(allBadges) do
			local badgeWidth = #badge * 7 + badgePadding * 2
			-- Badge background
			c[#c + 1] = { type = "rectangle", action = "fill", fillColor = { hex = "#3a3a3a", alpha = 1 }, roundedRectRadii = { xRadius = 4, yRadius = 4 }, frame = { x = badgeX, y = yPos, w = badgeWidth, h = badgeHeight } }
			-- Badge text
			c[#c + 1] = { type = "text", text = badge, textFont = font, textSize = badgeFontSize, textColor = { hex = "#a0a0a0", alpha = 1 }, textAlignment = "center", frame = { x = badgeX, y = yPos + 2, w = badgeWidth, h = badgeHeight - 2 } }
			badgeX = badgeX + badgeWidth + badgeGap
		end
		yPos = yPos + badgeHeight + 12
	end

	local status = task.status or "Unknown"
	c[#c + 1] = { type = "text", text = status, textFont = font, textSize = fontSize, textColor = { hex = "#f97316", alpha = 1 }, textAlignment = "left", frame = { x = padding, y = yPos, w = boxWidth - (padding * 2), h = lineHeight } }
	yPos = yPos + lineHeight + 16

	c[#c + 1] = { type = "rectangle", action = "fill", fillColor = { hex = "#444444", alpha = 1 }, frame = { x = padding, y = yPos, w = boxWidth - (padding * 2), h = 1 } }
	yPos = yPos + 20

	c[#c + 1] = { type = "text", text = "Content", textFont = font, textSize = fontSize, textColor = { hex = "#c9a67a", alpha = 1 }, textAlignment = "left", frame = { x = padding, y = yPos, w = boxWidth - (padding * 2), h = lineHeight } }
	yPos = yPos + lineHeight + 4

	local content = task.content or "(No content)"
	if #content > 3000 then content = content:sub(1, 3000) .. "..." end
	-- Better height calculation: count actual newlines and estimate wrapped lines
	local contentWidth = boxWidth - (padding * 2)
	local charsPerLine = math.floor(contentWidth / 8)  -- ~8px per char at fontSize - 1 (13px)
	local lineCount = 0
	-- Count actual lines by splitting on newlines
	for line in (content .. "\n"):gmatch("([^\n]*)\n") do
		-- Each actual line may wrap based on its length
		lineCount = lineCount + math.max(1, math.ceil(#line / charsPerLine))
	end
	local contentLineHeight = 18  -- line height for content text
	local contentHeight = math.max(100, lineCount * contentLineHeight + 20)  -- Add some padding
	c[#c + 1] = { type = "text", text = content, textFont = font, textSize = fontSize - 1, textColor = { hex = "#cccccc", alpha = 1 }, textAlignment = "left", frame = { x = padding, y = yPos, w = contentWidth, h = contentHeight } }
	yPos = yPos + contentHeight + 20

	self.contentHeight = yPos + self.scrollOffset - padding
	self.viewHeight = boxHeight - contentTop - footerHeight - 8

	c[#c + 1] = { type = "resetClip" }

	local footerY = boxHeight - footerHeight
	c[#c + 1] = { type = "rectangle", action = "fill", fillColor = { hex = "#252525", alpha = 1 }, frame = { x = 0, y = footerY, w = boxWidth, h = footerHeight } }
	c[#c + 1] = { type = "rectangle", action = "fill", fillColor = { hex = "#444444", alpha = 1 }, frame = { x = padding, y = footerY, w = boxWidth - (padding * 2), h = 1 } }

	local hintY = footerY + 10
	local hintSize = fontSize - 2
	local keyColor = { hex = "#c9a67a", alpha = 1 }
	local textColor = { hex = "#666666", alpha = 1 }

	local canScrollUp = self.scrollOffset > 0
	local canScrollDown = self.contentHeight > self.viewHeight + self.scrollOffset
	local scrollHint = ""
	if canScrollUp and canScrollDown then scrollHint = "↑↓"
	elseif canScrollUp then scrollHint = "↑"
	elseif canScrollDown then scrollHint = "↓"
	end

	local xPos = padding
	c[#c + 1] = { type = "text", text = "j/k", textFont = font, textSize = hintSize, textColor = keyColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 30, h = 20 } }
	xPos = xPos + 32
	c[#c + 1] = { type = "text", text = "scroll " .. scrollHint, textFont = font, textSize = hintSize, textColor = textColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 80, h = 20 } }
	xPos = xPos + 90
	c[#c + 1] = { type = "text", text = "b", textFont = font, textSize = hintSize, textColor = keyColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 14, h = 20 } }
	xPos = xPos + 16
	c[#c + 1] = { type = "text", text = "back", textFont = font, textSize = hintSize, textColor = textColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 40, h = 20 } }
	xPos = xPos + 60
	c[#c + 1] = { type = "text", text = "o", textFont = font, textSize = hintSize, textColor = keyColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 14, h = 20 } }
	xPos = xPos + 16
	c[#c + 1] = { type = "text", text = "open", textFont = font, textSize = hintSize, textColor = textColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 40, h = 20 } }
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
	if self.paginationInProgress then
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
			selfRef:hide()
		end,
		onChannelUp = function()
			if selfRef.currentSlackChannel then
				if selfRef.slackHistoryCache and #selfRef.slackHistoryCache > 0 then
					slackUI.switchView(selfRef, "history", selfRef.slackHistoryCache)
				else
					slackApi.fetchHistoryWithConfig(selfRef.currentSlackChannel, { token = selfRef.currentSlackToken }, function(messages, err)
						slackUI.switchView(selfRef, "history", messages)
					end)
				end
			end
		end,
		onThreadClick = function(threadTs)
			if selfRef.slackViewMode == "history" and selfRef.currentSlackThread then
				selfRef.slackHistoryCache = selfRef.currentSlackThread
			end
			local channelId = selfRef.currentSlackMsg.channel and selfRef.currentSlackMsg.channel.id
			if channelId and threadTs then
				slackApi.fetchThreadWithConfig(channelId, threadTs, { token = selfRef.currentSlackToken }, function(threadMsgs, err)
					slackUI.switchView(selfRef, "thread", threadMsgs)
				end)
			end
		end,
		onLoadMore = function()
			selfRef.paginationInProgress = true
			local channelId = selfRef.currentSlackChannel
			if not channelId then
				selfRef.paginationInProgress = false
				slackUI.resetLoadingFlag(selfRef)
				return
			end

			local oldestTs = nil
			if selfRef.currentSlackThread and #selfRef.currentSlackThread > 0 then
				oldestTs = selfRef.currentSlackThread[1].ts
			end

			slackApi.fetchHistoryWithConfig(channelId, { token = selfRef.currentSlackToken }, function(olderMessages, err)
				if olderMessages and #olderMessages > 0 then
					local combined = {}
					for _, m in ipairs(olderMessages) do
						table.insert(combined, m)
					end
					for _, m in ipairs(selfRef.currentSlackThread or {}) do
						table.insert(combined, m)
					end
					selfRef.currentSlackThread = combined
					selfRef.slackViewMode = "history"
					slackUI.prependMessages(selfRef, olderMessages)
				else
					slackUI.resetLoadingFlag(selfRef)
				end
				selfRef.paginationInProgress = false
			end, oldestTs)
		end,
	})
end

function obj:updateHover(index)
	if self.hoveredIndex == index then return end
	self.hoveredIndex = index

	if not self.canvas then return end

	-- Find the hover placeholder element (index 6 after search bar elements)
	local hoverIndex = 6
	if index and self.clickableItems[index] then
		local item = self.clickableItems[index]
		self.canvas[hoverIndex] = {
			type = "rectangle",
			action = "fill",
			fillColor = { hex = "#ffffff", alpha = 0.08 },
			roundedRectRadii = { xRadius = 4, yRadius = 4 },
			frame = { x = item.x or 24, y = item.y, w = item.w or 852, h = item.h }
		}
		setHandCursor()
	else
		self.canvas[hoverIndex] = {
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
	if self.scrollWatcher then
		self.scrollWatcher:stop()
	end

	local selfRef = self

	self.escapeWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
		local keyCode = event:getKeyCode()
		local char = event:getCharacters()
		local mods = event:getFlags()

		-- Let through keys with heavy modifier combinations (meh = ctrl+alt+shift, hyper = cmd+ctrl+alt+shift)
		-- These are typically system-level hotkeys that should always work
		local modCount = 0
		if mods.ctrl then modCount = modCount + 1 end
		if mods.alt then modCount = modCount + 1 end
		if mods.shift then modCount = modCount + 1 end
		if mods.cmd then modCount = modCount + 1 end
		if modCount >= 3 then
			return false  -- Let system hotkeys pass through
		end

		-- Cmd+Escape - emergency force close (always works)
		if keyCode == 53 and mods.cmd then
			selfRef:forceCleanup()
			return true
		end

		-- Escape key
		if keyCode == 53 then
			-- If in LLM mode with model selector open, close model selector first (stay in LLM mode)
			if selfRef.searchMode == "llm" and selfRef.showModelSelector then
				selfRef.showModelSelector = false
				selfRef.modelFilter = ""
				selfRef:render(selfRef.cache)
				return true
			end
			-- If in search mode, exit search mode (back to default)
			if selfRef.searchMode then
				selfRef.searchMode = nil
				selfRef.searchQuery = ""
				selfRef.showModelSelector = false
				selfRef.modelFilter = ""
				selfRef:render(selfRef.cache)
				return true
			end
			-- If filter active, clear it
			if selfRef.activeFilter ~= "" then
				selfRef.activeFilter = ""
				selfRef:render(selfRef.cache)
				return true
			end
			if selfRef.currentView == "linear-detail" or selfRef.currentView == "slack-detail" or selfRef.currentView == "notion-detail" then
				selfRef.scrollOffset = 0
				selfRef:render(selfRef.cache)
			else
				selfRef:hide()
			end
			return true
		end

		-- When in search mode, only handle search-related keys
		if selfRef.searchMode == "search" then
			-- Return/Enter key - apply search filter and exit search mode
			if keyCode == 36 then
				if selfRef.searchQuery ~= "" then
					selfRef.activeFilter = selfRef.searchQuery
				end
				selfRef.searchMode = nil
				selfRef:render(selfRef.cache)
				return true
			end

			-- Backspace key - remove last character from search
			if keyCode == 51 then
				if selfRef.searchQuery ~= "" then
					selfRef.searchQuery = selfRef.searchQuery:sub(1, -2)
					selfRef:render(selfRef.cache)
				end
				return true
			end

			-- Handle typing for search (regular characters, no modifiers)
			if char and #char == 1 and not mods.cmd and not mods.ctrl and not mods.alt then
				local charCode = char:byte()
				-- Allow alphanumeric, space, and common punctuation
				if (charCode >= 32 and charCode <= 126) then
					selfRef.searchQuery = selfRef.searchQuery .. char
					selfRef:render(selfRef.cache)
					return true
				end
			end

			-- Block all other keys in search mode
			return true
		end

		-- When in LLM search mode - open AI chat webview
		if selfRef.searchMode == "llm" then
			-- Model selector mode has different key handling
			if selfRef.showModelSelector then
				-- ESC is handled at the top of the event handler

				-- Enter key - select first filtered model
				if keyCode == 36 then
					local filtered = filterModels(selfRef.modelFilter)
					if #filtered > 0 then
						selfRef.currentLLMModel = filtered[1].id
						selfRef.showModelSelector = false
						selfRef.modelFilter = ""
						selfRef:render(selfRef.cache)
					end
					return true
				end

				-- Backspace key - remove last character from filter
				if keyCode == 51 then
					if selfRef.modelFilter ~= "" then
						selfRef.modelFilter = selfRef.modelFilter:sub(1, -2)
						selfRef:render(selfRef.cache)
					end
					return true
				end

				-- Letter keys for quick model selection (only when filter is empty)
				if selfRef.modelFilter == "" and char and char:match("^[a-j]$") then
					for _, model in ipairs(LLM_MODELS) do
						if model.key == char then
							selfRef.currentLLMModel = model.id
							selfRef.showModelSelector = false
							selfRef.modelFilter = ""
							selfRef:render(selfRef.cache)
							return true
						end
					end
				end

				-- Handle typing for model filter
				if char and #char == 1 and not mods.cmd and not mods.ctrl and not mods.alt then
					local charCode = char:byte()
					if (charCode >= 32 and charCode <= 126) then
						selfRef.modelFilter = selfRef.modelFilter .. char
						selfRef:render(selfRef.cache)
						return true
					end
				end

				-- Block all other keys in model selector
				return true
			end

			-- Shift+Space toggles model selector
			if keyCode == 49 and mods.shift and not mods.cmd and not mods.ctrl and not mods.alt then
				selfRef.showModelSelector = true
				selfRef.modelFilter = ""
				selfRef:render(selfRef.cache)
				return true
			end

			-- Return/Enter key - open AI chat with query and selected model
			if keyCode == 36 then
				local query = selfRef.searchQuery
				local model = selfRef.currentLLMModel
				-- Save the original window before we hide
				local originalWindow = selfRef.previousWindow
				selfRef.searchMode = nil
				selfRef.searchQuery = ""
				selfRef.showModelSelector = false
				selfRef.modelFilter = ""
				selfRef:hide()  -- Hide the main dashboard (clears previousWindow)
				-- Pass model to AI chat and sync it
				aiChatUI.currentModel = model
				-- Pass the original window so AI chat can restore focus to it
				aiChatUI.previousWindow = originalWindow
				aiChatUI.show(query, {
					onClose = function()
						-- "Back" pressed - get the original window before closing
						local windowToPass = aiChatUI.getPreviousWindow()
						-- Close AI chat WITHOUT restoring focus (we're going back to dashboard)
						aiChatUI.close(false)
						-- Re-show dashboard with original window preserved
						selfRef.previousWindow = windowToPass
						selfRef:show()
					end
				})
				return true
			end

			-- Backspace key - remove last character
			if keyCode == 51 then
				if selfRef.searchQuery ~= "" then
					selfRef.searchQuery = selfRef.searchQuery:sub(1, -2)
					selfRef:render(selfRef.cache)
				end
				return true
			end

			-- Handle typing
			if char and #char == 1 and not mods.cmd and not mods.ctrl and not mods.alt then
				local charCode = char:byte()
				if (charCode >= 32 and charCode <= 126) then
					selfRef.searchQuery = selfRef.searchQuery .. char
					selfRef:render(selfRef.cache)
					return true
				end
			end

			-- Block all other keys in LLM mode
			return true
		end

		-- Default mode (not in search mode)
		if selfRef.currentView == "main" then
			-- "s" activates search mode
			if char == "s" and not mods.shift and not mods.cmd and not mods.ctrl and not mods.alt then
				selfRef.searchMode = "search"
				selfRef.searchQuery = ""
				selfRef:render(selfRef.cache)
				return true
			end

			-- "S" activates LLM search mode
			if char == "S" and mods.shift and not mods.cmd and not mods.ctrl and not mods.alt then
				selfRef.searchMode = "llm"
				selfRef.searchQuery = ""
				selfRef:render(selfRef.cache)
				return true
			end
		end

		-- Scroll keys for linear-detail view
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

		-- Scroll keys for notion-detail view
		if selfRef.currentView == "notion-detail" then
			local scrollDown = (mods.ctrl and keyCode == 2) or (keyCode == 38)
			local scrollUp = (mods.ctrl and keyCode == 32) or (keyCode == 40)

			if scrollDown then
				local maxScroll = math.max(0, (selfRef.contentHeight or 0) - (selfRef.viewHeight or 400))
				selfRef.scrollOffset = math.min(selfRef.scrollOffset + 100, maxScroll)
				selfRef:renderNotionDetail(nil, false)
				return true
			end

			if scrollUp then
				selfRef.scrollOffset = math.max(0, selfRef.scrollOffset - 100)
				selfRef:renderNotionDetail(nil, false)
				return true
			end
		end

		-- Block all keys when in detail views (except those explicitly handled above)
		if selfRef.currentView == "linear-detail" or selfRef.currentView == "notion-detail" or selfRef.currentView == "slack-detail" then
			-- Handle specific shortcuts for detail views, then block all others
			if char and selfRef.keyMap[char] then
				local itemIdx = selfRef.keyMap[char]
				local item = selfRef.clickableItems[itemIdx]
				if item then
					if item.type == "back" then
						selfRef.scrollOffset = 0
						selfRef:render(selfRef.cache)
					elseif item.type == "open-notion" then
						if item.data and item.data.url then
							hs.urlevent.openURL(item.data.url)
							selfRef:hide()
						end
					end
				end
			end
			return true  -- Block all keys in detail views
		end

		-- Handle keyboard shortcuts for items in main view (only when not in search mode)
		if char and selfRef.keyMap[char] then
			local itemIdx = selfRef.keyMap[char]
			local item = selfRef.clickableItems[itemIdx]
			if item then
				if item.type == "calendar" then
					if item.data and item.data.meetingUrl then
						hs.urlevent.openURL(item.data.meetingUrl)
						selfRef:hide()
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
				elseif item.type == "notion" then
					selfRef:showLoader()
					local apiKey = item.data._apiKey
					if apiKey then
						notionApi.fetchDetail(item.data.id, apiKey, function(task, err)
							if task then
								selfRef:renderNotionDetail(task)
							else
								selfRef:render(selfRef.cache)
								hs.alert.show("Failed to load Notion page")
							end
						end)
					else
						selfRef:render(selfRef.cache)
						hs.alert.show("No API key for Notion page")
					end
				elseif item.type == "open-notion" then
					if item.data and item.data.url then
						hs.urlevent.openURL(item.data.url)
						selfRef:hide()
					end
				elseif item.type == "slack" then
					local channelId = item.data.channel and item.data.channel.id
					local isDM = item.data.channel and item.data.channel.is_im
					selfRef.currentSlackChannel = channelId

					local slackToken = item._token
					selfRef.currentSlackToken = slackToken
					if isDM and channelId then
						selfRef.slackViewMode = "history"
						selfRef:renderSlackDetail(item.data, {}, false, true)
						slackApi.fetchHistoryWithConfig(channelId, { token = slackToken }, function(messages, err)
							if err or not messages then
								selfRef:hide()
								hs.alert.show("Failed to load Slack history")
								return
							end
							slackUI.updateInitialMessages(selfRef, messages)
						end)
					else
						selfRef.slackViewMode = "thread"
						local threadTs = item.data.thread_ts or item.data.ts
						if channelId and threadTs then
							selfRef:renderSlackDetail(item.data, {}, false, true)
							slackApi.fetchThreadWithConfig(channelId, threadTs, { token = slackToken }, function(thread, err)
								if err or not thread then
									selfRef:hide()
									hs.alert.show("Failed to load Slack thread")
									return
								end
								slackUI.updateInitialMessages(selfRef, thread)
							end)
						else
							selfRef:hide()
							hs.alert.show("Missing channel or thread info")
						end
					end
				elseif item.type == "back" then
					selfRef.scrollOffset = 0
					selfRef:render(selfRef.cache)
				elseif item.type == "llm-model" then
					selfRef.currentLLMModel = item.data.id
					selfRef.showModelSelector = false
					selfRef.modelFilter = ""
					selfRef:render(selfRef.cache)
				end
			end
			return true
		end

		-- Let unhandled keys pass through (system shortcuts, etc.)
		return false
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
					elseif item.type == "calendar" then
						if relX >= item.x and relX <= item.x + item.w then
							if item.data and item.data.meetingUrl then
								hs.urlevent.openURL(item.data.meetingUrl)
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
					elseif item.type == "notion" then
						selfRef:showLoader()
						local apiKey = item.data._apiKey
						if apiKey then
							notionApi.fetchDetail(item.data.id, apiKey, function(task, err)
								if task then
									selfRef:renderNotionDetail(task)
								else
									selfRef:render(selfRef.cache)
									hs.alert.show("Failed to load Notion page")
								end
							end)
						else
							selfRef:render(selfRef.cache)
							hs.alert.show("No API key for Notion page")
						end
						return true
					elseif item.type == "open-notion" then
						if relX >= item.x and relX <= item.x + item.w then
							if item.data and item.data.url then
								hs.urlevent.openURL(item.data.url)
							end
							selfRef:hide()
							return true
						end
					elseif item.type == "slack" then
						selfRef:showLoader()
						local channelId = item.data.channel and item.data.channel.id
						local isDM = item.data.channel and item.data.channel.is_im
						selfRef.currentSlackChannel = channelId

						local slackToken = item._token
						selfRef.currentSlackToken = slackToken
						if isDM and channelId then
							selfRef.slackViewMode = "history"
							slackApi.fetchHistoryWithConfig(channelId, { token = slackToken }, function(messages, err)
								if err or not messages then
									selfRef:hide()
									hs.alert.show("Failed to load Slack history")
									return
								end
								selfRef:renderSlackDetail(item.data, messages)
							end)
						else
							selfRef.slackViewMode = "thread"
							local threadTs = item.data.thread_ts or item.data.ts
							if channelId and threadTs then
								slackApi.fetchThreadWithConfig(channelId, threadTs, { token = slackToken }, function(thread, err)
									if err or not thread then
										selfRef:hide()
										hs.alert.show("Failed to load Slack thread")
										return
									end
									selfRef:renderSlackDetail(item.data, thread)
								end)
							else
								selfRef:hide()
								hs.alert.show("Missing channel or thread info")
							end
						end
						return true
					elseif item.type == "llm-model" then
						if relX >= item.x and relX <= item.x + item.w then
							selfRef.currentLLMModel = item.data.id
							selfRef.showModelSelector = false
							selfRef.modelFilter = ""
							selfRef:render(selfRef.cache)
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

	self.scrollWatcher = hs.eventtap.new({ hs.eventtap.event.types.scrollWheel }, function(event)
		local mousePos = hs.mouse.absolutePosition()
		local frame = selfRef.canvasFrame
		if frame then
			local inside = mousePos.x >= frame.x and mousePos.x <= frame.x + frame.w
				and mousePos.y >= frame.y and mousePos.y <= frame.y + frame.h
			if inside then
				return false
			end
		end
		return true
	end)
	self.scrollWatcher:start()
end

function obj:show()
	-- Save the currently focused window to restore later (if not already set)
	if not self.previousWindow then
		self.previousWindow = hs.window.focusedWindow()
	end
	self.searchQuery = ""
	self.activeFilter = ""
	self.searchMode = nil
	self:showLoader()
	if self.cache.projects and next(self.cache.projects) and not self:needsFetch() then
		self:render(self.cache)
	else
		self:fetchAll(function(data)
			self:render(data)
		end)
	end
end

function obj:hide()
	resetCursor()
	if self.loadingTimer then
		self.loadingTimer:stop()
		self.loadingTimer = nil
	end
	slackUI.closeWebview(self)
	aiChatUI.close()  -- Also close AI chat if open
	if self.canvas then
		self.canvas:hide()
		self.canvas:delete()
		self.canvas = nil
	end
	self.visible = false
	-- Stop all eventtaps to release keyboard
	self:stopAllEventtaps()
	self.currentView = "main"
	self.clickableItems = {}
	self.canvasFrame = nil
	self.hoveredIndex = nil
	self.scrollOffset = 0
	self.currentIssue = nil
	self.currentNotionTask = nil
	self.currentSlackMsg = nil
	self.currentSlackThread = nil
	self.slackHistoryCache = nil
	self.searchQuery = ""
	self.activeFilter = ""
	self.searchMode = nil
	self.showModelSelector = false
	self.modelFilter = ""
	-- Restore focus to the previously focused window
	if self.previousWindow then
		self.previousWindow:focus()
		self.previousWindow = nil
	end
end

--- Stop all eventtaps to release keyboard control
function obj:stopAllEventtaps()
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
end

--- Force cleanup - call this if Attention gets stuck
function obj:forceCleanup()
	print("[Attention] Force cleanup triggered")
	self:stopAllEventtaps()
	slackUI.closeWebview(self)
	aiChatUI.close()
	if self.canvas then
		self.canvas:hide()
		self.canvas:delete()
		self.canvas = nil
	end
	self.visible = false
	resetCursor()
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
