--- Attention.spoon/ui/main.lua
--- Main dashboard rendering for the Attention dashboard

local styles = dofile(_G.AttentionSpoonPath .. "/ui/styles.lua")
local utils = dofile(_G.AttentionSpoonPath .. "/utils.lua")

---@class AttentionMainUI
local M = {}

--- Render the main dashboard view showing Linear issues and Slack messages
--- @param state table The state table containing cache and UI state
--- @param callbacks table Callback functions for item selection
--- @return hs.canvas canvas The rendered canvas
--- @example
---   local canvas = main.render(state, {
---     onLinearSelect = function(issue) ... end,
---     onSlackSelect = function(msg) ... end,
---   })
function M.render(state, callbacks)
	callbacks = callbacks or {}
	local data = state.cache

	state.currentView = "main"
	state.clickableItems = {}
	state.hoveredIndex = nil
	state.keyMap = {}
	local itemIndex = 0

	local c = styles.colors
	local d = styles.dimensions
	local f = styles.fonts

	local lineHeight = f.size + 10
	local sectionHeaderHeight = f.size + 16
	local groupHeaderHeight = f.size + 12
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

	-- Calculate content height
	local linearLines = #(data.linear or {})
	local linearGroups = #linearProjectOrder
	local slackDms = data.slack and data.slack.dms or {}
	local slackChannels = data.slack and data.slack.channels or {}
	local slackDmLines = math.min(#slackDms, 5)
	local slackChannelLines = math.min(#slackChannels, 5)

	local contentHeight = titleHeight + d.padding * 2 + 16
	if linearLines > 0 then
		contentHeight = contentHeight
			+ sectionHeaderHeight
			+ (linearLines * lineHeight)
			+ (linearGroups * (groupHeaderHeight + groupSpacing))
			+ sectionSpacing
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

	local boxWidth = d.boxWidth
	local screen = hs.screen.mainScreen()
	local frame = screen:frame()
	local boxX = frame.x + (frame.w - boxWidth) / 2
	local boxY = frame.y + (frame.h - contentHeight) / 2

	if state.canvas then
		state.canvas:delete()
	end

	state.canvas = hs.canvas.new({ x = boxX, y = boxY, w = boxWidth, h = contentHeight })
	state.canvasFrame = { x = boxX, y = boxY, w = boxWidth, h = contentHeight }
	state.lastCanvasSize = { w = boxWidth, h = contentHeight }
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

	-- Title
	local totalItems = linearLines + slackChannelLines + slackDmLines
	canvas[3] = {
		type = "text",
		text = "Attention (" .. totalItems .. ")",
		textFont = f.mono,
		textSize = f.sizeLarge,
		textColor = { hex = c.accentLinear, alpha = 1 },
		textAlignment = "center",
		frame = { x = d.padding, y = d.padding, w = boxWidth - (d.padding * 2), h = titleHeight },
	}
	canvas[4] = {
		type = "rectangle",
		action = "fill",
		fillColor = { hex = c.borderMedium, alpha = 1 },
		frame = { x = d.padding, y = d.padding + titleHeight, w = boxWidth - (d.padding * 2), h = 1 },
	}

	-- Hover highlight placeholder (index 5)
	canvas[5] = {
		type = "rectangle",
		action = "fill",
		fillColor = { hex = c.textPrimary, alpha = 0 },
		frame = { x = 0, y = 0, w = 0, h = 0 },
	}

	local yPos = d.padding + titleHeight + 16

	-- Linear section
	if #(data.linear or {}) > 0 then
		canvas[#canvas + 1] = {
			type = "text",
			text = "Linear",
			textFont = f.mono,
			textSize = f.sizeLarge,
			textColor = { hex = c.accentLinear, alpha = 1 },
			textAlignment = "left",
			frame = { x = d.padding, y = yPos, w = boxWidth - (d.padding * 2), h = sectionHeaderHeight },
		}
		yPos = yPos + sectionHeaderHeight

		for _, projectName in ipairs(linearProjectOrder) do
			canvas[#canvas + 1] = {
				type = "text",
				text = projectName,
				textFont = f.mono,
				textSize = f.size,
				textColor = { hex = c.accentOrange, alpha = 1 },
				textAlignment = "left",
				frame = { x = d.padding + 12, y = yPos, w = boxWidth - (d.padding * 2), h = groupHeaderHeight },
			}
			yPos = yPos + groupHeaderHeight

			for _, issue in ipairs(linearProjects[projectName]) do
				itemIndex = itemIndex + 1
				local shortcut = utils.getShortcutKey(itemIndex)

				-- Track clickable item
				table.insert(state.clickableItems, {
					type = "linear",
					y = yPos,
					h = lineHeight,
					x = d.padding,
					w = boxWidth - d.padding * 2,
					data = issue,
					key = shortcut,
				})
				if shortcut then
					state.keyMap[shortcut] = #state.clickableItems
				end

				-- Shortcut key
				canvas[#canvas + 1] = {
					type = "text",
					text = shortcut or "",
					textFont = f.mono,
					textSize = f.size,
					textColor = { hex = c.accentLinear, alpha = 1 },
					textAlignment = "center",
					frame = { x = d.padding, y = yPos, w = 20, h = lineHeight },
				}

				canvas[#canvas + 1] = {
					type = "text",
					text = issue.identifier,
					textFont = f.mono,
					textSize = f.size,
					textColor = { hex = c.textSecondary, alpha = 1 },
					textAlignment = "left",
					frame = { x = d.padding + 28, y = yPos, w = 100, h = lineHeight },
				}

				local title = issue.title
				local maxChars = 85
				if #title > maxChars then
					title = title:sub(1, maxChars - 1) .. "..."
				end
				canvas[#canvas + 1] = {
					type = "text",
					text = title,
					textFont = f.mono,
					textSize = f.size,
					textColor = { hex = c.textPrimary, alpha = 1 },
					textAlignment = "left",
					frame = { x = d.padding + 130, y = yPos, w = boxWidth - d.padding - 150, h = lineHeight },
				}

				yPos = yPos + lineHeight
			end
			yPos = yPos + groupSpacing
		end
		yPos = yPos + sectionSpacing - groupSpacing
	end

	-- Slack section
	if #slackChannels > 0 or #slackDms > 0 then
		canvas[#canvas + 1] = {
			type = "text",
			text = "Slack",
			textFont = f.mono,
			textSize = f.sizeLarge,
			textColor = { hex = c.accentSlack, alpha = 1 },
			textAlignment = "left",
			frame = { x = d.padding, y = yPos, w = boxWidth - (d.padding * 2), h = sectionHeaderHeight },
		}
		yPos = yPos + sectionHeaderHeight

		-- Channel mentions
		if #slackChannels > 0 then
			canvas[#canvas + 1] = {
				type = "text",
				text = "Mentions",
				textFont = f.mono,
				textSize = f.size,
				textColor = { hex = c.accentOrange, alpha = 1 },
				textAlignment = "left",
				frame = { x = d.padding + 12, y = yPos, w = boxWidth - (d.padding * 2), h = groupHeaderHeight },
			}
			yPos = yPos + groupHeaderHeight

			for i, msg in ipairs(slackChannels) do
				if i > 5 then
					break
				end
				itemIndex = itemIndex + 1
				local shortcut = utils.getShortcutKey(itemIndex)

				-- Track clickable item
				table.insert(state.clickableItems, {
					type = "slack",
					y = yPos,
					h = lineHeight,
					x = d.padding,
					w = boxWidth - d.padding * 2,
					data = msg,
					key = shortcut,
				})
				if shortcut then
					state.keyMap[shortcut] = #state.clickableItems
				end

				local from = msg.username or "unknown"
				local channel = msg.channel and msg.channel.name or ""
				local text = msg.text or ""
				text = text:gsub("<@[^>]+[^>]*>", ""):gsub("<[^>]+>", ""):gsub("%s+", " "):gsub("^%s+", "")
				local maxChars = 65
				if #text > maxChars then
					text = text:sub(1, maxChars - 1) .. "..."
				end

				-- Shortcut key
				canvas[#canvas + 1] = {
					type = "text",
					text = shortcut or "",
					textFont = f.mono,
					textSize = f.size,
					textColor = { hex = c.accentSlack, alpha = 1 },
					textAlignment = "center",
					frame = { x = d.padding, y = yPos, w = 20, h = lineHeight },
				}

				canvas[#canvas + 1] = {
					type = "text",
					text = "#" .. channel,
					textFont = f.mono,
					textSize = f.size,
					textColor = { hex = c.textSecondary, alpha = 1 },
					textAlignment = "left",
					frame = { x = d.padding + 28, y = yPos, w = 120, h = lineHeight },
				}
				canvas[#canvas + 1] = {
					type = "text",
					text = from .. ": " .. text,
					textFont = f.mono,
					textSize = f.size,
					textColor = { hex = c.textPrimary, alpha = 1 },
					textAlignment = "left",
					frame = { x = d.padding + 155, y = yPos, w = boxWidth - d.padding - 175, h = lineHeight },
				}

				yPos = yPos + lineHeight
			end
			yPos = yPos + groupSpacing
		end

		-- DMs
		if #slackDms > 0 then
			canvas[#canvas + 1] = {
				type = "text",
				text = "DMs",
				textFont = f.mono,
				textSize = f.size,
				textColor = { hex = c.accentOrange, alpha = 1 },
				textAlignment = "left",
				frame = { x = d.padding + 12, y = yPos, w = boxWidth - (d.padding * 2), h = groupHeaderHeight },
			}
			yPos = yPos + groupHeaderHeight

			for i, msg in ipairs(slackDms) do
				if i > 5 then
					break
				end
				itemIndex = itemIndex + 1
				local shortcut = utils.getShortcutKey(itemIndex)

				-- Track clickable item
				table.insert(state.clickableItems, {
					type = "slack",
					y = yPos,
					h = lineHeight,
					x = d.padding,
					w = boxWidth - d.padding * 2,
					data = msg,
					key = shortcut,
				})
				if shortcut then
					state.keyMap[shortcut] = #state.clickableItems
				end

				local from = msg.username or "unknown"
				local text = msg.text or ""
				text = text:gsub("<@[^>]+[^>]*>", ""):gsub("<[^>]+>", ""):gsub("%s+", " "):gsub("^%s+", "")
				local maxChars = 70
				if #text > maxChars then
					text = text:sub(1, maxChars - 1) .. "..."
				end

				-- Shortcut key
				canvas[#canvas + 1] = {
					type = "text",
					text = shortcut or "",
					textFont = f.mono,
					textSize = f.size,
					textColor = { hex = c.accentSlack, alpha = 1 },
					textAlignment = "center",
					frame = { x = d.padding, y = yPos, w = 20, h = lineHeight },
				}

				canvas[#canvas + 1] = {
					type = "text",
					text = from,
					textFont = f.mono,
					textSize = f.size,
					textColor = { hex = c.textSecondary, alpha = 1 },
					textAlignment = "left",
					frame = { x = d.padding + 28, y = yPos, w = 120, h = lineHeight },
				}
				canvas[#canvas + 1] = {
					type = "text",
					text = text,
					textFont = f.mono,
					textSize = f.size,
					textColor = { hex = c.textPrimary, alpha = 1 },
					textAlignment = "left",
					frame = { x = d.padding + 155, y = yPos, w = boxWidth - d.padding - 175, h = lineHeight },
				}

				yPos = yPos + lineHeight
			end
		end
	end

	canvas:level(hs.canvas.windowLevels.overlay)
	canvas:clickActivating(false)
	canvas:behaviorAsLabels({ "canJoinAllSpaces", "stationary" })
	canvas:show()
	state.visible = true

	return canvas
end

--- Update the hover highlight on the main dashboard
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
