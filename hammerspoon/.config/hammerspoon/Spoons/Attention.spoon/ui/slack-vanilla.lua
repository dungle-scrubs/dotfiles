--- Attention.spoon/ui/slack-vanilla.lua
--- Slack message detail webview with vanilla JS state management

-- Use global path set by init.lua
local spoonPath = _G.AttentionSpoonPath
local styles = dofile(spoonPath .. "/ui/styles.lua")

---@class AttentionSlackVanillaUI
local M = {}

-- Will be set by init.lua to share the same instance
M.slackApi = nil

-- Counter to track webview instances
local webviewInstanceId = 0

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
	text = text:gsub("<@([^|>]+)|([^>]+)>", function(uid, name)
		return "@" .. name
	end)
	text = text:gsub("<@([^>]+)>", function(uid)
		local name = M.slackApi.getUserName(uid)
		return "@" .. name
	end)
	text = text:gsub("<#[^|>]+|([^>]+)>", "#%1")
	text = text:gsub("<(https?://[^|>]+)|([^>]+)>", function(url, display)
		return "LINK[" .. url .. "](" .. display .. ")"
	end)
	text = text:gsub("<(https?://[^>]+)>", "%1")
	text = escapeHtml(text)
	text = text:gsub('LINK%[([^%]]+)%]%(([^%)]+)%)', function(url, display)
		return '<a href="#" class="link" data-url="' .. url .. '">' .. display .. '</a>'
	end)
	text = text:gsub("(https?://[%w%-%./_~:/?#%[%]@!$&;'()*+,;=%%]+)", function(url)
		if url:find('data%-url=') then return url end
		return '<a href="#" class="link" data-url="' .. url .. '">' .. url .. '</a>'
	end)
	text = text:gsub("@([%w%-_%.]+)", '<span class="mention">@%1</span>')
	text = text:gsub("\n", "<br>")
	return text
end

--- Format a Slack timestamp to human-readable date/time
--- @param ts string The Slack timestamp
--- @return string formatted The formatted date/time string
local function formatTs(ts)
	if not ts then return "" end
	local timestamp = tonumber(ts:match("^(%d+)"))
	if timestamp then
		return os.date("%b %d, %H:%M", timestamp)
	end
	return ""
end

--- Convert a message to JSON format
--- @param msg table The message object
--- @return table jsonMsg The JSON-safe message
local function messageToJson(msg)
	return {
		id = msg.ts or "",
		user = M.slackApi.getUserName(msg.user) or msg.user or "unknown",
		time = formatTs(msg.ts),
		text = formatSlackText(msg.text),
		replyCount = msg.reply_count or 0,
		threadTs = msg.thread_ts or msg.ts or "",
		isReply = false,
	}
end

--- Render the Slack detail view using vanilla JS
function M.renderWebview(state, msg, thread, keepScrollPosition, callbacks)
	webviewInstanceId = webviewInstanceId + 1
	local currentInstanceId = webviewInstanceId
	print("[SlackVanilla] renderWebview called - CREATING WEBVIEW #" .. currentInstanceId)
	state.webviewInstanceId = currentInstanceId
	callbacks = callbacks or {}

	if msg then
		state.currentSlackMsg = msg
		state.currentSlackThread = thread or {}
	else
		msg = state.currentSlackMsg
		thread = state.currentSlackThread or {}
	end
	if not msg then return nil end

	if thread and #thread > 0 and thread[1].ts then
		state.slackOldestTs = thread[1].ts
	end

	state.currentView = "slack-detail"

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

	-- Build initial messages JSON
	local messagesJson = {}
	local viewMode = state.slackViewMode or "history"

	if viewMode == "history" then
		for _, threadMsg in ipairs(thread or {}) do
			table.insert(messagesJson, messageToJson(threadMsg))
		end
	elseif thread and #thread > 0 then
		for i, threadMsg in ipairs(thread) do
			local m = messageToJson(threadMsg)
			if i > 1 then m.isReply = true end
			table.insert(messagesJson, m)
		end
	else
		table.insert(messagesJson, {
			id = msg.ts or "",
			user = msg.username or "unknown",
			time = formatTs(msg.ts),
			text = formatSlackText(msg.text),
			replyCount = 0,
			threadTs = msg.ts or "",
			isReply = false,
		})
	end

	local channelName = msg.channel and msg.channel.name or "Direct Message"
	local isDM = msg.channel and msg.channel.is_im
	local modeLabel = viewMode == "history" and " (history)" or " (thread)"
	local titleText = isDM and ("DM with " .. escapeHtml(msg.username or "unknown"))
		or ("#" .. escapeHtml(channelName) .. modeLabel)
	local showChannelUp = viewMode == "thread"

	local css = styles.getSlackWebviewCSS()
	local messagesJsonStr = hs.json.encode(messagesJson)
	local keepScrollStr = keepScrollPosition and "true" or "false"
	local showChannelUpStr = showChannelUp and "true" or "false"

	local html = [=[
<!DOCTYPE html>
<html>
<head>
<style>
]=] .. css .. [=[
</style>
</head>
<body>
<div class="container">
	<div class="header">
		<div class="header-left">
			<span class="btn" onclick="postMessage('back')"><span class="key">b</span>&lt;- Back</span>
		</div>
		<div class="title">]=] .. titleText .. [=[</div>
		<div class="header-right">
]=] .. (showChannelUp and [=[			<span class="btn" onclick="postMessage('channelUp')"><span class="key">u</span>^ Channel</span>
]=] or "") .. [=[
			<span class="btn" onclick="postMessage('openSlack')"><span class="key">o</span>Open in Slack -&gt;</span>
		</div>
	</div>
	<div class="content" id="content">
		<div class="loading-indicator" id="loadingIndicator">Loading older messages...</div>
		<div id="messagesContainer"></div>
	</div>
	<div class="footer">
		<span class="hint"><span class="key">j/k</span> <span class="label">scroll</span></span>
		<span class="hint"><span class="key">gg/G</span> <span class="label">top/btm</span></span>
		<span class="hint"><span class="key">^d/^u</span> <span class="label">page</span></span>
		<span class="hint"><span class="key">o</span> <span class="label">open</span></span>
		<span class="hint"><span class="key">b</span> <span class="label">back</span></span>
]=] .. (showChannelUp and [=[		<span class="hint"><span class="key">u</span> <span class="label">channel</span></span>
]=] or "") .. [=[
	</div>
</div>
<script>
// State
var messages = ]=] .. messagesJsonStr .. [=[;
var viewMode = ']=] .. viewMode .. [=[';
var isLoadingMore = false;
var showChannelUp = ]=] .. showChannelUpStr .. [=[;

// DOM elements
var content = document.getElementById('content');
var loadingIndicator = document.getElementById('loadingIndicator');
var messagesContainer = document.getElementById('messagesContainer');

// Post message to Hammerspoon
function postMessage(action) {
	window.webkit.messageHandlers.hammerspoon.postMessage(action);
}

// Create HTML for a single message
function createMessageHtml(msg) {
	var className = msg.isReply ? 'message reply' : 'message';
	var html = '<div class="' + className + '" data-id="' + msg.id + '">' +
		'<div class="message-header">' +
		'<span class="sender">' + msg.user + '</span>' +
		'<span class="time">' + msg.time + '</span>' +
		'</div>' +
		'<div class="message-text">' + msg.text + '</div>';

	if (viewMode === 'history' && msg.replyCount > 0) {
		html += '<span class="thread-link" onclick="postMessage(\'thread:' + msg.threadTs + '\')">' +
			msg.replyCount + ' replies</span>';
	}

	html += '</div>';
	return html;
}

// Render all messages
function renderMessages() {
	var html = '';

	if (viewMode === 'thread' && messages.length > 1) {
		// Thread view: first message, separator, then replies
		html += createMessageHtml(messages[0]);
		html += '<div class="thread-separator">Thread (' + (messages.length - 1) + ' replies)</div>';
		for (var i = 1; i < messages.length; i++) {
			var msg = messages[i];
			msg.isReply = true;
			html += createMessageHtml(msg);
		}
	} else {
		// History view: all messages
		for (var i = 0; i < messages.length; i++) {
			html += createMessageHtml(messages[i]);
		}
	}

	messagesContainer.innerHTML = html;
}

// Prepend new messages (for pagination)
function prependMessages(newMessages) {
	// Store scroll position relative to first visible message
	var firstMsg = messagesContainer.querySelector('.message');
	var scrollAnchor = null;
	var anchorOffset = 0;

	if (firstMsg) {
		scrollAnchor = firstMsg;
		anchorOffset = firstMsg.getBoundingClientRect().top - content.getBoundingClientRect().top;
	}

	// Prepend to state
	messages = newMessages.concat(messages);

	// Create HTML for new messages only
	var html = '';
	for (var i = 0; i < newMessages.length; i++) {
		html += createMessageHtml(newMessages[i]);
	}

	// Insert at the beginning of messages container
	messagesContainer.insertAdjacentHTML('afterbegin', html);

	// Restore scroll position
	if (scrollAnchor) {
		var newOffset = scrollAnchor.getBoundingClientRect().top - content.getBoundingClientRect().top;
		content.scrollTop += (newOffset - anchorOffset);
	}

	hideLoading();
}

// Show/hide loading indicator
function showLoading() {
	loadingIndicator.classList.add('visible');
	isLoadingMore = true;
}

function hideLoading() {
	loadingIndicator.classList.remove('visible');
	isLoadingMore = false;
}

// Scroll handler for pagination
content.addEventListener('scroll', function() {
	if (content.scrollTop < 50 && !isLoadingMore) {
		showLoading();
		postMessage('loadMore');
	}
});

// Link click handler
document.addEventListener('click', function(e) {
	var link = e.target.closest('a.link');
	if (link) {
		e.preventDefault();
		var url = link.getAttribute('data-url');
		if (url) postMessage('openUrl:' + url);
	}
});

// Keyboard handling
var lastKeyTime = 0;
var lastKey = '';

document.addEventListener('keydown', function(e) {
	var scrollAmount = 60;
	var pageAmount = content.clientHeight * 0.8;
	var now = Date.now();

	// Handle gg (go to top)
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

	lastKey = '';

	if (e.key === 'j') { content.scrollTop += scrollAmount; e.preventDefault(); }
	else if (e.key === 'k') { content.scrollTop -= scrollAmount; e.preventDefault(); }
	else if (e.key === 'd' && e.ctrlKey) { content.scrollTop += pageAmount; e.preventDefault(); }
	else if (e.key === 'u' && e.ctrlKey) { content.scrollTop -= pageAmount; e.preventDefault(); }
	else if (e.key === 'u' && !e.ctrlKey && !e.metaKey && showChannelUp) {
		postMessage('channelUp');
		e.preventDefault();
	}
	else if (e.key === 'b') { postMessage('back'); e.preventDefault(); }
	else if (e.key === 'o') { postMessage('openSlack'); e.preventDefault(); }
	else if (e.key === 'Escape') { postMessage('back'); e.preventDefault(); }
});

// Expose functions for Lua to call
window.prependMessages = prependMessages;
window.hideLoading = hideLoading;
window.showLoading = showLoading;

// Initial render
renderMessages();

// Scroll to bottom unless keeping position
if (!]=] .. keepScrollStr .. [=[) {
	content.scrollTop = content.scrollHeight;
}
</script>
</body>
</html>
]=]

	-- Stop canvas event watchers
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

	-- Create webview
	if state.webview then
		state.webview:delete()
	end
	if state.webviewUC then
		state.webviewUC = nil
	end

	local msgPermalink = msg.permalink

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
		{ developerExtrasEnabled = true },
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
	state.webview:hswindow():focus()
	state.visible = true
	state.canvasFrame = { x = boxX, y = boxY, w = boxWidth, h = boxHeight }

	return state.webview
end

--- Close the Slack webview
function M.closeWebview(state)
	print("[SlackVanilla] closeWebview called")
	if state.webview then
		state.webview:delete()
		state.webview = nil
	end
end

--- Reset loading flag
function M.resetLoadingFlag(state)
	if state.webview then
		state.webview:evaluateJavaScript("window.hideLoading && window.hideLoading();", function() end)
	end
end

--- Prepend messages using vanilla JS
function M.prependMessages(state, messages)
	print("[SlackVanilla] prependMessages called for webview #" .. tostring(state.webviewInstanceId))
	if not state.webview or not messages or #messages == 0 then
		print("[SlackVanilla] Early return: no webview or no messages")
		M.resetLoadingFlag(state)
		return
	end

	local messagesJson = {}
	for _, msg in ipairs(messages) do
		table.insert(messagesJson, messageToJson(msg))
	end

	local jsonStr = hs.json.encode(messagesJson)
	print("[SlackVanilla] Sending " .. #messagesJson .. " messages")

	local js = "window.prependMessages && window.prependMessages(" .. jsonStr .. ");"

	state.webview:evaluateJavaScript(js, function(result, err)
		if err then
			print("[SlackVanilla] JS error:", hs.inspect(err))
		else
			print("[SlackVanilla] Messages prepended successfully")
		end
	end)
end

return M
