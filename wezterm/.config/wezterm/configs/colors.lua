---@class Colors
---@field black string
---@field white string
---@field yellow string
---@field soft_red string
---@field purple string
---@field blue string
---@field blue_alt string
---@field cyan string
---@field green string
---@field red string
---@field background string
---@field foreground string
---@field inactive_fg string
---@field text string
---@field key string

---Shared color palette for WezTerm configuration
---@type Colors
local M = {
	black = "#000000",
	white = "#d8d8d8",
	yellow = "#ccb266",
	yellow_alt = "#d8a274",
	soft_red = "#bf8585",
	purple = "#7F718E",
	purple_alt = "#c678dd",
	blue = "#647f9d",
	blue_alt = "#6f88a6",
	blue_bright = "#61afef",
	cyan = "#56b6c2",
	green = "#98c379",
	red = "#e06c75",
	background = "#1a1c23",
	foreground = "#b1b1b1",
	inactive_fg = "#737373",
	text = "#808080",
	key = "#6cb6ff",
}

return M
