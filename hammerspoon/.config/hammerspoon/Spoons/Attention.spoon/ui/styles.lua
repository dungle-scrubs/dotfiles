--- Attention.spoon/ui/styles.lua
--- Centralized styling constants using design tokens

-- Use global path set by init.lua
local spoonPath = _G.AttentionSpoonPath
local tokens = dofile(spoonPath .. "/ui/tokens.lua")

local M = {}

-- Expose tokens for backward compatibility and direct access
M.tokens = tokens

-- Colors (derived from tokens for backward compatibility)
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
	accentLinear = tokens.color("accent.primary"),
	accentSlack = tokens.color("accent.slack"),
	accentAi = tokens.color("accent.ai"),
	accentOrange = tokens.color("accent.warning"),
	accentWarning = tokens.color("accent.warning"),
	accentSuccess = tokens.color("accent.success"),
	accentNotion = tokens.color("accent.notion"),
}

-- Fonts (derived from tokens)
M.fonts = {
	mono = tokens.font(),
	size = tokens.fontSize("base"),
	sizeLarge = tokens.fontSize("lg"),
	sizeSmall = tokens.fontSize("sm"),
	sizeXs = tokens.fontSize("xs"),
}

-- Dimensions (derived from tokens)
M.dimensions = {
	padding = tokens.spacing("lg"),
	boxWidth = tokens.dimension("boxWidth"),
	boxWidthWide = tokens.dimension("boxWidthWide"),
	boxHeight = tokens.dimension("boxHeight"),
	titleHeight = tokens.dimension("titleHeight"),
	footerHeight = tokens.dimension("footerHeight"),
	searchBarHeight = tokens.dimension("searchBarHeight"),
	sectionHeaderHeight = tokens.dimension("sectionHeaderHeight"),
	groupHeaderHeight = tokens.dimension("groupHeaderHeight"),
	lineHeight = tokens.dimension("lineHeight"),
	sectionSpacing = tokens.dimension("sectionSpacing"),
	groupSpacing = tokens.dimension("groupSpacing"),
	radiusSm = tokens.radius("sm"),
	radiusMd = tokens.radius("md"),
	radiusLg = tokens.radius("lg"),
}

--- Get CSS for Slack webview
--- @return string css The CSS styles
function M.getSlackWebviewCSS()
	local c = M.colors
	local f = M.fonts
	local d = M.dimensions
	return [[
* { margin: 0; padding: 0; box-sizing: border-box; }
html, body {
	height: 100%;
	background: transparent;
}
body {
	font-family: ]] .. f.mono .. [[, monospace;
	font-size: ]] .. f.size .. [[px;
	color: ]] .. c.textPrimary .. [[;
	overflow: hidden;
}
.container {
	display: flex;
	flex-direction: column;
	height: 100%;
	background: ]] .. c.bgPrimary .. [[;
	border-radius: ]] .. d.radiusLg .. [[px;
	border: 2px solid ]] .. c.accentSlack .. [[;
	overflow: hidden;
}
.header {
	display: flex;
	justify-content: space-between;
	align-items: center;
	padding: 12px ]] .. d.padding .. [[px;
	border-bottom: 1px solid ]] .. c.borderMedium .. [[;
	background: ]] .. c.bgSecondary .. [[;
}
.header-left, .header-right { display: flex; gap: 16px; }
.title { color: ]] .. c.textSecondary .. [[; font-size: ]] .. f.sizeLarge .. [[px; }
.btn { color: ]] .. c.textSecondary .. [[; cursor: pointer; }
.btn:hover { color: ]] .. c.textPrimary .. [[; }
.btn .key { color: ]] .. c.accentSlack .. [[; margin-right: 4px; }
.content {
	flex: 1;
	overflow-y: auto;
	padding: ]] .. d.padding .. [[px;
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
	border-radius: ]] .. d.radiusSm .. [[px;
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
.time { color: ]] .. c.textMuted .. [[; font-size: ]] .. f.sizeSmall .. [[px; }
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
	font-size: ]] .. f.sizeLarge .. [[px;
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
.hint-badge {
	display: inline-block;
	margin-left: 8px;
	padding: 1px 4px;
	background: ]] .. c.bgSecondary .. [[;
	border: 1px solid ]] .. c.borderMedium .. [[;
	border-radius: 3px;
	font-size: ]] .. f.sizeXs .. [[px;
	font-weight: bold;
	color: ]] .. c.textMuted .. [[;
	text-transform: uppercase;
	vertical-align: middle;
	opacity: 0.6;
	transition: all 0.15s ease;
}
body.hint-mode .hint-badge {
	opacity: 1;
	background: ]] .. c.accentLinear .. [[;
	border-color: ]] .. c.accentLinear .. [[;
	color: ]] .. c.textPrimary .. [[;
}
body.hint-mode .hint-badge.hint-dimmed {
	opacity: 0.3;
	background: ]] .. c.bgSecondary .. [[;
	border-color: ]] .. c.borderMedium .. [[;
	color: ]] .. c.textMuted .. [[;
}
body.hint-mode .hint-badge.hint-active {
	background: ]] .. c.accentSlack .. [[;
	border-color: ]] .. c.accentSlack .. [[;
}
.hint-matched {
	color: ]] .. c.textPrimary .. [[;
	opacity: 0.6;
}
.footer {
	display: flex;
	gap: 24px;
	padding: 10px ]] .. d.padding .. [[px;
	border-top: 1px solid ]] .. c.borderMedium .. [[;
	background: ]] .. c.bgSecondary .. [[;
}
.hint { color: ]] .. c.textMuted .. [[; font-size: ]] .. f.sizeSmall .. [[px; }
.hint .key { color: ]] .. c.accentSlack .. [[; }
.hint .label { color: ]] .. c.textMuted .. [[; }
]]
end

--- Get CSS for AI chat webview
--- @return string css The CSS styles for AI chat
function M.getAiChatWebviewCSS()
	local c = M.colors
	local f = M.fonts
	local d = M.dimensions
	return [[
* {
	margin: 0;
	padding: 0;
	box-sizing: border-box;
}
html, body {
	height: 100%;
	background: transparent;
}
body {
	font-family: ']] .. f.mono .. [[', 'SF Mono', monospace;
	font-size: ]] .. f.size .. [[px;
	color: #e0e0e0;
	display: flex;
	flex-direction: column;
	overflow: hidden;
}
.chat-container {
	display: flex;
	flex-direction: column;
	height: 100%;
	background: ]] .. c.bgPrimary .. [[;
	border-radius: ]] .. d.radiusLg .. [[px;
	border: 2px solid ]] .. c.accentAi .. [[;
	overflow: hidden;
}
.header {
	padding: 12px 16px;
	background: ]] .. c.bgSecondary .. [[;
	border-bottom: 1px solid ]] .. c.borderSubtle .. [[;
	display: flex;
	justify-content: space-between;
	align-items: center;
}
.header-title {
	color: ]] .. c.accentAi .. [[;
	font-size: ]] .. f.size .. [[px;
	font-weight: 600;
}
.header-hint {
	color: ]] .. c.textMuted .. [[;
	font-size: ]] .. f.sizeSmall .. [[px;
}
.header-hint kbd {
	background: ]] .. c.borderSubtle .. [[;
	padding: 2px 6px;
	border-radius: 3px;
	color: ]] .. c.accentAi .. [[;
}
.content-area {
	flex: 1;
	overflow-y: auto;
	padding: 16px;
	display: flex;
	flex-direction: column;
	gap: 12px;
}
.message-wrapper {
	display: flex;
	flex-direction: column;
	max-width: 85%;
}
.message-wrapper.user {
	align-self: flex-end;
	align-items: flex-end;
}
.message-wrapper.assistant,
.message-wrapper.error,
.message-wrapper.loading {
	align-self: flex-start;
	align-items: flex-start;
}
.message-model {
	font-size: 10px;
	color: ]] .. c.textMuted .. [[;
	margin-bottom: 4px;
	padding-left: 4px;
}
.message {
	padding: 10px 14px;
	border-radius: 8px;
	line-height: 1.5;
	white-space: pre-wrap;
	word-wrap: break-word;
}
.message.user {
	background: ]] .. c.accentAi .. [[;
	color: #fff;
}
.message.assistant {
	background: ]] .. c.bgTertiary .. [[;
	color: #e0e0e0;
	border: 1px solid ]] .. c.borderSubtle .. [[;
}
.message.error {
	background: #3a1a1a;
	color: #f87171;
	border: 1px solid #7f1d1d;
}
.loading-indicator {
	align-self: flex-start;
	display: inline-flex;
	padding: 10px 14px;
	background: ]] .. c.bgTertiary .. [[;
	border: 1px solid ]] .. c.borderSubtle .. [[;
	border-radius: 8px;
	color: #888;
}
.loading-text {
	color: #888;
}
.loading-dots {
	font-family: monospace;
	white-space: pre;
	color: #888;
}
.input-area {
	padding: 12px 16px;
	background: ]] .. c.bgSecondary .. [[;
	border-top: 1px solid ]] .. c.borderSubtle .. [[;
	display: flex;
	gap: 10px;
	align-items: flex-end;
}
.input-field {
	flex: 1;
	background: ]] .. c.bgPrimary .. [[;
	border: 1px solid ]] .. c.borderMedium .. [[;
	border-radius: ]] .. d.radiusMd .. [[px;
	padding: 10px 14px;
	color: #e0e0e0;
	font-family: inherit;
	font-size: ]] .. f.size .. [[px;
	outline: none;
	resize: none;
	min-height: 44px;
	max-height: 120px;
}
.input-field.model-search-input {
	min-height: 44px;
	max-height: 44px;
}
.input-field:focus {
	border-color: ]] .. c.accentAi .. [[;
}
.input-field::placeholder {
	color: ]] .. c.textMuted .. [[;
}
.input-field:disabled {
	opacity: 0.6;
}
.input-field.chat-input {
	flex: 1;
	min-width: 0;
}
.send-btn {
	background: ]] .. c.accentAi .. [[;
	color: #fff;
	border: none;
	border-radius: ]] .. d.radiusMd .. [[px;
	padding: 10px 18px;
	font-family: inherit;
	font-size: ]] .. f.size .. [[px;
	cursor: pointer;
	transition: background 0.2s;
	white-space: nowrap;
}
.send-btn:hover {
	background: #7c3aed;
}
.send-btn:disabled {
	background: #4a4a4a;
	cursor: not-allowed;
}
.empty-state {
	flex: 1;
	display: flex;
	align-items: center;
	justify-content: center;
	color: ]] .. c.textMuted .. [[;
	font-size: ]] .. f.size .. [[px;
}
.model-indicator {
	display: flex;
	align-items: center;
	gap: 6px;
	padding: 10px 12px;
	background: ]] .. c.bgTertiary .. [[;
	border-radius: ]] .. d.radiusMd .. [[px;
	cursor: pointer;
	transition: background 0.15s;
	white-space: nowrap;
}
.model-indicator:hover {
	background: ]] .. c.borderSubtle .. [[;
}
.model-name-display {
	color: #888;
	font-size: ]] .. f.sizeSmall .. [[px;
	max-width: 120px;
	overflow: hidden;
	text-overflow: ellipsis;
}
.model-hotkey {
	background: ]] .. c.borderSubtle .. [[;
	color: ]] .. c.accentAi .. [[;
	padding: 2px 8px;
	border-radius: ]] .. d.radiusSm .. [[px;
	font-size: ]] .. f.sizeXs .. [[px;
	font-weight: 600;
}
#app {
	flex: 1;
	display: flex;
	flex-direction: column;
	overflow: hidden;
	min-height: 0;
}
/* Model selector styles */
.model-list {
	display: flex;
	flex-direction: column;
	gap: 4px;
}
.model-item {
	display: flex;
	align-items: center;
	padding: 12px 16px;
	border-radius: ]] .. d.radiusMd .. [[px;
	cursor: pointer;
	gap: 12px;
	transition: background 0.15s;
}
.model-item:hover {
	background: ]] .. c.bgTertiary .. [[;
}
.model-item.active {
	background: ]] .. c.bgTertiary .. [[;
	border: 1px solid ]] .. c.accentAi .. [[;
}
.model-key {
	background: ]] .. c.borderSubtle .. [[;
	color: ]] .. c.accentAi .. [[;
	padding: 4px 10px;
	border-radius: ]] .. d.radiusSm .. [[px;
	font-size: ]] .. f.sizeSmall .. [[px;
	font-weight: 600;
	min-width: 28px;
	text-align: center;
}
.model-name {
	flex: 1;
	color: #e0e0e0;
}
.model-check {
	color: ]] .. c.accentAi .. [[;
	font-weight: bold;
}
.model-empty {
	padding: 20px;
	text-align: center;
	color: ]] .. c.textMuted .. [[;
}
]]
end

return M
