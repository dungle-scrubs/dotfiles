--- Attention.spoon/ui/canvas/helpers.lua
--- Shared canvas rendering utilities

-- Use global path set by init.lua
local spoonPath = _G.AttentionSpoonPath
local tokens = dofile(spoonPath .. "/ui/tokens.lua")

---@class AttentionCanvasHelpers
local M = {}

-- Cached token values for performance
M.colors = {
	bgPrimary = tokens.color("bg.primary"),
	bgSecondary = tokens.color("bg.secondary"),
	bgTertiary = tokens.color("bg.tertiary"),
	textPrimary = tokens.color("text.primary"),
	textSecondary = tokens.color("text.secondary"),
	textMuted = tokens.color("text.muted"),
	textDim = tokens.color("text.dim"),
	borderSubtle = tokens.color("border.subtle"),
	borderMedium = tokens.color("border.medium"),
	accentPrimary = tokens.color("accent.primary"),
	accentSlack = tokens.color("accent.slack"),
	accentAi = tokens.color("accent.ai"),
	accentWarning = tokens.color("accent.warning"),
	accentSuccess = tokens.color("accent.success"),
	accentNotion = tokens.color("accent.notion"),
}

M.font = tokens.font()
M.fontSize = tokens.fontSize("base")
M.fontSizeLg = tokens.fontSize("lg")
M.fontSizeSm = tokens.fontSize("sm")

M.padding = tokens.spacing("lg")
M.radiusLg = tokens.radius("lg")
M.radiusMd = tokens.radius("md")
M.radiusSm = tokens.radius("sm")

--- Get centered screen position for a box
--- @param width number Box width
--- @param height number Box height
--- @return table frame {x, y, w, h} frame for the canvas
function M.getCenteredFrame(width, height)
	local screen = hs.screen.mainScreen()
	local screenFrame = screen:frame()
	return {
		x = screenFrame.x + (screenFrame.w - width) / 2,
		y = screenFrame.y + (screenFrame.h - height) / 2,
		w = width,
		h = height,
	}
end

--- Create a standard background element
--- @param color string|nil Hex color (defaults to bgPrimary)
--- @param alpha number|nil Alpha value (defaults to 0.95)
--- @return table element Canvas element definition
function M.background(color, alpha)
	return {
		type = "rectangle",
		action = "fill",
		fillColor = { hex = color or M.colors.bgPrimary, alpha = alpha or 0.95 },
		roundedRectRadii = { xRadius = M.radiusLg, yRadius = M.radiusLg },
	}
end

--- Create a standard border element
--- @param color string|nil Hex color (defaults to accentPrimary)
--- @param alpha number|nil Alpha value (defaults to 0.9)
--- @return table element Canvas element definition
function M.border(color, alpha)
	return {
		type = "rectangle",
		action = "stroke",
		strokeColor = { hex = color or M.colors.accentPrimary, alpha = alpha or 0.9 },
		strokeWidth = 2,
		roundedRectRadii = { xRadius = M.radiusLg, yRadius = M.radiusLg },
	}
end

--- Create a text element
--- @param text string The text to display
--- @param opts table Options: x, y, w, h, color, size, align
--- @return table element Canvas element definition
function M.text(text, opts)
	opts = opts or {}
	return {
		type = "text",
		text = text,
		textFont = M.font,
		textSize = opts.size or M.fontSize,
		textColor = { hex = opts.color or M.colors.textPrimary, alpha = opts.alpha or 1 },
		textAlignment = opts.align or "left",
		frame = {
			x = opts.x or 0,
			y = opts.y or 0,
			w = opts.w or 100,
			h = opts.h or (opts.size or M.fontSize) + 4,
		},
	}
end

--- Create a rectangle fill element
--- @param opts table Options: x, y, w, h, color, alpha, radius
--- @return table element Canvas element definition
function M.rect(opts)
	opts = opts or {}
	local radius = opts.radius or 0
	local elem = {
		type = "rectangle",
		action = "fill",
		fillColor = { hex = opts.color or M.colors.bgSecondary, alpha = opts.alpha or 1 },
		frame = {
			x = opts.x or 0,
			y = opts.y or 0,
			w = opts.w or 100,
			h = opts.h or 20,
		},
	}
	if radius > 0 then
		elem.roundedRectRadii = { xRadius = radius, yRadius = radius }
	end
	return elem
end

--- Create a horizontal line element
--- @param opts table Options: x, y, w, color, alpha
--- @return table element Canvas element definition
function M.line(opts)
	opts = opts or {}
	return {
		type = "rectangle",
		action = "fill",
		fillColor = { hex = opts.color or M.colors.borderMedium, alpha = opts.alpha or 1 },
		frame = {
			x = opts.x or 0,
			y = opts.y or 0,
			w = opts.w or 100,
			h = 1,
		},
	}
end

--- Create a hover placeholder element (invisible rect)
--- @return table element Canvas element definition
function M.hoverPlaceholder()
	return {
		type = "rectangle",
		action = "fill",
		fillColor = { hex = "#ffffff", alpha = 0 },
		frame = { x = 0, y = 0, w = 0, h = 0 },
	}
end

--- Create a clip region
--- @param x number X position
--- @param y number Y position
--- @param w number Width
--- @param h number Height
--- @return table element Canvas element definition
function M.clip(x, y, w, h)
	return {
		type = "rectangle",
		action = "clip",
		frame = { x = x, y = y, w = w, h = h },
	}
end

--- Reset clip region
--- @return table element Canvas element definition
function M.resetClip()
	return { type = "resetClip" }
end

--- Truncate text to max characters with ellipsis
--- @param text string The text to truncate
--- @param maxChars number Maximum characters
--- @return string truncated The truncated text
function M.truncate(text, maxChars)
	if not text then return "" end
	if #text > maxChars then
		return text:sub(1, maxChars - 1) .. "..."
	end
	return text
end

--- Calculate line height for text with padding
--- @param fontSize number|nil The font size (defaults to base)
--- @return number lineHeight The line height in pixels
function M.lineHeight(fontSize)
	fontSize = fontSize or M.fontSize
	return fontSize + 10
end

--- Get max canvas height based on screen
--- @return number maxHeight Maximum canvas height
function M.maxCanvasHeight()
	local screen = hs.screen.mainScreen()
	local frame = screen:frame()
	return frame.h - 100
end

return M
