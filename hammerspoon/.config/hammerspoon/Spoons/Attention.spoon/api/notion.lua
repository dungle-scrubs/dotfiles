--- Attention.spoon/api/notion.lua
--- Notion API functions

local M = {}

-- Will be set by init.lua
M.getEnvVar = nil

--- Fetch Notion tasks assigned to user with specific statuses
--- @param config table Integration config { api_key, database_id, user_id, statuses }
--- @param callback function Callback with (tasks, error)
function M.fetchTasksWithConfig(config, callback)
	local apiKey = config.api_key
	if not apiKey then
		callback(nil, "Notion API key not provided")
		return
	end

	local databaseId = config.database_id
	if not databaseId then
		callback(nil, "Notion database ID not provided")
		return
	end

	-- Build status filters
	local statusFilters = {}
	local statuses = config.statuses or { "In Progress", "Ready" }
	for _, status in ipairs(statuses) do
		table.insert(statusFilters, {
			property = "Status",
			status = { equals = status },
		})
	end

	-- Build the filter
	local filter = {
		["and"] = {
			{ ["or"] = statusFilters },
		},
	}

	-- Add user filter if provided
	if config.user_id then
		table.insert(filter["and"], {
			property = "Person",
			people = { contains = config.user_id },
		})
	end

	local body = hs.json.encode({ filter = filter })

	hs.http.asyncPost(
		"https://api.notion.com/v1/databases/" .. databaseId .. "/query",
		body,
		{
			["Authorization"] = "Bearer " .. apiKey,
			["Content-Type"] = "application/json",
			["Notion-Version"] = "2022-06-28",
		},
		function(status, response)
			if status ~= 200 then
				callback(nil, "Notion API error: " .. tostring(status))
				return
			end
			local data = hs.json.decode(response)
			if data and data.results then
				local tasks = {}
				for _, page in ipairs(data.results) do
					local props = page.properties or {}
					local idProp = props.ID and props.ID.unique_id or {}
					local titleProp = props.Activity and props.Activity.title or {}
					local statusProp = props.Status and props.Status.status or {}

					local identifier = ""
					if idProp.prefix and idProp.number then
						identifier = idProp.prefix .. "-" .. idProp.number
					end

					local title = ""
					if titleProp[1] and titleProp[1].plain_text then
						title = titleProp[1].plain_text
					end

					table.insert(tasks, {
						identifier = identifier,
						title = title,
						status = statusProp.name or "",
						url = page.url,
						id = page.id,
					})
				end
				callback(tasks)
			else
				callback(nil, "Failed to parse Notion response")
			end
		end
	)
end

return M
