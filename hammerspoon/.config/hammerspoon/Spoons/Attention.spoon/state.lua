--- Attention.spoon/state.lua
--- State management for the Attention dashboard
--- Centralizes all mutable state to make it easier to track and debug
--- @module state

local M = {}

--- Initialize or reset all state to defaults
--- @return table state The initialized state table
function M.init()
	return {
		-- UI State
		canvas = nil,              -- hs.canvas object for main UI
		webview = nil,             -- hs.webview for Slack detail
		webviewUC = nil,           -- hs.webview.usercontent for JS callbacks
		visible = false,           -- Whether the dashboard is currently visible
		canvasFrame = nil,         -- Current canvas frame {x, y, w, h}
		lastCanvasSize = nil,      -- Remembered size for loader

		-- View State
		currentView = "main",      -- "main", "linear-detail", or "slack-detail"
		hoveredIndex = nil,        -- Currently hovered item index
		selectedIndex = nil,       -- Selected item for keyboard nav
		scrollOffset = 0,          -- Current scroll offset in pixels
		contentHeight = 0,         -- Total content height for scroll limits
		viewHeight = 0,            -- Visible viewport height

		-- Clickable Items
		clickableItems = {},       -- Array of {type, y, h, x, w, data, key}
		keyMap = {},               -- Maps key characters to item indices

		-- Data Cache
		cache = {
			linear = nil,          -- Cached Linear issues
			slack = nil,           -- Cached Slack messages
		},
		lastFetchDate = nil,       -- Date string of last fetch

		-- Linear Detail State
		currentIssue = nil,        -- Current Linear issue being viewed

		-- Slack Detail State
		currentSlackMsg = nil,     -- Current Slack message being viewed
		currentSlackThread = nil,  -- Thread replies for current message
		currentSlackChannel = nil, -- Channel ID for navigation
		slackViewMode = "thread",  -- "thread" or "history"
		slackOldestTs = nil,       -- Oldest message ts for pagination
		slackThreadTs = nil,       -- Thread parent ts for pagination

		-- User Cache (for resolving Slack user IDs to names)
		slackUserCache = {},       -- {userId: displayName}

		-- Event Watchers
		escapeWatcher = nil,       -- Keyboard event watcher
		clickWatcher = nil,        -- Mouse click watcher
		hoverWatcher = nil,        -- Mouse hover watcher
		webviewKeyWatcher = nil,   -- Keyboard watcher for webview

		-- Timers
		loadingTimer = nil,        -- Loading animation timer
		loadingDots = 0,           -- Loading animation frame
		dailyTimer = nil,          -- Daily refresh timer
	}
end

--- Reset state for closing/hiding the dashboard
--- Clears UI-related state while preserving cache
--- @param state table The state table to reset
function M.resetForClose(state)
	state.currentView = "main"
	state.clickableItems = {}
	state.keyMap = {}
	state.canvasFrame = nil
	state.hoveredIndex = nil
	state.selectedIndex = nil
	state.scrollOffset = 0
	state.currentIssue = nil
	state.currentSlackMsg = nil
	state.currentSlackThread = nil
end

--- Reset state for navigating back to main view
--- @param state table The state table to reset
function M.resetForBack(state)
	state.scrollOffset = 0
	state.currentView = "main"
	state.clickableItems = {}
	state.keyMap = {}
	state.hoveredIndex = nil
end

return M
