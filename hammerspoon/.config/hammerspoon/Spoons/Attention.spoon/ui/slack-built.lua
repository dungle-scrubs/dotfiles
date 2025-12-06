--- Attention.spoon/ui/slack-built.lua
--- Slack message detail webview using built Preact bundle

-- Use global path set by init.lua
local spoonPath = _G.AttentionSpoonPath
local styles = dofile(spoonPath .. "/ui/styles.lua")

---@class AttentionSlackBuiltUI
local M = {}

-- Will be set by init.lua to share the same instance
M.slackApi = nil

-- Load the bundled JS once
local bundlePath = spoonPath .. "/webview/dist/bundle.js"
local bundleFile = io.open(bundlePath, "r")
local bundledJS = bundleFile and bundleFile:read("*all") or ""
if bundleFile then bundleFile:close() end

if bundledJS == "" then
	print("[SlackBuilt] WARNING: Could not load bundle.js from " .. bundlePath)
end

-- Counter to track webview instances
local webviewInstanceId = 0

--- Escape HTML special characters
local function escapeHtml(text)
	if not text then return "" end
	return text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&#39;")
end

--- Format Slack message text with mentions, links, and formatting
local function formatSlackText(text)
	if not text then return "" end
	text = text:gsub("<@([^|>]+)|([^>]+)>", function(uid, name)
		return "@" .. name
	end)
	text = text:gsub("<@([^>]+)>", function(uid)
		local name = M.slackApi.getUserName(uid)
		return "@" .. name
	end)
	text = text:gsub("<#[^|>]+|([^>]+)>", "#%1")
	text = text:gsub("<(https?://[^|>]+)|([^>]+)>", "[%2](%1)")
	text = text:gsub("<(https?://[^>]+)>", "%1")
	return text
end

--- Format a Slack timestamp to human-readable date/time
local function formatTs(ts)
	if not ts then return "" end
	local timestamp = tonumber(ts:match("^(%d+)"))
	if timestamp then
		return os.date("%b %d, %H:%M", timestamp)
	end
	return ""
end

--- Convert a message to JSON format for Preact
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

--- Render the Slack detail view using built Preact
function M.renderWebview(state, msg, thread, keepScrollPosition, isInitialLoading, callbacks)
	webviewInstanceId = webviewInstanceId + 1
	local currentInstanceId = webviewInstanceId
	print("[SlackBuilt] renderWebview called - CREATING WEBVIEW #" .. currentInstanceId)
	state.webviewInstanceId = currentInstanceId
	callbacks = callbacks or {}
	isInitialLoading = isInitialLoading or false

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

	-- Build HTML with bundled JS
	local html = [[
<!DOCTYPE html>
<html>
<head>
<style>
]] .. css .. [[
#app {
	flex: 1;
	display: flex;
	flex-direction: column;
	overflow: hidden;
	min-height: 0;
}
</style>
</head>
<body>
<div class="container">
	<div class="header">
		<div class="header-left">
			<span class="btn" onclick="window.webkit.messageHandlers.hammerspoon.postMessage('back')"><span class="key">b</span>&lt;- Back</span>
		</div>
		<div class="title">]] .. titleText .. [[</div>
		<div class="header-right">
]] .. (showChannelUp and [[			<span class="btn" onclick="window.webkit.messageHandlers.hammerspoon.postMessage('channelUp')"><span class="key">u</span>^ Channel</span>
]] or "") .. [[
			<span class="btn" onclick="window.webkit.messageHandlers.hammerspoon.postMessage('openSlack')"><span class="key">O</span>Open in Slack -&gt;</span>
		</div>
	</div>
	<div id="app"></div>
	<div class="footer">
		<span class="hint"><span class="key">j/k</span> <span class="label">scroll</span></span>
		<span class="hint"><span class="key">gg/G</span> <span class="label">top/btm</span></span>
		<span class="hint"><span class="key">^d/^u</span> <span class="label">page</span></span>
		<span class="hint"><span class="key">O</span> <span class="label">open</span></span>
		<span class="hint"><span class="key">b</span> <span class="label">back</span></span>
]] .. (showChannelUp and [[		<span class="hint"><span class="key">u</span> <span class="label">channel</span></span>
]] or "") .. [[
	</div>
</div>
<script>
// Initialize app state before bundle runs
window.appState = {
	messages: ]] .. messagesJsonStr .. [[,
	viewMode: ']] .. viewMode .. [[',
	isLoadingMore: false,
	isInitialLoading: ]] .. (isInitialLoading and "true" or "false") .. [[,
	showChannelUp: ]] .. (showChannelUp and "true" or "false") .. [[
};
window.keepScrollPosition = ]] .. (keepScrollPosition and "true" or "false") .. [[;
</script>
<script>
]] .. bundledJS .. [[
</script>
</body>
</html>
]]

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

	-- Wait for page to finish loading before hiding canvas
	state.webview:navigationCallback(function(action, wv, navID, err)
		if action == "didFinishNavigation" then
			-- Page loaded, now hide canvas
			if state.canvas then
				state.canvas:hide()
			end
			wv:bringToFront()
			local win = wv:hswindow()
			if win then win:focus() end
		end
	end)

	state.webview:html(html)
	state.webview:show()
	state.visible = true
	state.canvasFrame = { x = boxX, y = boxY, w = boxWidth, h = boxHeight }

	return state.webview
end

--- Close the Slack webview
function M.closeWebview(state)
	print("[SlackBuilt] closeWebview called")
	if state.webview then
		state.webview:delete()
		state.webview = nil
	end
end

--- Reset loading flag
function M.resetLoadingFlag(state)
	if state.webview then
		state.webview:evaluateJavaScript("window.setLoading && window.setLoading(false);", function() end)
	end
end

--- Prepend messages using Preact state update
function M.prependMessages(state, messages)
	print("[SlackBuilt] prependMessages called for webview #" .. tostring(state.webviewInstanceId))
	if not state.webview or not messages or #messages == 0 then
		print("[SlackBuilt] Early return: no webview or no messages")
		M.resetLoadingFlag(state)
		return
	end

	local messagesJson = {}
	for _, msg in ipairs(messages) do
		table.insert(messagesJson, messageToJson(msg))
	end

	local jsonStr = hs.json.encode(messagesJson)
	print("[SlackBuilt] Sending " .. #messagesJson .. " messages to Preact")

	local js = "window.updateMessages && window.updateMessages(" .. jsonStr .. ", true);"

	state.webview:evaluateJavaScript(js, function(result, err)
		if err then
			print("[SlackBuilt] JS error:", hs.inspect(err))
		else
			print("[SlackBuilt] Messages updated successfully")
		end
	end)
end

--- Update initial messages (for zero-gap loading)
function M.updateInitialMessages(state, messages, retryCount)
	retryCount = retryCount or 0
	print("[SlackBuilt] updateInitialMessages called, retry=" .. retryCount)
	if not state.webview then
		print("[SlackBuilt] No webview, skipping")
		return
	end

	-- Update state for pagination
	if messages and #messages > 0 and messages[1].ts then
		state.slackOldestTs = messages[1].ts
	end
	state.currentSlackThread = messages or {}

	local messagesJson = {}
	local viewMode = state.slackViewMode or "history"
	for i, msg in ipairs(messages or {}) do
		local m = messageToJson(msg)
		if viewMode == "thread" and i > 1 then
			m.isReply = true
		end
		table.insert(messagesJson, m)
	end

	local jsonStr = hs.json.encode(messagesJson)
	print("[SlackBuilt] Sending " .. #messagesJson .. " initial messages")

	-- Check if updateMessages is ready, retry if not
	local js = [[
		(function() {
			if (window.updateMessages) {
				window.updateMessages(]] .. jsonStr .. [[, false);
				return true;
			}
			return false;
		})();
	]]

	state.webview:evaluateJavaScript(js, function(result, err)
		if err then
			print("[SlackBuilt] JS error:", hs.inspect(err))
		elseif result == false and retryCount < 5 then
			-- Retry after a short delay
			print("[SlackBuilt] updateMessages not ready, retrying...")
			hs.timer.doAfter(0.1, function()
				M.updateInitialMessages(state, messages, retryCount + 1)
			end)
		else
			print("[SlackBuilt] Initial messages loaded successfully")
		end
	end)
end

--- Switch view mode in-place (thread <-> history) without recreating webview
function M.switchView(state, viewMode, messages, showLoading)
	print("[SlackBuilt] switchView called: " .. viewMode)
	if not state.webview then
		print("[SlackBuilt] No webview, skipping")
		return
	end

	-- Update state
	state.slackViewMode = viewMode
	if messages and #messages > 0 and messages[1].ts then
		state.slackOldestTs = messages[1].ts
	end
	state.currentSlackThread = messages or {}

	-- Build messages JSON
	local messagesJson = {}
	for i, msg in ipairs(messages or {}) do
		local m = messageToJson(msg)
		if viewMode == "thread" and i > 1 then
			m.isReply = true
		end
		table.insert(messagesJson, m)
	end

	local jsonStr = hs.json.encode(messagesJson)
	local showChannelUp = viewMode == "thread"

	-- Build title
	local msg = state.currentSlackMsg
	local channelName = msg and msg.channel and msg.channel.name or "Direct Message"
	local isDM = msg and msg.channel and msg.channel.is_im
	local modeLabel = viewMode == "history" and " (history)" or " (thread)"
	local titleText = isDM and ("DM with " .. escapeHtml(msg.username or "unknown"))
		or ("#" .. escapeHtml(channelName) .. modeLabel)

	-- JavaScript to update view in-place
	local js = string.format([[
		(function() {
			console.log('[SlackBuilt] switchView JS executing, viewMode=' + '%s' + ', showChannelUp=' + %s);
			// Update app state
			window.appState.viewMode = '%s';
			window.appState.showChannelUp = %s;
			window.appState.isLoadingMore = false;

			// Update title
			var title = document.querySelector('.title');
			if (title) title.textContent = '%s';

			// Update header buttons - show/hide channelUp button
			var headerRight = document.querySelector('.header-right');
			if (headerRight) {
				var channelUpBtn = headerRight.querySelector('[onclick*="channelUp"]');
				if (%s) {
					// Show channelUp button
					if (!channelUpBtn) {
						var btn = document.createElement('span');
						btn.className = 'btn';
						btn.innerHTML = '<span class="key">u</span>^ Channel';
						btn.onclick = function() { window.webkit.messageHandlers.hammerspoon.postMessage('channelUp'); };
						headerRight.insertBefore(btn, headerRight.firstChild);
					}
				} else {
					// Hide channelUp button
					if (channelUpBtn) channelUpBtn.remove();
				}
			}

			// Update footer hints
			var footer = document.querySelector('.footer');
			if (footer) {
				var channelHint = footer.querySelector('.hint:last-child');
				if (channelHint && channelHint.textContent.includes('channel')) {
					if (!%s) channelHint.remove();
				} else if (%s) {
					var hint = document.createElement('span');
					hint.className = 'hint';
					hint.innerHTML = '<span class="key">u</span> <span class="label">channel</span>';
					footer.appendChild(hint);
				}
			}

			// Update messages
			if (window.updateMessages) {
				window.updateMessages(%s, false);
			}
		})();
	]],
		viewMode, -- console.log viewMode
		showChannelUp and "true" or "false", -- console.log showChannelUp
		viewMode, -- window.appState.viewMode
		showChannelUp and "true" or "false", -- window.appState.showChannelUp
		titleText:gsub("'", "\\'"), -- title.textContent (escape single quotes)
		showChannelUp and "true" or "false", -- show channelUp button
		showChannelUp and "true" or "false", -- remove channel hint
		showChannelUp and "true" or "false", -- add channel hint
		jsonStr -- updateMessages
	)

	state.webview:evaluateJavaScript(js, function(result, err)
		if err then
			print("[SlackBuilt] switchView JS error:", hs.inspect(err))
		else
			print("[SlackBuilt] View switched to " .. viewMode)
		end
	end)
end

return M
