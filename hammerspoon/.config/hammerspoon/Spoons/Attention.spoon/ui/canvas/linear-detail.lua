--- Attention.spoon/ui/canvas/linear-detail.lua
--- Linear issue detail canvas rendering

-- Use global path set by init.lua
local spoonPath = _G.AttentionSpoonPath
local helpers = dofile(spoonPath .. "/ui/canvas/helpers.lua")

---@class AttentionLinearDetailCanvas
local M = {}

-- Local references for performance
local colors = helpers.colors
local font = helpers.font
local fontSize = helpers.fontSize
local padding = helpers.padding

--- Render the Linear issue detail canvas
--- @param state table The Attention spoon state object
--- @param issue table|nil The issue to render (uses state.currentIssue if nil)
--- @param resetScroll boolean|nil Whether to reset scroll position (default true)
function M.render(state, issue, resetScroll)
	-- Stop any loading timer
	if state.loadingTimer then
		state.loadingTimer:stop()
		state.loadingTimer = nil
	end

	if issue then
		state.currentIssue = issue
	else
		issue = state.currentIssue
	end
	if not issue then return nil end

	if resetScroll ~= false then
		state.scrollOffset = 0
	end

	state.currentView = "linear-detail"
	state.clickableItems = {}
	state.hoveredIndex = nil
	state.keyMap = {}
	state.keyMap["b"] = 1

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

	-- Background and border
	c[1] = helpers.background()
	c[2] = helpers.border()

	-- Back button
	table.insert(state.clickableItems, { type = "back", y = padding, h = 30, x = padding, w = 90, key = "b" })
	c[3] = helpers.text("b", { x = padding, y = padding, w = 16, h = 30, color = colors.accentPrimary })
	c[4] = helpers.text("<- Back", { x = padding + 20, y = padding, w = 70, h = 30, color = colors.textSecondary })
	c[5] = helpers.hoverPlaceholder()

	-- Issue identifier
	local titleY = padding + 10
	c[#c + 1] = helpers.text(issue.identifier, { x = padding, y = titleY, w = boxWidth - (padding * 2), h = 30, color = colors.textSecondary, size = fontSize + 2, align = "center" })

	-- Clip region for scrollable content
	local clipTop = padding + 45
	local clipHeight = boxHeight - clipTop - footerHeight - 8
	c[#c + 1] = helpers.clip(0, clipTop, boxWidth, clipHeight)

	local scrollY = -state.scrollOffset
	local yPos = clipTop + 5 + scrollY

	-- Issue title
	c[#c + 1] = helpers.text(issue.title or "Untitled", { x = padding, y = yPos, w = boxWidth - (padding * 2), h = 36, color = colors.textPrimary, size = fontSize + 6 })
	yPos = yPos + 44

	-- Status and project
	local status = issue.state and issue.state.name or "Unknown"
	local project = issue.project and issue.project.name or "No Project"
	c[#c + 1] = helpers.text(status .. "  *  " .. project, { x = padding, y = yPos, w = boxWidth - (padding * 2), h = lineHeight, color = colors.accentWarning })
	yPos = yPos + lineHeight + 16

	-- Divider
	c[#c + 1] = helpers.line({ x = padding, y = yPos, w = boxWidth - (padding * 2) })
	yPos = yPos + 20

	-- Description section
	c[#c + 1] = helpers.text("Description", { x = padding, y = yPos, w = boxWidth - (padding * 2), h = lineHeight, color = colors.accentPrimary })
	yPos = yPos + lineHeight + 4

	local desc = issue.description or "(No description)"
	if #desc > 2000 then desc = desc:sub(1, 2000) .. "..." end
	local descLines = math.ceil(#desc / 80)
	local descHeight = math.max(50, descLines * 18)
	c[#c + 1] = helpers.text(desc, { x = padding, y = yPos, w = boxWidth - (padding * 2), h = descHeight, color = "#cccccc", size = fontSize - 1 })
	yPos = yPos + descHeight + 20

	-- Comments section
	local comments = issue.comments and issue.comments.nodes or {}
	if #comments > 0 then
		c[#c + 1] = helpers.line({ x = padding, y = yPos, w = boxWidth - (padding * 2) })
		yPos = yPos + 20

		c[#c + 1] = helpers.text("Comments (" .. #comments .. ")", { x = padding, y = yPos, w = boxWidth - (padding * 2), h = lineHeight, color = colors.accentPrimary })
		yPos = yPos + lineHeight + 8

		for _, comment in ipairs(comments) do
			local author = comment.user and comment.user.name or "Unknown"
			local body = comment.body or ""
			if #body > 500 then body = body:sub(1, 500) .. "..." end
			local commentLines = math.ceil(#body / 80)
			local commentHeight = math.max(30, commentLines * 18)

			c[#c + 1] = helpers.text(author, { x = padding, y = yPos, w = boxWidth - (padding * 2), h = lineHeight, color = colors.accentWarning, size = fontSize - 1 })
			yPos = yPos + lineHeight

			c[#c + 1] = helpers.text(body, { x = padding + 12, y = yPos, w = boxWidth - (padding * 2) - 12, h = commentHeight, color = "#aaaaaa", size = fontSize - 1 })
			yPos = yPos + commentHeight + 12
		end
	end

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
	local keyColor = colors.accentPrimary
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
	c[#c + 1] = helpers.text("^d/^u", { x = xPos, y = hintY, w = 50, h = 20, color = keyColor, size = hintSize })
	xPos = xPos + 52
	c[#c + 1] = helpers.text("page", { x = xPos, y = hintY, w = 40, h = 20, color = textColor, size = hintSize })
	xPos = xPos + 60
	c[#c + 1] = helpers.text("b", { x = xPos, y = hintY, w = 14, h = 20, color = keyColor, size = hintSize })
	xPos = xPos + 16
	c[#c + 1] = helpers.text("back", { x = xPos, y = hintY, w = 40, h = 20, color = textColor, size = hintSize })
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
