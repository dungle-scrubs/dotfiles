--- Attention.spoon/ui/styles.lua
--- Shared styles, colors, and CSS for the Attention dashboard
--- @module ui.styles

local M = {}

--- Color palette used throughout the UI
--- @type table<string, string>
M.colors = {
	-- Backgrounds
	bgPrimary = "#1a1a1a",
	bgSecondary = "#252525",
	bgHover = "#ffffff",  -- with alpha 0.08

	-- Borders
	borderDark = "#333333",
	borderMedium = "#444444",

	-- Text
	textPrimary = "#ffffff",
	textSecondary = "#888888",
	textMuted = "#666666",
	textDim = "#555555",

	-- Accents
	accentLinear = "#5e6ad2",    -- Linear purple
	accentSlack = "#e01e5a",     -- Slack pink
	accentLink = "#36a3eb",      -- Links blue
	accentOrange = "#f97316",    -- Usernames

	-- Priority colors
	priorityUrgent = "#f87171",
	priorityHigh = "#fb923c",
	priorityMedium = "#facc15",
	priorityLow = "#94a3b8",
}

--- Standard dimensions
--- @type table<string, number>
M.dimensions = {
	boxWidth = 900,
	boxHeight = 600,
	padding = 24,
	lineHeight = 22,
	fontSize = 14,
	footerHeight = 36,
}

--- Font configuration
--- @type table<string, string|number>
M.fonts = {
	mono = "CaskaydiaCove Nerd Font Mono",
	size = 14,
	sizeSmall = 12,
	sizeLarge = 16,
}

--- Generate CSS for the Slack webview
--- @param options table|nil Optional overrides for styles
--- @return string css The complete CSS stylesheet
function M.getSlackWebviewCSS(options)
	options = options or {}
	local c = M.colors
	local d = M.dimensions
	local f = M.fonts

	return [[
* { margin: 0; padding: 0; box-sizing: border-box; }
body {
	font-family: ']] .. f.mono .. [[', 'SF Mono', Menlo, monospace;
	font-size: ]] .. f.size .. [[px;
	line-height: 1.5;
	background: ]] .. c.bgPrimary .. [[;
	color: ]] .. c.textPrimary .. [[;
	padding: 0;
	overflow: hidden;
}
.container {
	display: flex;
	flex-direction: column;
	height: 100vh;
	border: 2px solid ]] .. c.accentSlack .. [[;
	border-radius: 10px;
	overflow: hidden;
}
.header {
	padding: 16px ]] .. d.padding .. [[px;
	border-bottom: 1px solid ]] .. c.borderDark .. [[;
	display: flex;
	justify-content: space-between;
	align-items: center;
	flex-shrink: 0;
}
.header-left, .header-right { display: flex; gap: 8px; align-items: center; }
.btn {
	color: ]] .. c.textSecondary .. [[;
	cursor: pointer;
	padding: 4px 8px;
	border-radius: 4px;
	transition: background 0.15s;
	user-select: none;
}
.btn:hover { background: rgba(255,255,255,0.1); }
.btn .key { color: ]] .. c.accentSlack .. [[; margin-right: 4px; }
.mention {
	color: ]] .. c.accentLink .. [[;
	background: rgba(54, 163, 235, 0.15);
	padding: 1px 4px;
	border-radius: 3px;
}
.thread-link {
	color: ]] .. c.accentLink .. [[;
	cursor: pointer;
	font-size: ]] .. f.sizeSmall .. [[px;
	margin-top: 6px;
	display: inline-block;
	padding: 2px 6px;
	border-radius: 4px;
	transition: background 0.15s;
}
.thread-link:hover { background: rgba(54, 163, 235, 0.15); text-decoration: underline; }
.title {
	color: #8b8b8b;
	font-size: ]] .. f.sizeLarge .. [[px;
	text-align: center;
	flex: 1;
}
.content {
	flex: 1;
	overflow-y: auto;
	padding: 20px ]] .. d.padding .. [[px;
	user-select: text;
	cursor: text;
}
.message { margin-bottom: 20px; }
.message.reply { margin-left: 16px; padding-left: 12px; border-left: 2px solid ]] .. c.borderDark .. [[; }
.message-header { display: flex; justify-content: space-between; align-items: baseline; margin-bottom: 6px; }
.sender { color: ]] .. c.accentOrange .. [[; font-weight: 500; }
.message.reply .sender { font-size: 13px; }
.time { color: ]] .. c.textMuted .. [[; font-size: ]] .. f.sizeSmall .. [[px; }
.message-text { color: ]] .. c.textPrimary .. [[; white-space: pre-wrap; word-wrap: break-word; }
.message.reply .message-text { color: #ccc; font-size: 13px; }
.thread-separator {
	border-top: 1px solid ]] .. c.borderMedium .. [[;
	margin: 20px 0 16px 0;
	padding-top: 12px;
	color: ]] .. c.accentSlack .. [[;
	font-size: ]] .. f.size .. [[px;
}
a { color: ]] .. c.accentLink .. [[; text-decoration: none; cursor: pointer; }
a:hover { text-decoration: underline; }
.footer {
	padding: 10px ]] .. d.padding .. [[px;
	border-top: 1px solid ]] .. c.borderMedium .. [[;
	background: ]] .. c.bgSecondary .. [[;
	display: flex;
	gap: 16px;
	flex-shrink: 0;
	font-size: ]] .. f.sizeSmall .. [[px;
}
.hint .key { color: ]] .. c.accentSlack .. [[; }
.hint .label { color: ]] .. c.textMuted .. [[; }
/* Scrollbar styling */
::-webkit-scrollbar { width: 8px; }
::-webkit-scrollbar-track { background: ]] .. c.bgSecondary .. [[; }
::-webkit-scrollbar-thumb { background: ]] .. c.borderMedium .. [[; border-radius: 4px; }
::-webkit-scrollbar-thumb:hover { background: #555; }
]]
end

return M
