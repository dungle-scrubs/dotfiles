--- Attention.spoon/ui/canvas/notion-detail.lua
--- Notion task detail canvas rendering

-- Use global path set by init.lua
local spoonPath = _G.AttentionSpoonPath
local helpers = dofile(spoonPath .. "/ui/canvas/helpers.lua")

---@class AttentionNotionDetailCanvas
local M = {}

-- Local references for performance
local colors = helpers.colors
local font = helpers.font
local fontSize = helpers.fontSize
local padding = helpers.padding

--- Render the Notion task detail canvas
--- @param state table The Attention spoon state object
--- @param task table|nil The task to render (uses state.currentNotionTask if nil)
--- @param resetScroll boolean|nil Whether to reset scroll position (default true)
function M.render(state, task, resetScroll)
	-- Stop any loading timer
	if state.loadingTimer then
		state.loadingTimer:stop()
		state.loadingTimer = nil
	end

	if task then
		state.currentNotionTask = task
	else
		task = state.currentNotionTask
	end
	if not task then return nil end

	if resetScroll ~= false then
		state.scrollOffset = 0
	end

	state.currentView = "notion-detail"
	state.clickableItems = {}
	state.hoveredIndex = nil
	state.keyMap = {}
	state.keyMap["b"] = 1
	state.keyMap["o"] = 2

	local lineHeight = fontSize + 8
	local boxWidth = 900
	local boxHeight = 600
	local footerHeight = 36
	local contentTop = 60

	local frame = helpers.getCenteredFrame(boxWidth, boxHeight)

	if state.canvas then
		state.canvas:delete()
	end

	state.canvas = hs.canvas.new(frame)
	state.canvasFrame = frame
	state.lastCanvasSize = { w = boxWidth, h = boxHeight }
	local c = state.canvas

	-- Background and border (using Notion accent color)
	c[1] = helpers.background()
	c[2] = helpers.border(colors.accentNotion)

	-- Back button
	table.insert(state.clickableItems, { type = "back", y = padding, h = 30, x = padding, w = 90, key = "b" })
	c[3] = helpers.text("b", { x = padding, y = padding, w = 16, h = 30, color = colors.accentNotion })
	c[4] = helpers.text("<- Back", { x = padding + 20, y = padding, w = 70, h = 30, color = colors.textSecondary })

	-- Open in Notion button
	table.insert(state.clickableItems, { type = "open-notion", y = padding, h = 30, x = boxWidth - padding - 140, w = 140, data = task, key = "o" })
	c[5] = helpers.text("o", { x = boxWidth - padding - 140, y = padding, w = 16, h = 30, color = colors.accentNotion, align = "right" })
	c[6] = helpers.text("Open in Notion ->", { x = boxWidth - padding - 120, y = padding, w = 120, h = 30, color = colors.textSecondary, align = "right" })

	c[7] = helpers.hoverPlaceholder()

	-- Task identifier
	local titleY = padding + 10
	c[#c + 1] = helpers.text(task.identifier, { x = padding, y = titleY, w = boxWidth - (padding * 2), h = 30, color = colors.textSecondary, size = fontSize + 2, align = "center" })

	-- Clip region for scrollable content
	local clipTop = padding + 45
	local clipHeight = boxHeight - clipTop - footerHeight - 8
	c[#c + 1] = helpers.clip(0, clipTop, boxWidth, clipHeight)

	local scrollY = -state.scrollOffset
	local yPos = clipTop + 5 + scrollY

	-- Task title
	c[#c + 1] = helpers.text(task.title or "Untitled", { x = padding, y = yPos, w = boxWidth - (padding * 2), h = 36, color = colors.textPrimary, size = fontSize + 6 })
	yPos = yPos + 40

	-- Badges (domain + tags)
	local hasBadges = task.domain or (task.tags and #task.tags > 0)
	if hasBadges then
		local badgeX = padding
		local badgeFontSize = 11
		local badgePadding = 8
		local badgeGap = 6
		local badgeHeight = 18

		-- Collect all badges
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
			c[#c + 1] = helpers.rect({ x = badgeX, y = yPos, w = badgeWidth, h = badgeHeight, color = "#3a3a3a", radius = helpers.radiusSm })
			c[#c + 1] = helpers.text(badge, { x = badgeX, y = yPos + 2, w = badgeWidth, h = badgeHeight - 2, color = "#a0a0a0", size = badgeFontSize, align = "center" })
			badgeX = badgeX + badgeWidth + badgeGap
		end
		yPos = yPos + badgeHeight + 12
	end

	-- Status
	local status = task.status or "Unknown"
	c[#c + 1] = helpers.text(status, { x = padding, y = yPos, w = boxWidth - (padding * 2), h = lineHeight, color = colors.accentWarning })
	yPos = yPos + lineHeight + 16

	-- Divider
	c[#c + 1] = helpers.line({ x = padding, y = yPos, w = boxWidth - (padding * 2) })
	yPos = yPos + 20

	-- Content section
	c[#c + 1] = helpers.text("Content", { x = padding, y = yPos, w = boxWidth - (padding * 2), h = lineHeight, color = colors.accentNotion })
	yPos = yPos + lineHeight + 4

	local content = task.content or "(No content)"
	if #content > 3000 then content = content:sub(1, 3000) .. "..." end

	-- Better height calculation
	local contentWidth = boxWidth - (padding * 2)
	local charsPerLine = math.floor(contentWidth / 8)
	local lineCount = 0
	for line in (content .. "\n"):gmatch("([^\n]*)\n") do
		lineCount = lineCount + math.max(1, math.ceil(#line / charsPerLine))
	end
	local contentLineHeight = 18
	local contentHeight = math.max(100, lineCount * contentLineHeight + 20)
	c[#c + 1] = helpers.text(content, { x = padding, y = yPos, w = contentWidth, h = contentHeight, color = "#cccccc", size = fontSize - 1 })
	yPos = yPos + contentHeight + 20

	state.contentHeight = yPos + state.scrollOffset - padding
	state.viewHeight = boxHeight - contentTop - footerHeight - 8

	c[#c + 1] = helpers.resetClip()

	-- Footer
	local footerY = boxHeight - footerHeight
	c[#c + 1] = helpers.rect({ x = 0, y = footerY, w = boxWidth, h = footerHeight, color = colors.bgSecondary })
	c[#c + 1] = helpers.line({ x = padding, y = footerY, w = boxWidth - (padding * 2) })

	-- Footer hints
	local hintY = footerY + 10
	local hintSize = fontSize - 2
	local keyColor = colors.accentNotion
	local textColor = colors.textMuted

	local canScrollUp = state.scrollOffset > 0
	local canScrollDown = state.contentHeight > state.viewHeight + state.scrollOffset
	local scrollHint = ""
	if canScrollUp and canScrollDown then scrollHint = "↑↓"
	elseif canScrollUp then scrollHint = "↑"
	elseif canScrollDown then scrollHint = "↓"
	end

	local xPos = padding
	c[#c + 1] = helpers.text("j/k", { x = xPos, y = hintY, w = 30, h = 20, color = keyColor, size = hintSize })
	xPos = xPos + 32
	c[#c + 1] = helpers.text("scroll " .. scrollHint, { x = xPos, y = hintY, w = 80, h = 20, color = textColor, size = hintSize })
	xPos = xPos + 90
	c[#c + 1] = helpers.text("b", { x = xPos, y = hintY, w = 14, h = 20, color = keyColor, size = hintSize })
	xPos = xPos + 16
	c[#c + 1] = helpers.text("back", { x = xPos, y = hintY, w = 40, h = 20, color = textColor, size = hintSize })
	xPos = xPos + 60
	c[#c + 1] = helpers.text("o", { x = xPos, y = hintY, w = 14, h = 20, color = keyColor, size = hintSize })
	xPos = xPos + 16
	c[#c + 1] = helpers.text("open", { x = xPos, y = hintY, w = 40, h = 20, color = textColor, size = hintSize })
	xPos = xPos + 60
	c[#c + 1] = helpers.text("esc", { x = xPos, y = hintY, w = 30, h = 20, color = keyColor, size = hintSize })
	xPos = xPos + 32
	c[#c + 1] = helpers.text("close", { x = xPos, y = hintY, w = 50, h = 20, color = textColor, size = hintSize })

	c:level(hs.canvas.windowLevels.overlay)
	c:clickActivating(false)
	c:show()
	state.visible = true

	return c
end

return M
