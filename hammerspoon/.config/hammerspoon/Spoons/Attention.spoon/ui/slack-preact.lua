--- Attention.spoon/ui/slack-preact.lua
--- Slack message detail webview rendering using Preact for efficient updates

-- Use global path set by init.lua
local spoonPath = _G.AttentionSpoonPath
local styles = dofile(spoonPath .. "/ui/styles.lua")

---@class AttentionSlackPreactUI
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
--- @return string formatted The formatted text (safe for JSON)
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
	text = text:gsub("<(https?://[^|>]+)|([^>]+)>", "[%2](%1)")
	-- Plain URLs: <http://url>
	text = text:gsub("<(https?://[^>]+)>", "%1")
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

--- Convert a message to JSON format for Preact
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

--- Render the Slack detail view using a Preact-powered webview
--- @param state table The state table
--- @param msg table|nil The Slack message to render
--- @param thread table|nil The thread messages
--- @param keepScrollPosition boolean|nil If true, don't scroll to bottom
--- @param callbacks table Callback functions for actions
--- @return hs.webview webview The rendered webview
function M.renderWebview(state, msg, thread, keepScrollPosition, callbacks)
	webviewInstanceId = webviewInstanceId + 1
	local currentInstanceId = webviewInstanceId
	print("[SlackPreact] renderWebview called - CREATING WEBVIEW #" .. currentInstanceId)
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
			if i > 1 then
				m.isReply = true
			end
			table.insert(messagesJson, m)
		end
	else
		-- Single message
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

	-- Use [=[ ]=] for long strings to avoid conflicts with JS regex
	local html = [=[
<!DOCTYPE html>
<html>
<head>
<style>
]=] .. css .. [=[
#app {
	flex: 1;
	display: flex;
	flex-direction: column;
	overflow: hidden;
	min-height: 0;
}
</style>
<script type="module">
import { h, render } from 'https://esm.sh/preact@10.19.3';
import { useState, useEffect, useRef, useCallback } from 'https://esm.sh/preact@10.19.3/hooks';
import htm from 'https://esm.sh/htm@3.1.1';

const html = htm.bind(h);

// Global state for messages
window.appState = {
	messages: ]=] .. messagesJsonStr .. [=[,
	viewMode: ']=] .. viewMode .. [=[',
	isLoadingMore: false,
	showChannelUp: ]=] .. showChannelUpStr .. [=[
};

// Send message to Hammerspoon
const postMessage = (action) => {
	window.webkit.messageHandlers.hammerspoon.postMessage(action);
};

// Format message text with links and mentions
const formatText = (text) => {
	if (!text) return '';
	// Convert markdown-style links to HTML
	text = text.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="#" class="link" data-url="$2">$1</a>');
	// Make plain URLs clickable
	text = text.replace(/(https?:\/\/[^\s<]+)/g, (url) => {
		if (url.includes('data-url=')) return url;
		return '<a href="#" class="link" data-url="' + url + '">' + url + '</a>';
	});
	// Style @mentions
	text = text.replace(/@([a-zA-Z0-9._-]+)/g, '<span class="mention">@$1</span>');
	// Convert newlines to <br>
	text = text.replace(/\n/g, '<br>');
	return text;
};

// Message component
const Message = ({ msg, onThreadClick }) => {
	const showReplies = window.appState.viewMode === 'history' && msg.replyCount > 0;
	const className = msg.isReply ? 'message reply' : 'message';

	return html`
		<div class=${className} key=${msg.id}>
			<div class="message-header">
				<span class="sender">${msg.user}</span>
				<span class="time">${msg.time}</span>
			</div>
			<div class="message-text" dangerouslySetInnerHTML=${{ __html: formatText(msg.text) }}></div>
			${showReplies && html`
				<span class="thread-link" onclick=${() => onThreadClick(msg.threadTs)}>
					${msg.replyCount} replies
				</span>
			`}
		</div>
	`;
};

// Thread separator
const ThreadSeparator = ({ count }) => html`
	<div class="thread-separator">Thread (${count} replies)</div>
`;

// Main App component
const App = () => {
	const [messages, setMessages] = useState(window.appState.messages);
	const [isLoading, setIsLoading] = useState(false);
	const contentRef = useRef(null);
	const prevScrollHeight = useRef(0);
	const shouldPreserveScroll = useRef(false);

	// Expose update function globally
	useEffect(() => {
		window.updateMessages = (newMessages, prepend = false) => {
			shouldPreserveScroll.current = prepend;
			if (prepend) {
				prevScrollHeight.current = contentRef.current?.scrollHeight || 0;
			}
			setMessages(prev => prepend ? [...newMessages, ...prev] : newMessages);
			setIsLoading(false);
			window.appState.isLoadingMore = false;
		};

		window.setLoading = (loading) => {
			setIsLoading(loading);
		};
	}, []);

	// Scroll handling after messages update
	useEffect(() => {
		const content = contentRef.current;
		if (!content) return;

		if (shouldPreserveScroll.current && prevScrollHeight.current > 0) {
			// Preserve scroll position when prepending
			const newHeight = content.scrollHeight;
			const heightDiff = newHeight - prevScrollHeight.current;
			content.scrollTop = heightDiff;
			shouldPreserveScroll.current = false;
		}
	}, [messages]);

	// Initial scroll to bottom
	useEffect(() => {
		const content = contentRef.current;
		if (content && !]=] .. keepScrollStr .. [=[) {
			content.scrollTop = content.scrollHeight;
		}
	}, []);

	// Scroll event for loading more
	const handleScroll = useCallback((e) => {
		const content = e.target;
		if (content.scrollTop < 50 && !window.appState.isLoadingMore) {
			window.appState.isLoadingMore = true;
			setIsLoading(true);
			postMessage('loadMore');
		}
	}, []);

	// Thread click handler
	const handleThreadClick = useCallback((threadTs) => {
		postMessage('thread:' + threadTs);
	}, []);

	// Link click handler
	useEffect(() => {
		const handleClick = (e) => {
			const link = e.target.closest('a.link');
			if (link) {
				e.preventDefault();
				const url = link.getAttribute('data-url');
				if (url) postMessage('openUrl:' + url);
			}
		};
		document.addEventListener('click', handleClick);
		return () => document.removeEventListener('click', handleClick);
	}, []);

	// Render messages based on view mode
	const renderMessages = () => {
		if (window.appState.viewMode === 'thread' && messages.length > 1) {
			return html`
				${html`<${Message} msg=${messages[0]} onThreadClick=${handleThreadClick} />`}
				<${ThreadSeparator} count=${messages.length - 1} />
				${messages.slice(1).map(msg => html`<${Message} msg=${msg} onThreadClick=${handleThreadClick} />`)}
			`;
		}
		return messages.map(msg => html`<${Message} msg=${msg} onThreadClick=${handleThreadClick} />`);
	};

	return html`
		<div class="content" id="content" ref=${contentRef} onScroll=${handleScroll}>
			<div class="loading-indicator ${isLoading ? 'visible' : ''}">Loading older messages...</div>
			${renderMessages()}
		</div>
	`;
};

// Render app
render(html`<${App} />`, document.getElementById('app'));

// Keyboard handling
let lastKeyTime = 0;
let lastKey = '';

document.addEventListener('keydown', (e) => {
	const content = document.getElementById('content');
	if (!content) return;

	const scrollAmount = 60;
	const pageAmount = content.clientHeight * 0.8;
	const now = Date.now();

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
	else if (e.key === 'u' && !e.ctrlKey && !e.metaKey && window.appState.showChannelUp) {
		postMessage('channelUp');
		e.preventDefault();
	}
	else if (e.key === 'b') { postMessage('back'); e.preventDefault(); }
	else if (e.key === 'o') { postMessage('openSlack'); e.preventDefault(); }
	else if (e.key === 'Escape') { postMessage('back'); e.preventDefault(); }
});
</script>
</head>
<body>
<div class="container">
	<div class="header">
		<div class="header-left">
			<span class="btn" onclick="window.webkit.messageHandlers.hammerspoon.postMessage('back')"><span class="key">b</span><- Back</span>
		</div>
		<div class="title">]=] .. titleText .. [=[</div>
		<div class="header-right">
]=] .. (showChannelUp and [=[			<span class="btn" onclick="window.webkit.messageHandlers.hammerspoon.postMessage('channelUp')"><span class="key">u</span>^ Channel</span>
]=] or "") .. [=[
			<span class="btn" onclick="window.webkit.messageHandlers.hammerspoon.postMessage('openSlack')"><span class="key">o</span>Open in Slack -></span>
		</div>
	</div>
	<div id="app"></div>
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
</body>
</html>
]=]

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

--- Close the Slack webview and clean up resources
--- @param state table The state table
function M.closeWebview(state)
	print("[SlackPreact] closeWebview called")
	if state.webview then
		state.webview:delete()
		state.webview = nil
	end
end

--- Reset the loading flag and hide indicator in the webview
--- @param state table The state table
function M.resetLoadingFlag(state)
	if state.webview then
		state.webview:evaluateJavaScript("window.setLoading && window.setLoading(false);", function() end)
	end
end

--- Prepend messages to the existing webview using Preact state update
--- @param state table The state table
--- @param messages table The messages to prepend
function M.prependMessages(state, messages)
	print("[SlackPreact] prependMessages called for webview #" .. tostring(state.webviewInstanceId))
	if not state.webview or not messages or #messages == 0 then
		print("[SlackPreact] Early return: no webview or no messages")
		M.resetLoadingFlag(state)
		return
	end

	-- Convert messages to JSON
	local messagesJson = {}
	for _, msg in ipairs(messages) do
		table.insert(messagesJson, messageToJson(msg))
	end

	local jsonStr = hs.json.encode(messagesJson)
	print("[SlackPreact] Sending " .. #messagesJson .. " messages to Preact")

	-- Call Preact's updateMessages function
	local js = "window.updateMessages && window.updateMessages(" .. jsonStr .. ", true);"

	state.webview:evaluateJavaScript(js, function(result, err)
		if err then
			print("[SlackPreact] JS error:", hs.inspect(err))
		else
			print("[SlackPreact] Messages updated successfully")
		end
	end)
end

return M
