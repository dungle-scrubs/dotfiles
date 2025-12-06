--- Attention.spoon/api/slack.lua
--- Slack API integration for fetching messages, threads, and user info
--- @module api.slack

local utils = require("Spoons.Attention.spoon.utils")

local M = {}

--- Cache for resolved user IDs to display names
--- Shared across all API calls to avoid redundant lookups
--- @type table<string, string>
M.userCache = {}

--- Fetch a single user's info and cache it
--- @param userId string The Slack user ID (e.g., "U1234567")
--- @param token string The Slack API token
--- @param callback function Callback function(displayName)
--- @private
local function fetchUser(userId, token, callback)
	if M.userCache[userId] then
		callback(M.userCache[userId])
		return
	end

	hs.http.asyncGet(
		"https://slack.com/api/users.info?user=" .. userId,
		{ ["Authorization"] = "Bearer " .. token },
		function(status, response)
			if status == 200 then
				local data = hs.json.decode(response)
				if data and data.ok and data.user then
					local name = data.user.real_name or data.user.name or userId
					M.userCache[userId] = name
					callback(name)
					return
				end
			end
			callback(userId) -- fallback to ID
		end
	)
end

--- Resolve multiple user IDs to display names
--- Fetches uncached users in parallel (up to 10 at a time)
--- @param messages table Array of message objects with 'user' field
--- @param callback function Callback function() called when all resolved
--- @private
local function resolveUsers(messages, callback)
	local token = utils.getEnvVar("SLACK_USER_TOKEN")
	if not token then
		callback()
		return
	end

	-- Collect unique uncached user IDs
	local userIds = {}
	local seen = {}
	for _, msg in ipairs(messages or {}) do
		local uid = msg.user
		if uid and not seen[uid] and not M.userCache[uid] then
			seen[uid] = true
			table.insert(userIds, uid)
		end
	end

	if #userIds == 0 then
		callback()
		return
	end

	-- Fetch in parallel (limit to 10)
	local pending = math.min(#userIds, 10)
	for i = 1, pending do
		fetchUser(userIds[i], token, function()
			pending = pending - 1
			if pending == 0 then
				callback()
			end
		end)
	end
end

--- Get display name for a user ID from cache
--- @param userId string The Slack user ID
--- @return string name The display name, or the userId if not cached
function M.getUserName(userId)
	if not userId then return "unknown" end
	return M.userCache[userId] or userId
end

--- Search for Slack messages mentioning the current user
--- Combines DM search and mention search results
--- @param callback function Callback function(messages, error)
---   - messages: Array of message objects, or nil on error
---   - error: Error message string, or nil on success
--- @example
---   slack.fetchMentions(function(messages, err)
---     if messages then
---       for _, msg in ipairs(messages) do
---         print(msg.channel.name, msg.text)
---       end
---     end
---   end)
function M.fetchMentions(callback)
	local token = utils.getEnvVar("SLACK_USER_TOKEN")
	if not token then
		callback(nil, "SLACK_USER_TOKEN not found")
		return
	end

	local allMessages = {}
	local pendingRequests = 2

	local function checkComplete()
		pendingRequests = pendingRequests - 1
		if pendingRequests == 0 then
			-- Sort by timestamp, newest first
			table.sort(allMessages, function(a, b)
				return (a.ts or "0") > (b.ts or "0")
			end)
			-- Limit to 15 messages
			local limited = {}
			for i = 1, math.min(15, #allMessages) do
				table.insert(limited, allMessages[i])
			end
			callback(limited)
		end
	end

	-- Search DMs
	hs.http.asyncGet(
		"https://slack.com/api/search.messages?query=in%3A%40me&count=10&sort=timestamp",
		{ ["Authorization"] = "Bearer " .. token },
		function(status, response)
			if status == 200 then
				local data = hs.json.decode(response)
				if data and data.ok and data.messages and data.messages.matches then
					for _, msg in ipairs(data.messages.matches) do
						msg.isDM = true
						table.insert(allMessages, msg)
					end
				end
			end
			checkComplete()
		end
	)

	-- Search mentions
	hs.http.asyncGet(
		"https://slack.com/api/search.messages?query=to%3Ame&count=10&sort=timestamp",
		{ ["Authorization"] = "Bearer " .. token },
		function(status, response)
			if status == 200 then
				local data = hs.json.decode(response)
				if data and data.ok and data.messages and data.messages.matches then
					for _, msg in ipairs(data.messages.matches) do
						table.insert(allMessages, msg)
					end
				end
			end
			checkComplete()
		end
	)
end

--- Fetch thread replies for a specific message
--- @param channelId string The channel ID
--- @param threadTs string The parent message timestamp
--- @param callback function Callback function(messages, error)
--- @param latest string|nil Optional: fetch messages older than this timestamp
--- @example
---   slack.fetchThread("C1234567", "1234567890.123456", function(msgs, err)
---     if msgs then
---       for _, msg in ipairs(msgs) do
---         print(msg.user, msg.text)
---       end
---     end
---   end)
function M.fetchThread(channelId, threadTs, callback, latest)
	local token = utils.getEnvVar("SLACK_USER_TOKEN")
	if not token then
		callback(nil, "SLACK_USER_TOKEN not found")
		return
	end

	local url = "https://slack.com/api/conversations.replies?channel="
		.. channelId .. "&ts=" .. threadTs .. "&limit=50"
	if latest then
		url = url .. "&latest=" .. latest
	end

	hs.http.asyncGet(
		url,
		{ ["Authorization"] = "Bearer " .. token },
		function(status, response)
			if status ~= 200 then
				callback(nil, "Slack API error: " .. tostring(status))
				return
			end
			local data = hs.json.decode(response)
			if data and data.ok and data.messages then
				resolveUsers(data.messages, function()
					callback(data.messages)
				end)
			else
				callback({}, data and data.error)
			end
		end
	)
end

--- Fetch conversation history for a channel or DM
--- @param channelId string The channel ID
--- @param callback function Callback function(messages, error)
--- @param latest string|nil Optional: fetch messages older than this timestamp
--- @example
---   slack.fetchHistory("C1234567", function(msgs, err)
---     if msgs then
---       -- msgs are in chronological order (oldest first)
---       for _, msg in ipairs(msgs) do
---         print(msg.user, msg.text)
---       end
---     end
---   end)
function M.fetchHistory(channelId, callback, latest)
	local token = utils.getEnvVar("SLACK_USER_TOKEN")
	if not token then
		callback(nil, "SLACK_USER_TOKEN not found")
		return
	end

	local url = "https://slack.com/api/conversations.history?channel="
		.. channelId .. "&limit=30"
	if latest then
		url = url .. "&latest=" .. latest
	end

	hs.http.asyncGet(
		url,
		{ ["Authorization"] = "Bearer " .. token },
		function(status, response)
			if status ~= 200 then
				callback(nil, "Slack API error: " .. tostring(status))
				return
			end
			local data = hs.json.decode(response)
			if data and data.ok and data.messages then
				-- Reverse to get chronological order (API returns newest first)
				local reversed = {}
				for i = #data.messages, 1, -1 do
					table.insert(reversed, data.messages[i])
				end
				resolveUsers(reversed, function()
					callback(reversed)
				end)
			else
				callback({}, data and data.error)
			end
		end
	)
end

return M
