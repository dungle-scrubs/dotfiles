--- Attention.spoon/ui/styles.lua
--- Centralized styling constants

local M = {}

-- Colors
M.colors = {
	bgPrimary = "#1a1a1a",
	bgSecondary = "#252525",
	textPrimary = "#ffffff",
	textSecondary = "#8b8b8b",
	textMuted = "#666666",
	borderMedium = "#444444",
	accentLinear = "#5e6ad2",
	accentSlack = "#e01e5a",
	accentOrange = "#f97316",
}

-- Fonts
M.fonts = {
	mono = "CaskaydiaCove Nerd Font Mono",
	size = 14,
	sizeLarge = 16,
	sizeSmall = 12,
}

-- Dimensions
M.dimensions = {
	padding = 24,
	boxWidth = 900,
	boxHeight = 600,
	titleHeight = 36,
	footerHeight = 40,
	sectionHeaderHeight = 30,
	groupHeaderHeight = 26,
	sectionSpacing = 20,
	groupSpacing = 8,
}

--- Get CSS for Slack webview
--- @return string css The CSS styles
function M.getSlackWebviewCSS()
	local c = M.colors
	return [[
* { margin: 0; padding: 0; box-sizing: border-box; }
html, body {
	height: 100%;
	background: transparent;
}
body {
	font-family: ]] .. M.fonts.mono .. [[, monospace;
	font-size: ]] .. M.fonts.size .. [[px;
	color: ]] .. c.textPrimary .. [[;
	overflow: hidden;
}
.container {
	display: flex;
	flex-direction: column;
	height: 100%;
	background: ]] .. c.bgPrimary .. [[;
	border-radius: 10px;
	border: 2px solid ]] .. c.accentSlack .. [[;
	overflow: hidden;
}
.header {
	display: flex;
	justify-content: space-between;
	align-items: center;
	padding: 12px ]] .. M.dimensions.padding .. [[px;
	border-bottom: 1px solid ]] .. c.borderMedium .. [[;
	background: ]] .. c.bgSecondary .. [[;
}
.header-left, .header-right { display: flex; gap: 16px; }
.title { color: ]] .. c.textSecondary .. [[; font-size: 16px; }
.btn { color: ]] .. c.textSecondary .. [[; cursor: pointer; }
.btn:hover { color: ]] .. c.textPrimary .. [[; }
.btn .key { color: ]] .. c.accentSlack .. [[; margin-right: 4px; }
.content {
	flex: 1;
	overflow-y: auto;
	padding: ]] .. M.dimensions.padding .. [[px;
	overflow-anchor: auto;
	overscroll-behavior: contain;
}
.content::-webkit-scrollbar {
	width: 8px;
}
.content::-webkit-scrollbar-track {
	background: transparent;
}
.content::-webkit-scrollbar-thumb {
	background: ]] .. c.borderMedium .. [[;
	border-radius: 4px;
}
.content::-webkit-scrollbar-thumb:hover {
	background: ]] .. c.borderMedium .. [[;
}
.message {
	margin-bottom: 16px;
	padding-bottom: 16px;
	border-bottom: 1px solid ]] .. c.borderMedium .. [[;
}
.message:last-child { border-bottom: none; }
.message.reply {
	margin-left: 24px;
	padding-left: 12px;
	border-left: 2px solid ]] .. c.accentSlack .. [[;
	border-bottom: none;
	padding-bottom: 8px;
	margin-bottom: 8px;
}
.message-header {
	display: flex;
	justify-content: space-between;
	margin-bottom: 4px;
}
.sender { color: ]] .. c.accentOrange .. [[; font-weight: bold; }
.time { color: ]] .. c.textMuted .. [[; font-size: 12px; }
.message-text { color: ]] .. c.textPrimary .. [[; line-height: 1.5; white-space: pre-wrap; }
.message-text a.link { color: ]] .. c.accentLinear .. [[; cursor: pointer; text-decoration: none; }
.message-text a.link:hover { text-decoration: underline; }
.message-text .mention { color: ]] .. c.accentSlack .. [[; background: rgba(224, 30, 90, 0.15); padding: 1px 4px; border-radius: 3px; }
.loading-indicator {
	text-align: center;
	padding: 16px;
	color: ]] .. c.textMuted .. [[;
	height: 48px;
	opacity: 0;
	pointer-events: none;
	overflow-anchor: none;
}
.loading-indicator.visible { opacity: 1; }
.initial-loading {
	display: flex;
	align-items: center;
	justify-content: center;
	height: 100%;
	color: ]] .. c.accentSlack .. [[;
	font-size: 16px;
}
.thread-separator {
	text-align: center;
	color: ]] .. c.accentSlack .. [[;
	padding: 12px 0;
	border-top: 1px solid ]] .. c.borderMedium .. [[;
	margin-top: 8px;
}
.thread-link {
	color: ]] .. c.accentSlack .. [[;
	cursor: pointer;
	font-size: 13px;
	margin-top: 8px;
	display: inline-block;
}
.thread-link:hover { text-decoration: underline; }
.footer {
	display: flex;
	gap: 24px;
	padding: 10px ]] .. M.dimensions.padding .. [[px;
	border-top: 1px solid ]] .. c.borderMedium .. [[;
	background: ]] .. c.bgSecondary .. [[;
}
.hint { color: ]] .. c.textMuted .. [[; font-size: 12px; }
.hint .key { color: ]] .. c.accentSlack .. [[; }
.hint .label { color: ]] .. c.textMuted .. [[; }
]]
end

return M
