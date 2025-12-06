--- Attention.spoon/ui/slack.lua
--- Slack message detail webview rendering

local styles = dofile(_G.AttentionSpoonPath .. "/ui/styles.lua")
local slackApi = dofile(_G.AttentionSpoonPath .. "/api/slack.lua")

---@class AttentionSlackUI
local M = {}

--- Escape HTML special characters
--- @param text string The text to escape
--- @return string escaped The escaped text
--- @private
local function escapeHtml(text)
	if not text then
		return ""
	end
	local result = text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&#39;")
	return result
end

--- Format Slack message text with mentions, links, and formatting
--- @param text string The raw Slack message text
--- @return string formatted The HTML-formatted text
--- @private
local function formatSlackText(text)
	if not text then
		return ""
	end
	-- Process Slack formatting BEFORE escaping HTML
	-- User mentions: <@U123ABC|displayname> or <@U123ABC>
	text = text:gsub("<@([^|>]+)|([^>]+)>", function(uid, name)
		return "@" .. name
	end)
	text = text:gsub("<@([^>]+)>", function(uid)
		local name = slackApi.getUserName(uid)
		return "@" .. name
	end)
	-- Channel links: <#C123|channel-name>
	text = text:gsub("<#[^|>]+|([^>]+)>", "#%1")
	-- URL with display text: <http://url|display text>
	text = text:gsub("<(https?://[^|>]+)|([^>]+)>", function(url, display)
		return "LINK[" .. url .. "](" .. display .. ")"
	end)
	-- Plain URLs: <http://url>
	text = text:gsub("<(https?://[^>]+)>", "%1")

	-- Now escape HTML
	text = escapeHtml(text)

	-- Convert our link placeholders to actual links (after escaping)
	text = text:gsub('LINK%[([^%]]+)%]%(([^%)]+)%)', '<a href="%1" target="_blank">%2</a>')
	-- Make plain URLs clickable
	text = text:gsub("(https?://[%w%-%./_~:/?#%[%]@!$&amp;'()*+,;=%%]+)", '<a href="%1" target="_blank">%1</a>')
	-- Style @mentions
	text = text:gsub("@([%w%-_%.]+)", '<span class="mention">@%1</span>')
	-- Convert newlines to <br>
	text = text:gsub("\n", "<br>")
	return text
end

--- Format a Slack timestamp to human-readable date/time
--- @param ts string The Slack timestamp (e.g., "1234567890.123456")
--- @return string formatted The formatted date/time string
--- @private
local function formatTs(ts)
	if not ts then
		return ""
	end
	local timestamp = tonumber(ts:match("^(%d+)"))
	if timestamp then
		return os.date("%b %d, %H:%M", timestamp)
	end
	return ""
end

--- Render the Slack detail view using a webview
--- @param state table The state table
--- @param msg table|nil The Slack message to render (uses state.currentSlackMsg if nil)
--- @param thread table|nil The thread messages
--- @param keepScrollPosition boolean|nil If true, don't scroll to bottom
--- @param callbacks table Callback functions for actions
--- @return hs.webview webview The rendered webview
--- @example
---   local webview = slack.renderWebview(state, msg, thread, false, {
---     onBack = function() ... end,
---     onClose = function() ... end,
---     onOpenSlack = function(permalink) ... end,
---     onChannelUp = function() ... end,
---     onLoadMore = function() ... end,
---     onThreadClick = function(threadTs) ... end,
---   })
function M.renderWebview(state, msg, thread, keepScrollPosition, callbacks)
	callbacks = callbacks or {}

	-- Store for later use
	if msg then
		state.currentSlackMsg = msg
		state.currentSlackThread = thread or {}
	else
		msg = state.currentSlackMsg
		thread = state.currentSlackThread or {}
	end
	if not msg then
		return nil
	end

	-- Store oldest timestamp for pagination
	if thread and #thread > 0 and thread[1].ts then
		state.slackOldestTs = thread[1].ts
	end

	state.currentView = "slack-detail"

	-- Close canvas if open
	if state.canvas then
		state.canvas:delete()
		state.canvas = nil
	end

	local d = styles.dimensions
	local boxWidth = d.boxWidth
	local boxHeight = d.boxHeight
	local screen = hs.screen.mainScreen()
	local frame = screen:frame()
	local boxX = frame.x + (frame.w - boxWidth) / 2
	local boxY = frame.y + (frame.h - boxHeight) / 2

	-- Build HTML
	local channelName = msg.channel and msg.channel.name or "Direct Message"
	local isDM = msg.channel and msg.channel.is_im
	local modeLabel = state.slackViewMode == "history" and " (history)" or " (thread)"
	local titleText = isDM and ("DM with " .. escapeHtml(msg.username or "unknown"))
		or ("#" .. escapeHtml(channelName) .. modeLabel)
	local showChannelUp = state.slackViewMode == "thread"

	local css = styles.getSlackWebviewCSS()

	local html = [[
<!DOCTYPE html>
<html>
<head>
<style>
]] .. css .. [[
</style>
</head>
<body>
<div class="container">
	<div class="header">
		<div class="header-left">
			<span class="btn" onclick="window.webkit.messageHandlers.hammerspoon.postMessage('back')"><span class="key">b</span><- Back</span>
		</div>
		<div class="title">]] .. titleText .. [[</div>
		<div class="header-right">
]] .. (showChannelUp and [[			<span class="btn" onclick="window.webkit.messageHandlers.hammerspoon.postMessage('channelUp')"><span class="key">u</span>^ Channel</span>
]] or "") .. [[
			<span class="btn" onclick="window.webkit.messageHandlers.hammerspoon.postMessage('openSlack')"><span class="key">o</span>Open in Slack -></span>
		</div>
	</div>
	<div class="content" id="content">
]]

	-- Add messages based on view mode
	if state.slackViewMode == "history" then
		-- History mode: show messages with "X replies" links
		for _, threadMsg in ipairs(thread or {}) do
			local sender = escapeHtml(slackApi.getUserName(threadMsg.user))
			local msgTime = formatTs(threadMsg.ts)
			local msgText = formatSlackText(threadMsg.text)
			local replyCount = threadMsg.reply_count or 0
			local threadTs = threadMsg.thread_ts or threadMsg.ts

			html = html .. [[
		<div class="message">
			<div class="message-header">
				<span class="sender">]] .. sender .. [[</span>
				<span class="time">]] .. msgTime .. [[</span>
			</div>
			<div class="message-text">]] .. msgText .. [[</div>
]]
			if replyCount > 0 then
				html = html
					.. [[
			<span class="thread-link" onclick="window.webkit.messageHandlers.hammerspoon.postMessage('thread:]]
					.. threadTs
					.. [[')">]] .. replyCount .. [[ replies</span>
]]
			end
			html = html .. [[
		</div>
]]
		end
	elseif thread and #thread > 0 then
		-- Thread mode: show all messages
		for i, threadMsg in ipairs(thread) do
			local sender = escapeHtml(slackApi.getUserName(threadMsg.user))
			local msgTime = formatTs(threadMsg.ts)
			local msgText = formatSlackText(threadMsg.text)

			if i == 1 then
				html = html .. [[
		<div class="message">
			<div class="message-header">
				<span class="sender">]] .. sender .. [[</span>
				<span class="time">]] .. msgTime .. [[</span>
			</div>
			<div class="message-text">]] .. msgText .. [[</div>
		</div>
]]
				if #thread > 1 then
					html = html .. [[
		<div class="thread-separator">Thread (]] .. (#thread - 1) .. [[ replies)</div>
]]
				end
			else
				html = html .. [[
		<div class="message reply">
			<div class="message-header">
				<span class="sender">]] .. sender .. [[</span>
				<span class="time">]] .. msgTime .. [[</span>
			</div>
			<div class="message-text">]] .. msgText .. [[</div>
		</div>
]]
			end
		end
	else
		-- No thread data - show search result message
		local sender = escapeHtml(msg.username or "unknown")
		local msgTime = formatTs(msg.ts)
		local msgText = formatSlackText(msg.text)
		html = html .. [[
		<div class="message">
			<div class="message-header">
				<span class="sender">]] .. sender .. [[</span>
				<span class="time">]] .. msgTime .. [[</span>
			</div>
			<div class="message-text">]] .. msgText .. [[</div>
		</div>
		<div class="thread-separator">]] .. (isDM and "(No thread replies)" or "(Press 'o' to view thread in Slack)") .. [[</div>
]]
	end

	html = html .. [[
	</div>
	<div class="footer">
		<span class="hint"><span class="key">j/k</span> <span class="label">scroll</span></span>
		<span class="hint"><span class="key">^d/^u</span> <span class="label">page</span></span>
		<span class="hint"><span class="key">o</span> <span class="label">open</span></span>
		<span class="hint"><span class="key">b</span> <span class="label">back</span></span>
]] .. (showChannelUp and [[		<span class="hint"><span class="key">u</span> <span class="label">channel</span></span>
]] or "") .. [[
		<span class="hint"><span class="key">esc</span> <span class="label">close</span></span>
	</div>
</div>
<script>
var isLoadingMore = false;
window.onload = function() {
	var content = document.getElementById('content');
	]] .. (keepScrollPosition and "isLoadingMore = false;" or "content.scrollTop = content.scrollHeight;") .. [[
};
document.getElementById('content').addEventListener('scroll', function() {
	var content = this;
	if (content.scrollTop < 50 && !isLoadingMore) {
		isLoadingMore = true;
		window.webkit.messageHandlers.hammerspoon.postMessage('loadMore');
	}
});
document.addEventListener('keydown', function(e) {
	var content = document.getElementById('content');
	var scrollAmount = 60;
	var pageAmount = content.clientHeight * 0.8;

	if (e.key === 'j') {
		content.scrollTop += scrollAmount;
		e.preventDefault();
	} else if (e.key === 'k') {
		content.scrollTop -= scrollAmount;
		e.preventDefault();
	} else if (e.key === 'd' && e.ctrlKey) {
		content.scrollTop += pageAmount;
		e.preventDefault();
	} else if (e.key === 'u' && e.ctrlKey) {
		content.scrollTop -= pageAmount;
		e.preventDefault();
	} else if (e.key === 'u' && !e.ctrlKey && !e.metaKey && ]] .. (showChannelUp and "true" or "false") .. [[) {
		window.webkit.messageHandlers.hammerspoon.postMessage('channelUp');
		e.preventDefault();
	} else if (e.key === 'b') {
		window.webkit.messageHandlers.hammerspoon.postMessage('back');
		e.preventDefault();
	} else if (e.key === 'o') {
		window.webkit.messageHandlers.hammerspoon.postMessage('openSlack');
		e.preventDefault();
	} else if (e.key === 'Escape') {
		window.webkit.messageHandlers.hammerspoon.postMessage('close');
		e.preventDefault();
	}
});
</script>
</body>
</html>
]]

	-- Stop canvas event watchers - they interfere with webview mouse events
	if state.escapeWatcher then
		state.escapeWatcher:stop()
		state.escapeWatcher = nil
	end
	if state.clickWatcher then
		state.clickWatcher:stop()
		state.clickWatcher = nil
	end
	if state.hoverWatcher then
		state.hoverWatcher:stop()
		state.hoverWatcher = nil
	end

	-- Create webview with user content controller
	if state.webview then
		state.webview:delete()
	end
	if state.webviewUC then
		state.webviewUC = nil
	end

	-- Store permalink for callback use
	local msgPermalink = msg.permalink

	-- Create user content controller for JS -> Lua communication
	state.webviewUC = hs.webview.usercontent.new("hammerspoon")
	state.webviewUC:setCallback(function(message)
		local action = message.body
		if action == "back" then
			if callbacks.onBack then
				callbacks.onBack()
			end
		elseif action == "close" then
			if callbacks.onClose then
				callbacks.onClose()
			end
		elseif action == "openSlack" then
			if callbacks.onOpenSlack then
				callbacks.onOpenSlack(msgPermalink)
			end
		elseif action == "channelUp" then
			if callbacks.onChannelUp then
				callbacks.onChannelUp()
			end
		elseif action:match("^thread:") then
			local threadTs = action:match("^thread:(.+)$")
			if threadTs and callbacks.onThreadClick then
				callbacks.onThreadClick(threadTs)
			end
		elseif action == "loadMore" then
			if callbacks.onLoadMore then
				callbacks.onLoadMore()
			end
		end
	end)

	state.webview =
		hs.webview.new({ x = boxX, y = boxY, w = boxWidth, h = boxHeight }, { developerExtrasEnabled = false }, state.webviewUC)
	state.webview:windowStyle({ "borderless", "closable" })
	state.webview:level(hs.canvas.windowLevels.overlay)
	state.webview:allowTextEntry(true)
	state.webview:allowNewWindows(false)
	state.webview:transparent(false)

	-- Handle link clicks - open in browser instead of navigating
	state.webview:navigationCallback(function(action, wv, navType, url)
		if action == "navigationAction" and url and url ~= "about:blank" and not url:match("^data:") then
			hs.urlevent.openURL(url)
			return false
		end
		return true
	end)

	state.webview:html(html)
	state.webview:show()
	state.webview:bringToFront()
	state.visible = true
	state.canvasFrame = { x = boxX, y = boxY, w = boxWidth, h = boxHeight }

	-- Create eventtap for keyboard handling
	state.webviewKeyWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
		local keyCode = event:getKeyCode()
		local flags = event:getFlags()

		-- Escape - close
		if keyCode == 53 then
			if callbacks.onClose then
				callbacks.onClose()
			end
			return true
		end

		-- 'b' - back (keycode 11)
		if keyCode == 11 and not flags.ctrl and not flags.cmd then
			if callbacks.onBack then
				callbacks.onBack()
			end
			return true
		end

		-- 'o' - open in Slack (keycode 31)
		if keyCode == 31 and not flags.ctrl and not flags.cmd then
			if callbacks.onOpenSlack then
				callbacks.onOpenSlack(msgPermalink)
			end
			return true
		end

		-- 'u' - channel up (keycode 32) - only in thread mode
		if keyCode == 32 and not flags.ctrl and not flags.cmd and showChannelUp then
			if callbacks.onChannelUp then
				callbacks.onChannelUp()
			end
			return true
		end

		-- 'j' - scroll down (keycode 38)
		if keyCode == 38 and not flags.ctrl then
			state.webview:evaluateJavaScript("document.getElementById('content').scrollTop += 60;", nil)
			return true
		end

		-- 'k' - scroll up (keycode 40)
		if keyCode == 40 and not flags.ctrl then
			state.webview:evaluateJavaScript("document.getElementById('content').scrollTop -= 60;", nil)
			return true
		end

		-- Ctrl+d - page down (keycode 2)
		if keyCode == 2 and flags.ctrl then
			state.webview:evaluateJavaScript("var c = document.getElementById('content'); c.scrollTop += c.clientHeight * 0.8;", nil)
			return true
		end

		-- Ctrl+u - page up (keycode 32)
		if keyCode == 32 and flags.ctrl then
			state.webview:evaluateJavaScript("var c = document.getElementById('content'); c.scrollTop -= c.clientHeight * 0.8;", nil)
			return true
		end

		return true -- block all other keys
	end)
	state.webviewKeyWatcher:start()

	return state.webview
end

--- Close the Slack webview and clean up resources
--- @param state table The state table
function M.closeWebview(state)
	if state.webviewKeyWatcher then
		state.webviewKeyWatcher:stop()
		state.webviewKeyWatcher = nil
	end
	if state.webview then
		state.webview:delete()
		state.webview = nil
	end
end

--- Reset the loading flag in the webview (for pagination)
--- @param state table The state table
function M.resetLoadingFlag(state)
	if state.webview then
		state.webview:evaluateJavaScript("isLoadingMore = false;", nil)
	end
end

return M
