--- Attention.spoon/utils.lua
--- Utility functions for the Attention dashboard
--- @module utils

local M = {}

--- Read an environment variable from ~/.env/services/.env
--- @param varName string The name of the environment variable to read
--- @return string|nil value The value of the environment variable, or nil if not found
--- @example
---   local apiKey = utils.getEnvVar("LINEAR_API_KEY")
function M.getEnvVar(varName)
	local envPath = os.getenv("HOME") .. "/.env/services/.env"
	local file = io.open(envPath, "r")
	if not file then return nil end

	for line in file:lines() do
		local key, value = line:match("^([^=]+)=(.*)$")
		if key == varName then
			file:close()
			-- Remove quotes if present
			value = value:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
			return value
		end
	end
	file:close()
	return nil
end

--- Generate a shortcut key for a given index
--- Returns a-z for indices 1-26, A-Z for indices 27-52
--- @param index number The index (1-based)
--- @return string|nil key The shortcut key character, or nil if index > 52
--- @example
---   utils.getShortcutKey(1)  -- returns "a"
---   utils.getShortcutKey(27) -- returns "A"
function M.getShortcutKey(index)
	if index <= 26 then
		return string.char(96 + index) -- a-z
	elseif index <= 52 then
		return string.char(64 + index - 26) -- A-Z
	end
	return nil
end

--- Format a Slack timestamp to human-readable format
--- @param ts string The Slack timestamp (e.g., "1234567890.123456")
--- @return string formatted The formatted date string (e.g., "Dec 06, 14:30")
function M.formatSlackTs(ts)
	if not ts then return "" end
	local timestamp = tonumber(ts:match("^(%d+)"))
	if timestamp then
		return os.date("%b %d, %H:%M", timestamp)
	end
	return ""
end

--- Escape HTML special characters
--- @param text string The text to escape
--- @return string escaped The escaped text safe for HTML
function M.escapeHtml(text)
	if not text then return "" end
	return text:gsub("&", "&amp;")
		:gsub("<", "&lt;")
		:gsub(">", "&gt;")
		:gsub('"', "&quot;")
		:gsub("'", "&#39;")
end

--- Check if today's date matches the last fetch date
--- Used to determine if cached data is still fresh
--- @param lastFetchDate string|nil The date string of the last fetch
--- @return boolean needsFetch True if data should be refetched
function M.needsFetch(lastFetchDate)
	local today = os.date("%Y-%m-%d")
	return lastFetchDate ~= today
end

return M
