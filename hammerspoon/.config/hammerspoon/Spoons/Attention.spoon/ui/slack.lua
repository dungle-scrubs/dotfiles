--- Attention.spoon/ui/slack.lua
--- Slack message detail webview rendering

-- Use global path set by init.lua
local spoonPath = _G.AttentionSpoonPath
local styles = dofile(spoonPath .. "/ui/styles.lua")

---@class AttentionSlackUI
local M = {}

-- Will be set by init.lua to share the same instance
M.slackApi = nil

--- Escape HTML special characters
--- @param text string The text to escape
--- @return string escaped The escaped text
local function escapeHtml(text)
	if not text then return "" end
	return text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&#39;")
end

--- Format Slack message text with mentions, links, and formatting
--- @param text string The raw Slack message text
--- @return string formatted The HTML-formatted text
local function formatSlackText(text)
	if not text then return "" end
	-- Process Slack formatting BEFORE escaping HTML
	-- User mentions: <@U123ABC|displayname> or <@U123ABC>
	text = text:gsub("<@([^|>]+)|([^>]+)>", function(uid, name)
		return "@" .. name
	end)
	text = text:gsub("<@([^>]+)>", function(uid)
		local name = M.slackApi.getUserName(uid)
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
	-- Use onclick to post message to Hammerspoon for link handling
	text = text:gsub('LINK%[([^%]]+)%]%(([^%)]+)%)', function(url, display)
		return '<a href="#" class="link" data-url="' .. url .. '">' .. display .. '</a>'
	end)
	-- Make plain URLs clickable
	text = text:gsub("(https?://[%w%-%./_~:/?#%[%]@!$&;'()*+,;=%%]+)", function(url)
		return '<a href="#" class="link" data-url="' .. url .. '">' .. url .. '</a>'
	end)
	-- Style @mentions
	text = text:gsub("@([%w%-_%.]+)", '<span class="mention">@%1</span>')
	-- Convert newlines to <br>
	text = text:gsub("\n", "<br>")
	return text
end

--- Format a Slack timestamp to human-readable date/time
--- @param ts string The Slack timestamp (e.g., "1234567890.123456")
--- @return string formatted The formatted date/time string
local function formatTs(ts)
	if not ts then return "" end
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
-- Counter to track webview instances
local webviewInstanceId = 0

function M.renderWebview(state, msg, thread, keepScrollPosition, callbacks)
	webviewInstanceId = webviewInstanceId + 1
	local currentInstanceId = webviewInstanceId
	print("[SlackUI] renderWebview called - CREATING WEBVIEW #" .. currentInstanceId)
	state.webviewInstanceId = currentInstanceId
	callbacks = callbacks or {}

	-- Store for later use
	if msg then
		state.currentSlackMsg = msg
		state.currentSlackThread = thread or {}
	else
		msg = state.currentSlackMsg
		thread = state.currentSlackThread or {}
	end
	if not msg then return nil end

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
		<div class="loading-indicator" id="loadingIndicator">Loading older messages...</div>
]]

	-- Add messages based on view mode
	if state.slackViewMode == "history" then
		-- History mode: show messages with "X replies" links
		for _, threadMsg in ipairs(thread or {}) do
			local sender = escapeHtml(M.slackApi.getUserName(threadMsg.user))
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
				html = html .. [[
			<span class="thread-link" onclick="window.webkit.messageHandlers.hammerspoon.postMessage('thread:]] .. threadTs .. [[')">]] .. replyCount .. [[ replies</span>
]]
			end
			html = html .. [[
		</div>
]]
		end
	elseif thread and #thread > 0 then
		-- Thread mode: show all messages
		for i, threadMsg in ipairs(thread) do
			local sender = escapeHtml(M.slackApi.getUserName(threadMsg.user))
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
		<span class="hint"><span class="key">gg/G</span> <span class="label">top/btm</span></span>
		<span class="hint"><span class="key">^d/^u</span> <span class="label">page</span></span>
		<span class="hint"><span class="key">o</span> <span class="label">open</span></span>
		<span class="hint"><span class="key">b</span> <span class="label">back</span></span>
]] .. (showChannelUp and [[		<span class="hint"><span class="key">u</span> <span class="label">channel</span></span>
]] or "") .. [[
	</div>
</div>
<script>
var isLoadingMore = false;
var loadMoreSentAt = 0;
var loadingIndicator = document.getElementById('loadingIndicator');

window.onload = function() {
	console.log('[slack-webview] window.onload fired');
	var content = document.getElementById('content');
	]] .. (keepScrollPosition and [[
	// After prepending content, scroll down past the trigger zone and block immediate re-load
	console.log('[slack-webview] keepScrollPosition=true, setting scrollTop=150');
	isLoadingMore = true;
	content.scrollTop = 150;
	// Allow loading more after a brief delay
	setTimeout(function() {
		console.log('[slack-webview] Allowing load more after delay');
		isLoadingMore = false;
	}, 500);
	]] or [[
	console.log('[slack-webview] keepScrollPosition=false, scrolling to bottom');
	content.scrollTop = content.scrollHeight;
	]]) .. [[
};

// Handle link clicks
document.addEventListener('click', function(e) {
	var link = e.target.closest('a.link');
	if (link) {
		e.preventDefault();
		var url = link.getAttribute('data-url');
		if (url) {
			window.webkit.messageHandlers.hammerspoon.postMessage('openUrl:' + url);
		}
	}
});

document.getElementById('content').addEventListener('scroll', function() {
	var content = this;
	var now = Date.now();
	if (content.scrollTop < 50 && !isLoadingMore && (now - loadMoreSentAt > 1000)) {
		console.log('[slack-webview] Scroll triggered loadMore, scrollTop:', content.scrollTop);
		isLoadingMore = true;
		loadMoreSentAt = now;
		loadingIndicator.classList.add('visible');
		window.webkit.messageHandlers.hammerspoon.postMessage('loadMore');
	}
});

var lastKeyTime = 0;
var lastKey = '';

document.addEventListener('keydown', function(e) {
	var content = document.getElementById('content');
	var scrollAmount = 60;
	var pageAmount = content.clientHeight * 0.8;
	var now = Date.now();

	// Handle gg (go to top) - two g's within 500ms
	if (e.key === 'g' && !e.shiftKey) {
		if (lastKey === 'g' && (now - lastKeyTime) < 500) {
			content.scrollTop = 0;
			lastKey = '';
			e.preventDefault();
			return;
		}
		lastKey = 'g';
		lastKeyTime = now;
		e.preventDefault();
		return;
	}

	// Handle G (go to bottom)
	if (e.key === 'G' && e.shiftKey) {
		content.scrollTop = content.scrollHeight;
		e.preventDefault();
		return;
	}

	// Reset g sequence on other keys
	lastKey = '';

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
		window.webkit.messageHandlers.hammerspoon.postMessage('back');
		e.preventDefault();
	}
});

// Function to hide loading indicator (called from Lua)
function hideLoading() {
	loadingIndicator.classList.remove('visible');
	isLoadingMore = false;
}
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
			if callbacks.onBack then callbacks.onBack() end
		elseif action == "close" then
			if callbacks.onClose then callbacks.onClose() end
		elseif action == "openSlack" then
			if callbacks.onOpenSlack then callbacks.onOpenSlack(msgPermalink) end
		elseif action == "channelUp" then
			if callbacks.onChannelUp then callbacks.onChannelUp() end
		elseif action:match("^thread:") then
			local threadTs = action:match("^thread:(.+)$")
			if threadTs and callbacks.onThreadClick then
				callbacks.onThreadClick(threadTs)
			end
		elseif action:match("^openUrl:") then
			local url = action:match("^openUrl:(.+)$")
			if url then
				hs.urlevent.openURL(url)
			end
		elseif action == "loadMore" then
			if callbacks.onLoadMore then callbacks.onLoadMore() end
		end
	end)

	state.webview = hs.webview.new(
		{ x = boxX, y = boxY, w = boxWidth, h = boxHeight },
		{ developerExtrasEnabled = false },
		state.webviewUC
	)
	state.webview:windowStyle({ "borderless", "closable" })
	state.webview:level(hs.canvas.windowLevels.overlay)
	state.webview:allowTextEntry(true)
	state.webview:allowNewWindows(false)
	state.webview:transparent(true)

	state.webview:html(html)
	state.webview:show()
	state.webview:bringToFront()
	-- Make webview the key window to receive keyboard events
	state.webview:hswindow():focus()
	state.visible = true
	state.canvasFrame = { x = boxX, y = boxY, w = boxWidth, h = boxHeight }

	return state.webview
end

--- Close the Slack webview and clean up resources
--- @param state table The state table
function M.closeWebview(state)
	print("[SlackUI] closeWebview called")
	print("[SlackUI] Stack trace: " .. debug.traceback())
	if state.webview then
		state.webview:delete()
		state.webview = nil
	end
end

--- Reset the loading flag and hide indicator in the webview (for pagination)
--- @param state table The state table
function M.resetLoadingFlag(state)
	if state.webview then
		state.webview:evaluateJavaScript("hideLoading();", function() end)
	end
end

--- Generate HTML for a single message in history mode
--- @param msg table The message object
--- @return string html The HTML for the message
local function generateMessageHtml(msg)
	local sender = escapeHtml(M.slackApi.getUserName(msg.user))
	local msgTime = formatTs(msg.ts)
	local msgText = formatSlackText(msg.text)
	local replyCount = msg.reply_count or 0
	local threadTs = msg.thread_ts or msg.ts

	local html = [[
<div class="message">
	<div class="message-header">
		<span class="sender">]] .. sender .. [[</span>
		<span class="time">]] .. msgTime .. [[</span>
	</div>
	<div class="message-text">]] .. msgText .. [[</div>
]]
	if replyCount > 0 then
		html = html .. [[
	<span class="thread-link" onclick="window.webkit.messageHandlers.hammerspoon.postMessage('thread:]] .. threadTs .. [[')">]] .. replyCount .. [[ replies</span>
]]
	end
	html = html .. [[
</div>
]]
	return html
end

--- Prepend messages to the existing webview without re-rendering
--- @param state table The state table
--- @param messages table The messages to prepend
function M.prependMessages(state, messages)
	print("[SlackUI] prependMessages called for webview #" .. tostring(state.webviewInstanceId))
	print("[SlackUI] Global webview counter: " .. tostring(webviewInstanceId))
	print("[SlackUI] webview exists: " .. tostring(state.webview ~= nil))
	print("[SlackUI] messages count: " .. tostring(messages and #messages or 0))
	if not state.webview or not messages or #messages == 0 then
		print("[SlackUI] Early return: no webview or no messages")
		M.resetLoadingFlag(state)
		return
	end

	-- Generate HTML for all new messages
	local html = ""
	for _, msg in ipairs(messages) do
		html = html .. generateMessageHtml(msg)
	end
	print("[SlackUI] Generated HTML length: " .. #html)

	-- Base64 encode to avoid any escaping issues
	local base64Html = hs.base64.encode(html)
	print("[SlackUI] Base64 encoded, length: " .. #base64Html)

	-- JavaScript to prepend messages with scroll preservation
	-- Uses a technique that anchors to the first visible message
	local js = [[
		(function() {
			try {
				var content = document.getElementById('content');
				var loadingIndicator = document.getElementById('loadingIndicator');

				if (!content) return 'error: no content';
				if (!loadingIndicator) return 'error: no indicator';

				// Find the first visible message BEFORE we insert anything
				var messages = content.querySelectorAll('.message');
				var firstVisibleMsg = null;
				var firstVisibleOffset = 0;
				for (var i = 0; i < messages.length; i++) {
					var msg = messages[i];
					var rect = msg.getBoundingClientRect();
					var contentRect = content.getBoundingClientRect();
					if (rect.top >= contentRect.top) {
						firstVisibleMsg = msg;
						firstVisibleOffset = rect.top - contentRect.top;
						break;
					}
				}

				// Decode and insert new messages
				var html = atob(']] .. base64Html .. [[');
				loadingIndicator.insertAdjacentHTML('afterend', html);

				// Scroll to keep the first visible message in the same position
				if (firstVisibleMsg) {
					var newRect = firstVisibleMsg.getBoundingClientRect();
					var newContentRect = content.getBoundingClientRect();
					var currentOffset = newRect.top - newContentRect.top;
					var adjustment = currentOffset - firstVisibleOffset;
					content.scrollTop += adjustment;
				}

				hideLoading();
				return 'success';
			} catch(e) {
				return 'error: ' + e.message;
			}
		})();
	]]

	print("[SlackUI] About to call evaluateJavaScript")
	state.webview:evaluateJavaScript(js, function(result, err)
		if err then
			print("[SlackUI] JS error:", hs.inspect(err))
		else
			print("[SlackUI] JS result:", tostring(result))
		end
		print("[SlackUI] evaluateJavaScript callback completed")
	end)
	print("[SlackUI] evaluateJavaScript called (async)")
end

return M
