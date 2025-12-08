--- Attention.spoon/ui/canvas/main.lua
--- Main dashboard canvas rendering

-- Use global path set by init.lua
local spoonPath = _G.AttentionSpoonPath
local helpers = dofile(spoonPath .. "/ui/canvas/helpers.lua")
local search = dofile(spoonPath .. "/search.lua")
local calendarApi = dofile(spoonPath .. "/api/calendar.lua")

---@class AttentionMainCanvas
local M = {}

-- Dependencies (set by init.lua)
M.fetch = nil
M.utils = nil

-- Local references to helpers for performance
local colors = helpers.colors
local font = helpers.font
local fontSize = helpers.fontSize
local padding = helpers.padding

--- Filter models by search query (fuzzy match)
--- @param models table Array of model definitions
--- @param query string Search query
--- @return table filtered Filtered models
local function filterModels(models, query)
	if not query or query == "" then return models end
	local filtered = {}
	local lowerQuery = query:lower()
	for _, m in ipairs(models) do
		local lowerName = m.name:lower()
		local lowerId = m.id:lower()
		local matches = false
		-- Simple fuzzy match
		local queryIndex = 1
		for i = 1, #lowerName do
			if lowerName:sub(i, i) == lowerQuery:sub(queryIndex, queryIndex) then
				queryIndex = queryIndex + 1
			end
			if queryIndex > #lowerQuery then
				matches = true
				break
			end
		end
		if not matches then
			queryIndex = 1
			for i = 1, #lowerId do
				if lowerId:sub(i, i) == lowerQuery:sub(queryIndex, queryIndex) then
					queryIndex = queryIndex + 1
				end
				if queryIndex > #lowerQuery then
					matches = true
					break
				end
			end
		end
		if matches then
			table.insert(filtered, m)
		end
	end
	return filtered
end

--- Get model display name from ID
--- @param models table Array of model definitions
--- @param modelId string The model ID
--- @return string name Display name
local function getModelDisplayName(models, modelId)
	for _, m in ipairs(models) do
		if m.id == modelId then
			return m.name
		end
	end
	return modelId:match("/(.+)") or modelId
end

--- Render the main dashboard canvas
--- @param state table The Attention spoon state object
--- @param data table The cached data (projects, calendar, etc.)
--- @param llmModels table Array of LLM model definitions
function M.render(state, data, llmModels)
	-- Stop any loading timer
	if state.loadingTimer then
		state.loadingTimer:stop()
		state.loadingTimer = nil
	end

	state.currentView = "main"
	state.clickableItems = {}
	state.hoveredIndex = nil
	state.keyMap = {}
	local itemIndex = 0

	local lineHeight = fontSize + 10
	local sectionHeaderHeight = fontSize + 16
	local groupHeaderHeight = fontSize + 12
	local searchBarHeight = 40
	local sectionSpacing = 16
	local groupSpacing = 8

	-- Apply search filter if active
	local displayData = data
	if state.activeFilter and state.activeFilter ~= "" then
		displayData = search.filterAll(data, state.activeFilter)
	end

	-- Get projects in order from config
	local projects = M.fetch.getProjectsInOrder(displayData)
	local calendarEvents = displayData.calendar or {}

	-- Group calendar events by date
	local calendarByDate, calendarDateOrder = calendarApi.groupByDate(calendarEvents)

	-- Two-column layout setup
	local boxWidth = 1400
	local columnGap = 32
	local columnWidth = (boxWidth - padding * 2 - columnGap) / 2
	local integrationHeaderHeight = fontSize + 12
	local subHeaderHeight = fontSize + 8

	-- Helper to calculate height for a project
	local function calcProjectHeight(project)
		local h = sectionHeaderHeight + 6
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
	local leftProjects = {}
	local rightProjects = {}
	local hasActiveFilter = state.activeFilter and state.activeFilter ~= ""

	if hasActiveFilter then
		local activeProjects = {}
		for _, project in ipairs(projects) do
			if search.projectHasItems(project.data) then
				table.insert(activeProjects, project)
			end
		end
		for i, project in ipairs(activeProjects) do
			if i % 2 == 1 then
				table.insert(leftProjects, project)
			else
				table.insert(rightProjects, project)
			end
		end
	else
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

	if #calendarEvents > 0 then
		contentHeight = contentHeight + sectionHeaderHeight
		for _, dateStr in ipairs(calendarDateOrder) do
			contentHeight = contentHeight + groupHeaderHeight
			contentHeight = contentHeight + (#calendarByDate[dateStr] * lineHeight)
		end
		contentHeight = contentHeight + sectionSpacing
	end

	contentHeight = contentHeight + math.max(leftHeight, rightHeight)
	contentHeight = contentHeight + padding
	local maxHeight = helpers.maxCanvasHeight()
	contentHeight = math.min(contentHeight, maxHeight)

	local frame = helpers.getCenteredFrame(boxWidth, contentHeight)

	if state.canvas then
		state.canvas:delete()
	end

	state.canvas = hs.canvas.new(frame)
	state.canvasFrame = frame
	state.lastCanvasSize = { w = boxWidth, h = contentHeight }
	local c = state.canvas

	-- Background
	c[1] = helpers.background()
	c[2] = helpers.border()

	-- Search bar
	local searchY = padding
	local searchText = state.searchQuery ~= "" and state.searchQuery or (state.activeFilter ~= "" and state.activeFilter or "")
	local searchPlaceholder, searchColor, borderColor
	local modelIndicatorWidth = 180
	local searchBarWidth = boxWidth - padding * 2
	local showModelIndicator = false

	if state.searchMode == "search" then
		searchPlaceholder = searchText ~= "" and searchText or ""
		searchColor = "#e0e0e0"
		borderColor = colors.accentWarning
	elseif state.searchMode == "llm" then
		searchPlaceholder = state.showModelSelector and (state.modelFilter ~= "" and state.modelFilter or "Search models...") or (searchText ~= "" and searchText or "Ask AI...")
		searchColor = "#e0e0e0"
		borderColor = colors.accentAi
		showModelIndicator = true
		searchBarWidth = boxWidth - padding * 2 - modelIndicatorWidth - 8
	elseif state.activeFilter ~= "" then
		searchPlaceholder = state.activeFilter
		searchColor = colors.accentWarning
		borderColor = colors.accentWarning
	else
		searchPlaceholder = "[s] search  /  [S] AI"
		searchColor = colors.textDim
		borderColor = colors.borderSubtle
	end

	-- Search bar background
	c[#c + 1] = helpers.rect({ x = padding, y = searchY, w = searchBarWidth, h = searchBarHeight - 8, color = colors.bgSecondary, radius = helpers.radiusMd })
	c[#c + 1] = {
		type = "rectangle",
		action = "stroke",
		strokeColor = { hex = borderColor, alpha = 0.6 },
		strokeWidth = 1,
		roundedRectRadii = { xRadius = helpers.radiusMd, yRadius = helpers.radiusMd },
		frame = { x = padding, y = searchY, w = searchBarWidth, h = searchBarHeight - 8 },
	}
	c[#c + 1] = helpers.text(searchPlaceholder, { x = padding + 12, y = searchY + 6, w = searchBarWidth - 24, h = fontSize + 4, color = searchColor })

	-- Model indicator (shown when in LLM mode)
	if showModelIndicator then
		local modelIndicatorX = padding + searchBarWidth + 8
		local modelName = getModelDisplayName(llmModels, state.currentLLMModel)
		local hotkeyBadgeWidth = 32
		local modelNameWidth = modelIndicatorWidth - hotkeyBadgeWidth - 20

		c[#c + 1] = helpers.rect({ x = modelIndicatorX, y = searchY, w = modelIndicatorWidth, h = searchBarHeight - 8, color = colors.bgTertiary, radius = helpers.radiusMd })
		c[#c + 1] = {
			type = "rectangle",
			action = "stroke",
			strokeColor = { hex = colors.accentAi, alpha = 0.4 },
			strokeWidth = 1,
			roundedRectRadii = { xRadius = helpers.radiusMd, yRadius = helpers.radiusMd },
			frame = { x = modelIndicatorX, y = searchY, w = modelIndicatorWidth, h = searchBarHeight - 8 },
		}
		c[#c + 1] = helpers.text(modelName, { x = modelIndicatorX + 8, y = searchY + 7, w = modelNameWidth, h = fontSize + 2, color = colors.textSecondary, size = fontSize - 1 })
		c[#c + 1] = helpers.rect({ x = modelIndicatorX + modelIndicatorWidth - hotkeyBadgeWidth - 6, y = searchY + 4, w = hotkeyBadgeWidth, h = searchBarHeight - 16, color = colors.borderSubtle, radius = helpers.radiusSm })
		c[#c + 1] = helpers.text("⇧␣", { x = modelIndicatorX + modelIndicatorWidth - hotkeyBadgeWidth - 6, y = searchY + 6, w = hotkeyBadgeWidth, h = fontSize, color = colors.accentAi, size = fontSize - 2, align = "center" })
	end

	-- Hover placeholder
	c[#c + 1] = helpers.hoverPlaceholder()

	local yPos = padding + searchBarHeight + sectionSpacing

	-- Model selector list (replaces content when active)
	if state.showModelSelector and state.searchMode == "llm" then
		local filteredModels = filterModels(llmModels, state.modelFilter)
		local modelLineHeight = lineHeight + 8

		if #filteredModels > 0 then
			for _, model in ipairs(filteredModels) do
				local isActive = model.id == state.currentLLMModel

				if isActive then
					c[#c + 1] = helpers.rect({ x = padding, y = yPos, w = boxWidth - padding * 2, h = modelLineHeight, color = colors.bgTertiary, radius = helpers.radiusMd })
					c[#c + 1] = {
						type = "rectangle",
						action = "stroke",
						strokeColor = { hex = colors.accentAi, alpha = 0.6 },
						strokeWidth = 1,
						roundedRectRadii = { xRadius = helpers.radiusMd, yRadius = helpers.radiusMd },
						frame = { x = padding, y = yPos, w = boxWidth - padding * 2, h = modelLineHeight },
					}
				end

				c[#c + 1] = helpers.rect({ x = padding + 12, y = yPos + 6, w = 28, h = modelLineHeight - 12, color = colors.borderSubtle, radius = helpers.radiusSm })
				c[#c + 1] = helpers.text(model.key, { x = padding + 12, y = yPos + 8, w = 28, h = fontSize, color = colors.accentAi, size = fontSize - 1, align = "center" })
				c[#c + 1] = helpers.text(model.name, { x = padding + 52, y = yPos + 8, w = boxWidth - padding * 2 - 100, h = fontSize + 4, color = "#e0e0e0" })

				if isActive then
					c[#c + 1] = helpers.text("*", { x = boxWidth - padding - 30, y = yPos + 6, w = 20, h = fontSize + 4, color = colors.accentAi, size = fontSize + 2, align = "right" })
				end

				table.insert(state.clickableItems, {
					type = "llm-model",
					y = yPos,
					h = modelLineHeight,
					x = padding,
					w = boxWidth - padding * 2,
					data = model,
					key = model.key,
				})
				state.keyMap[model.key] = #state.clickableItems

				yPos = yPos + modelLineHeight + 4
			end
		else
			c[#c + 1] = helpers.text("No models match \"" .. state.modelFilter .. "\"", { x = padding, y = yPos + 20, w = boxWidth - padding * 2, h = fontSize + 4, color = colors.textMuted, align = "center" })
		end

		c:level(hs.canvas.windowLevels.overlay)
		c:clickActivating(false)
		c:behaviorAsLabels({ "canJoinAllSpaces", "stationary" })
		c:show()
		state.visible = true
		return c
	end

	-- Calendar section
	if #calendarEvents > 0 then
		c[#c + 1] = helpers.text("Calendar", { x = padding, y = yPos, w = boxWidth - padding * 2, h = sectionHeaderHeight, color = colors.accentSuccess, size = fontSize + 2 })
		yPos = yPos + sectionHeaderHeight

		for _, dateStr in ipairs(calendarDateOrder) do
			local dateLabel = calendarApi.formatDate(dateStr)
			c[#c + 1] = helpers.text(dateLabel, { x = padding + 12, y = yPos, w = boxWidth - padding * 2, h = groupHeaderHeight, color = colors.accentWarning })
			yPos = yPos + groupHeaderHeight

			for _, event in ipairs(calendarByDate[dateStr]) do
				itemIndex = itemIndex + 1
				local shortcut = M.utils.getShortcutKey(itemIndex)

				if event.meetingUrl then
					table.insert(state.clickableItems, {
						type = "calendar",
						y = yPos,
						h = lineHeight,
						x = padding,
						w = boxWidth - padding * 2,
						data = event,
						key = shortcut,
					})
					if shortcut then state.keyMap[shortcut] = #state.clickableItems end
				end

				local timeDisplay = event.displayTime or ""
				local title = helpers.truncate(event.title or "", 50)

				local shortcutDisplay = event.meetingUrl and (shortcut or "") or ""
				local shortcutColor = event.meetingUrl and colors.accentSuccess or colors.textMuted
				local titleColor = event.isToday and colors.textPrimary or "#aaaaaa"

				c[#c + 1] = helpers.text(shortcutDisplay, { x = padding, y = yPos, w = 20, h = lineHeight, color = shortcutColor, align = "center" })
				c[#c + 1] = helpers.text(timeDisplay, { x = padding + 28, y = yPos, w = 110, h = lineHeight, color = colors.textSecondary })
				c[#c + 1] = helpers.text(title, { x = padding + 145, y = yPos, w = boxWidth - padding * 2 - 165, h = lineHeight, color = titleColor })

				if event.meetingUrl then
					c[#c + 1] = helpers.text("video", { x = boxWidth - padding - 50, y = yPos, w = 45, h = lineHeight, color = colors.accentSuccess, size = fontSize - 2, align = "right" })
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

		-- Project header with color indicator
		c[#c + 1] = helpers.rect({ x = colX, y = localY + 4, w = 4, h = fontSize, color = project.color })
		c[#c + 1] = helpers.text(project.name, { x = colX + 12, y = localY, w = columnWidth - 12, h = sectionHeaderHeight, color = colors.textPrimary, size = fontSize + 4 })
		localY = localY + sectionHeaderHeight + 6

		if #linearIssues == 0 and #notionTasks == 0 and slackCount == 0 then
			c[#c + 1] = helpers.text("No items", { x = colX, y = localY, w = columnWidth, h = lineHeight, color = colors.textMuted })
			localY = localY + lineHeight
		end

		-- Linear integration
		if #linearIssues > 0 then
			c[#c + 1] = helpers.text("Linear", { x = colX, y = localY, w = columnWidth, h = integrationHeaderHeight, color = colors.accentPrimary, size = fontSize + 1 })
			localY = localY + integrationHeaderHeight

			for _, issue in ipairs(linearIssues) do
				itemIndex = itemIndex + 1
				local shortcut = M.utils.getShortcutKey(itemIndex)

				table.insert(state.clickableItems, {
					type = "linear",
					y = localY,
					h = lineHeight,
					x = colX,
					w = columnWidth,
					data = issue,
					key = shortcut,
				})
				if shortcut then state.keyMap[shortcut] = #state.clickableItems end

				local title = helpers.truncate(issue.title or "", 45)

				c[#c + 1] = helpers.text(shortcut or "", { x = colX, y = localY, w = 20, h = lineHeight, color = colors.accentPrimary, align = "center" })
				c[#c + 1] = helpers.text(issue.identifier, { x = colX + 24, y = localY, w = 80, h = lineHeight, color = colors.textSecondary })
				c[#c + 1] = helpers.text(title, { x = colX + 108, y = localY, w = columnWidth - 120, h = lineHeight, color = colors.textPrimary })

				localY = localY + lineHeight
			end
			localY = localY + groupSpacing
		end

		-- Notion integration
		if #notionTasks > 0 then
			c[#c + 1] = helpers.text("Notion", { x = colX, y = localY, w = columnWidth, h = integrationHeaderHeight, color = colors.accentNotion, size = fontSize + 1 })
			localY = localY + integrationHeaderHeight

			for _, task in ipairs(notionTasks) do
				itemIndex = itemIndex + 1
				local shortcut = M.utils.getShortcutKey(itemIndex)

				table.insert(state.clickableItems, {
					type = "notion",
					y = localY,
					h = lineHeight,
					x = colX,
					w = columnWidth,
					data = task,
					key = shortcut,
				})
				if shortcut then state.keyMap[shortcut] = #state.clickableItems end

				local title = helpers.truncate(task.title or "", 45)

				c[#c + 1] = helpers.text(shortcut or "", { x = colX, y = localY, w = 20, h = lineHeight, color = colors.accentNotion, align = "center" })
				c[#c + 1] = helpers.text(task.identifier, { x = colX + 24, y = localY, w = 80, h = lineHeight, color = colors.textSecondary })
				c[#c + 1] = helpers.text(title, { x = colX + 108, y = localY, w = columnWidth - 120, h = lineHeight, color = colors.textPrimary })

				localY = localY + lineHeight
			end
			localY = localY + groupSpacing
		end

		-- Slack integration
		if slackCount > 0 then
			c[#c + 1] = helpers.text("Slack", { x = colX, y = localY, w = columnWidth, h = integrationHeaderHeight, color = colors.accentSlack, size = fontSize + 1 })
			localY = localY + integrationHeaderHeight

			-- Mentions
			if #slackChannels > 0 then
				c[#c + 1] = helpers.text("Mentions (" .. #slackChannels .. ")", { x = colX, y = localY, w = columnWidth, h = subHeaderHeight, color = colors.textSecondary, size = fontSize - 1 })
				localY = localY + subHeaderHeight

				for i, msg in ipairs(slackChannels) do
					if i > 5 then break end
					itemIndex = itemIndex + 1
					local shortcut = M.utils.getShortcutKey(itemIndex)

					table.insert(state.clickableItems, {
						type = "slack",
						y = localY,
						h = lineHeight,
						x = colX,
						w = columnWidth,
						data = msg,
						key = shortcut,
						_token = slackToken,
					})
					if shortcut then state.keyMap[shortcut] = #state.clickableItems end

					local from = msg.username or "unknown"
					local channel = msg.channel and msg.channel.name or ""
					local text = msg.text or ""
					text = text:gsub("<@[^>]+[^>]*>", ""):gsub("<[^>]+>", ""):gsub("%s+", " "):gsub("^%s+", "")
					text = helpers.truncate(text, 35)

					c[#c + 1] = helpers.text(shortcut or "", { x = colX, y = localY, w = 20, h = lineHeight, color = colors.accentSlack, align = "center" })
					c[#c + 1] = helpers.text("#" .. channel, { x = colX + 24, y = localY, w = 80, h = lineHeight, color = colors.textSecondary })
					c[#c + 1] = helpers.text(from .. ": " .. text, { x = colX + 108, y = localY, w = columnWidth - 120, h = lineHeight, color = colors.textPrimary })

					localY = localY + lineHeight
				end
				localY = localY + groupSpacing
			end

			-- DMs
			if #slackDms > 0 then
				c[#c + 1] = helpers.text("DMs (" .. #slackDms .. ")", { x = colX, y = localY, w = columnWidth, h = subHeaderHeight, color = colors.textSecondary, size = fontSize - 1 })
				localY = localY + subHeaderHeight

				for i, msg in ipairs(slackDms) do
					if i > 5 then break end
					itemIndex = itemIndex + 1
					local shortcut = M.utils.getShortcutKey(itemIndex)

					table.insert(state.clickableItems, {
						type = "slack",
						y = localY,
						h = lineHeight,
						x = colX,
						w = columnWidth,
						data = msg,
						key = shortcut,
						_token = slackToken,
					})
					if shortcut then state.keyMap[shortcut] = #state.clickableItems end

					local from = msg.username or "unknown"
					local text = msg.text or ""
					text = text:gsub("<@[^>]+[^>]*>", ""):gsub("<[^>]+>", ""):gsub("%s+", " "):gsub("^%s+", "")
					text = helpers.truncate(text, 40)

					c[#c + 1] = helpers.text(shortcut or "", { x = colX, y = localY, w = 20, h = lineHeight, color = colors.accentSlack, align = "center" })
					c[#c + 1] = helpers.text(from, { x = colX + 24, y = localY, w = 80, h = lineHeight, color = colors.textSecondary })
					c[#c + 1] = helpers.text(text, { x = colX + 108, y = localY, w = columnWidth - 120, h = lineHeight, color = colors.textPrimary })

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

	c:level(hs.canvas.windowLevels.overlay)
	c:clickActivating(false)
	c:behaviorAsLabels({ "canJoinAllSpaces", "stationary" })
	c:show()
	state.visible = true

	return c
end

return M
