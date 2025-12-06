--- Attention.spoon/ui/linear.lua
--- Linear issue detail view rendering

local styles = dofile(_G.AttentionSpoonPath .. "/ui/styles.lua")

---@class AttentionLinearUI
local M = {}

--- Render the Linear issue detail view with description and comments
--- @param state table The state table
--- @param issue table|nil The issue to render (uses state.currentIssue if nil)
--- @param resetScroll boolean|nil Whether to reset scroll position (default true)
--- @return hs.canvas|nil canvas The rendered canvas, or nil if no issue
--- @example
---   local canvas = linear.renderDetail(state, issue, true)
function M.renderDetail(state, issue, resetScroll)
	-- Store issue for scroll re-renders
	if issue then
		state.currentIssue = issue
	else
		issue = state.currentIssue
	end
	if not issue then
		return nil
	end

	-- Reset scroll on new issue
	if resetScroll ~= false then
		state.scrollOffset = 0
	end

	state.currentView = "linear-detail"
	state.clickableItems = {}
	state.hoveredIndex = nil
	state.keyMap = {}
	state.keyMap["b"] = 1 -- 'b' for back

	local c = styles.colors
	local d = styles.dimensions
	local f = styles.fonts

	local lineHeight = f.size + 8
	local boxWidth = d.boxWidth
	local boxHeight = d.boxHeight
	local footerHeight = d.footerHeight
	local contentTop = 60 -- Start of scrollable content

	local screen = hs.screen.mainScreen()
	local frame = screen:frame()
	local boxX = frame.x + (frame.w - boxWidth) / 2
	local boxY = frame.y + (frame.h - boxHeight) / 2

	if state.canvas then
		state.canvas:delete()
	end

	state.canvas = hs.canvas.new({ x = boxX, y = boxY, w = boxWidth, h = boxHeight })
	state.canvasFrame = { x = boxX, y = boxY, w = boxWidth, h = boxHeight }
	state.lastCanvasSize = { w = boxWidth, h = boxHeight }
	local canvas = state.canvas

	-- Background & border
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

	-- Back button
	table.insert(state.clickableItems, {
		type = "back",
		y = d.padding,
		h = 30,
		x = d.padding,
		w = 90,
		key = "b",
	})
	canvas[3] = {
		type = "text",
		text = "b",
		textFont = f.mono,
		textSize = f.size,
		textColor = { hex = c.accentLinear, alpha = 1 },
		textAlignment = "left",
		frame = { x = d.padding, y = d.padding, w = 16, h = 30 },
	}
	canvas[4] = {
		type = "text",
		text = "<- Back",
		textFont = f.mono,
		textSize = f.size,
		textColor = { hex = c.textSecondary, alpha = 1 },
		textAlignment = "left",
		frame = { x = d.padding + 20, y = d.padding, w = 70, h = 30 },
	}

	-- Hover highlight placeholder (index 5)
	canvas[5] = {
		type = "rectangle",
		action = "fill",
		fillColor = { hex = c.textPrimary, alpha = 0 },
		frame = { x = 0, y = 0, w = 0, h = 0 },
	}

	-- Title bar with identifier (fixed, not scrolled)
	local titleY = d.padding + 10
	canvas[#canvas + 1] = {
		type = "text",
		text = issue.identifier,
		textFont = f.mono,
		textSize = f.sizeLarge,
		textColor = { hex = c.textSecondary, alpha = 1 },
		textAlignment = "center",
		frame = { x = d.padding, y = titleY, w = boxWidth - (d.padding * 2), h = 30 },
	}

	-- Clipping rectangle for scrollable content
	local clipTop = d.padding + 45
	local clipHeight = boxHeight - clipTop - footerHeight - 8
	canvas[#canvas + 1] = {
		type = "rectangle",
		action = "clip",
		frame = { x = 0, y = clipTop, w = boxWidth, h = clipHeight },
	}

	-- Scrollable content area
	local scrollY = -state.scrollOffset
	local yPos = clipTop + 5 + scrollY

	-- Issue title
	canvas[#canvas + 1] = {
		type = "text",
		text = issue.title or "Untitled",
		textFont = f.mono,
		textSize = f.sizeLarge + 4,
		textColor = { hex = c.textPrimary, alpha = 1 },
		textAlignment = "left",
		frame = { x = d.padding, y = yPos, w = boxWidth - (d.padding * 2), h = 36 },
	}
	yPos = yPos + 44

	-- Status & Project
	local status = issue.state and issue.state.name or "Unknown"
	local project = issue.project and issue.project.name or "No Project"
	canvas[#canvas + 1] = {
		type = "text",
		text = status .. "  *  " .. project,
		textFont = f.mono,
		textSize = f.size,
		textColor = { hex = c.accentOrange, alpha = 1 },
		textAlignment = "left",
		frame = { x = d.padding, y = yPos, w = boxWidth - (d.padding * 2), h = lineHeight },
	}
	yPos = yPos + lineHeight + 16

	-- Separator
	canvas[#canvas + 1] = {
		type = "rectangle",
		action = "fill",
		fillColor = { hex = c.borderMedium, alpha = 1 },
		frame = { x = d.padding, y = yPos, w = boxWidth - (d.padding * 2), h = 1 },
	}
	yPos = yPos + 20

	-- Description
	canvas[#canvas + 1] = {
		type = "text",
		text = "Description",
		textFont = f.mono,
		textSize = f.size,
		textColor = { hex = c.accentLinear, alpha = 1 },
		textAlignment = "left",
		frame = { x = d.padding, y = yPos, w = boxWidth - (d.padding * 2), h = lineHeight },
	}
	yPos = yPos + lineHeight + 4

	local desc = issue.description or "(No description)"
	if #desc > 2000 then
		desc = desc:sub(1, 2000) .. "..."
	end
	local descLines = math.ceil(#desc / 80)
	local descHeight = math.max(50, descLines * 18)
	canvas[#canvas + 1] = {
		type = "text",
		text = desc,
		textFont = f.mono,
		textSize = f.size - 1,
		textColor = { hex = "#cccccc", alpha = 1 },
		textAlignment = "left",
		frame = { x = d.padding, y = yPos, w = boxWidth - (d.padding * 2), h = descHeight },
	}
	yPos = yPos + descHeight + 20

	-- Comments section
	local comments = issue.comments and issue.comments.nodes or {}
	if #comments > 0 then
		canvas[#canvas + 1] = {
			type = "rectangle",
			action = "fill",
			fillColor = { hex = c.borderMedium, alpha = 1 },
			frame = { x = d.padding, y = yPos, w = boxWidth - (d.padding * 2), h = 1 },
		}
		yPos = yPos + 20

		canvas[#canvas + 1] = {
			type = "text",
			text = "Comments (" .. #comments .. ")",
			textFont = f.mono,
			textSize = f.size,
			textColor = { hex = c.accentLinear, alpha = 1 },
			textAlignment = "left",
			frame = { x = d.padding, y = yPos, w = boxWidth - (d.padding * 2), h = lineHeight },
		}
		yPos = yPos + lineHeight + 8

		for _, comment in ipairs(comments) do
			local author = comment.user and comment.user.name or "Unknown"
			local body = comment.body or ""
			if #body > 500 then
				body = body:sub(1, 500) .. "..."
			end
			local commentLines = math.ceil(#body / 80)
			local commentHeight = math.max(30, commentLines * 18)

			canvas[#canvas + 1] = {
				type = "text",
				text = author,
				textFont = f.mono,
				textSize = f.size - 1,
				textColor = { hex = c.accentOrange, alpha = 1 },
				textAlignment = "left",
				frame = { x = d.padding, y = yPos, w = boxWidth - (d.padding * 2), h = lineHeight },
			}
			yPos = yPos + lineHeight

			canvas[#canvas + 1] = {
				type = "text",
				text = body,
				textFont = f.mono,
				textSize = f.size - 1,
				textColor = { hex = c.textSecondary, alpha = 1 },
				textAlignment = "left",
				frame = { x = d.padding + 12, y = yPos, w = boxWidth - (d.padding * 2) - 12, h = commentHeight },
			}
			yPos = yPos + commentHeight + 12
		end
	end

	-- Track total content height for scroll limits
	state.contentHeight = yPos + state.scrollOffset - d.padding
	state.viewHeight = boxHeight - contentTop - footerHeight - 8

	-- Reset clip for footer
	canvas[#canvas + 1] = { type = "resetClip" }

	-- Footer bar
	local footerY = boxHeight - footerHeight
	canvas[#canvas + 1] = {
		type = "rectangle",
		action = "fill",
		fillColor = { hex = c.bgSecondary, alpha = 1 },
		frame = { x = 0, y = footerY, w = boxWidth, h = footerHeight },
	}
	canvas[#canvas + 1] = {
		type = "rectangle",
		action = "fill",
		fillColor = { hex = c.borderMedium, alpha = 1 },
		frame = { x = d.padding, y = footerY, w = boxWidth - (d.padding * 2), h = 1 },
	}

	-- Footer hotkey hints
	local hintY = footerY + 10
	local hintSize = f.sizeSmall
	local keyColor = { hex = c.accentLinear, alpha = 1 }
	local textColor = { hex = c.textMuted, alpha = 1 }

	-- Scroll indicators
	local canScrollUp = state.scrollOffset > 0
	local canScrollDown = state.contentHeight > state.viewHeight + state.scrollOffset
	local scrollHint = ""
	if canScrollUp and canScrollDown then
		scrollHint = "^v"
	elseif canScrollUp then
		scrollHint = "^"
	elseif canScrollDown then
		scrollHint = "v"
	end

	local xPos = d.padding
	-- j/k scroll
	canvas[#canvas + 1] = {
		type = "text",
		text = "j/k",
		textFont = f.mono,
		textSize = hintSize,
		textColor = keyColor,
		textAlignment = "left",
		frame = { x = xPos, y = hintY, w = 30, h = 20 },
	}
	xPos = xPos + 32
	canvas[#canvas + 1] = {
		type = "text",
		text = "scroll " .. scrollHint,
		textFont = f.mono,
		textSize = hintSize,
		textColor = textColor,
		textAlignment = "left",
		frame = { x = xPos, y = hintY, w = 80, h = 20 },
	}
	xPos = xPos + 90

	-- Ctrl+D/U page
	canvas[#canvas + 1] = {
		type = "text",
		text = "^d/^u",
		textFont = f.mono,
		textSize = hintSize,
		textColor = keyColor,
		textAlignment = "left",
		frame = { x = xPos, y = hintY, w = 50, h = 20 },
	}
	xPos = xPos + 52
	canvas[#canvas + 1] = {
		type = "text",
		text = "page",
		textFont = f.mono,
		textSize = hintSize,
		textColor = textColor,
		textAlignment = "left",
		frame = { x = xPos, y = hintY, w = 40, h = 20 },
	}
	xPos = xPos + 60

	-- b back
	canvas[#canvas + 1] = {
		type = "text",
		text = "b",
		textFont = f.mono,
		textSize = hintSize,
		textColor = keyColor,
		textAlignment = "left",
		frame = { x = xPos, y = hintY, w = 14, h = 20 },
	}
	xPos = xPos + 16
	canvas[#canvas + 1] = {
		type = "text",
		text = "back",
		textFont = f.mono,
		textSize = hintSize,
		textColor = textColor,
		textAlignment = "left",
		frame = { x = xPos, y = hintY, w = 40, h = 20 },
	}
	xPos = xPos + 60

	-- esc close
	canvas[#canvas + 1] = {
		type = "text",
		text = "esc",
		textFont = f.mono,
		textSize = hintSize,
		textColor = keyColor,
		textAlignment = "left",
		frame = { x = xPos, y = hintY, w = 30, h = 20 },
	}
	xPos = xPos + 32
	canvas[#canvas + 1] = {
		type = "text",
		text = "close",
		textFont = f.mono,
		textSize = hintSize,
		textColor = textColor,
		textAlignment = "left",
		frame = { x = xPos, y = hintY, w = 50, h = 20 },
	}

	canvas:level(hs.canvas.windowLevels.overlay)
	canvas:clickActivating(false)
	canvas:show()
	state.visible = true

	return canvas
end

--- Update the hover highlight on the Linear detail view
--- @param state table The state table
--- @param index number|nil The item index to highlight (nil to clear)
function M.updateHover(state, index)
	if state.hoveredIndex == index then
		return
	end
	state.hoveredIndex = index

	if not state.canvas then
		return
	end

	local c = styles.colors

	if index and state.clickableItems[index] then
		local item = state.clickableItems[index]
		state.canvas[5] = {
			type = "rectangle",
			action = "fill",
			fillColor = { hex = c.textPrimary, alpha = 0.08 },
			roundedRectRadii = { xRadius = 4, yRadius = 4 },
			frame = { x = item.x or 24, y = item.y, w = item.w or 852, h = item.h },
		}
	else
		state.canvas[5] = {
			type = "rectangle",
			action = "fill",
			fillColor = { hex = c.textPrimary, alpha = 0 },
			frame = { x = 0, y = 0, w = 0, h = 0 },
		}
	end
end

return M
