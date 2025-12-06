--- Attention.spoon/api/slack.lua
--- Slack API functions

local M = {}

-- Will be set by init.lua
M.getEnvVar = nil

-- User cache for resolving IDs to names
local userCache = {}

--- Get a user's name from cache
--- @param userId string The Slack user ID
--- @return string name The user's name (or userId if not cached)
function M.getUserName(userId)
	return userCache[userId] or userId
end

--- Fetch a single Slack user's info
--- @param userId string The user ID
--- @param token string The Slack token
--- @param callback function Callback with (name)
local function fetchUser(userId, token, callback)
	if userCache[userId] then
		callback(userCache[userId])
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
					userCache[userId] = name
					callback(name)
					return
				end
			end
			callback(userId)
		end
	)
end

--- Resolve user IDs to names for a list of messages
--- @param messages table The messages containing user IDs
--- @param token string The Slack token
--- @param callback function Callback when done
local function resolveUsers(messages, token, callback)
	local userIds = {}
	local seen = {}
	for _, msg in ipairs(messages or {}) do
		local uid = msg.user
		if uid and not seen[uid] and not userCache[uid] then
			seen[uid] = true
			table.insert(userIds, uid)
		end
	end

	if #userIds == 0 then
		callback()
		return
	end

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

--- Fetch Slack mentions and DMs
--- @param callback function Callback with ({dms, channels}, error)
function M.fetchMentions(callback)
	local token = M.getEnvVar("SLACK_USER_TOKEN")
	if not token then
		callback(nil, "SLACK_USER_TOKEN not found")
		return
	end

	hs.http.asyncGet(
		"https://slack.com/api/auth.test",
		{ ["Authorization"] = "Bearer " .. token },
		function(status, response)
			if status ~= 200 then
				callback(nil, "Slack auth error")
				return
			end
			local authData = hs.json.decode(response)
			if not authData or not authData.user_id then
				callback(nil, "Failed to get Slack user ID")
				return
			end

			local userId = authData.user_id
			local results = { dms = {}, channels = {} }
			local pending = 2

			local function checkDone()
				pending = pending - 1
				if pending == 0 then
					callback(results)
				end
			end

			local function dedupeByUser(messages)
				local seen = {}
				local deduped = {}
				for _, msg in ipairs(messages or {}) do
					local username = msg.username or "unknown"
					if not seen[username] then
						seen[username] = true
						table.insert(deduped, msg)
					end
				end
				return deduped
			end

			-- Fetch DMs
			hs.http.asyncGet(
				"https://slack.com/api/search.messages?query=to:me&count=20&sort=timestamp",
				{ ["Authorization"] = "Bearer " .. token },
				function(s, r)
					if s == 200 then
						local data = hs.json.decode(r)
						if data and data.ok and data.messages then
							local dms = {}
							for _, msg in ipairs(data.messages.matches or {}) do
								if msg.channel and msg.channel.is_im then
									table.insert(dms, msg)
								end
							end
							results.dms = dedupeByUser(dms)
						end
					end
					checkDone()
				end
			)

			-- Fetch channel @mentions
			hs.http.asyncGet(
				"https://slack.com/api/search.messages?query=<@" .. userId .. ">&count=20&sort=timestamp",
				{ ["Authorization"] = "Bearer " .. token },
				function(s, r)
					if s == 200 then
						local data = hs.json.decode(r)
						if data and data.ok and data.messages then
							local channels = {}
							for _, msg in ipairs(data.messages.matches or {}) do
								if msg.channel and not msg.channel.is_im then
									table.insert(channels, msg)
								end
							end
							results.channels = dedupeByUser(channels)
						end
					end
					checkDone()
				end
			)
		end
	)
end

--- Fetch thread replies
--- @param channelId string The channel ID
--- @param threadTs string The thread timestamp
--- @param callback function Callback with (messages, error)
function M.fetchThread(channelId, threadTs, callback)
	local token = M.getEnvVar("SLACK_USER_TOKEN")
	if not token then
		callback(nil, "SLACK_USER_TOKEN not found")
		return
	end

	local url = "https://slack.com/api/conversations.replies?channel=" .. channelId .. "&ts=" .. threadTs .. "&limit=50"
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
				resolveUsers(data.messages, token, function()
					callback(data.messages)
				end)
			else
				callback({}, data and data.error)
			end
		end
	)
end

--- Fetch channel history
--- @param channelId string The channel ID
--- @param callback function Callback with (messages, error)
--- @param oldest string|nil Optional oldest timestamp to fetch messages before
function M.fetchHistory(channelId, callback, oldest)
	local token = M.getEnvVar("SLACK_USER_TOKEN")
	if not token then
		callback(nil, "SLACK_USER_TOKEN not found")
		return
	end

	local url = "https://slack.com/api/conversations.history?channel=" .. channelId .. "&limit=30"
	if oldest then
		url = url .. "&latest=" .. oldest
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
				local reversed = {}
				for i = #data.messages, 1, -1 do
					table.insert(reversed, data.messages[i])
				end
				resolveUsers(reversed, token, function()
					callback(reversed)
				end)
			else
				callback({}, data and data.error)
			end
		end
	)
end

return M
