--- Attention.spoon/api/notion.lua
--- Notion API functions

local M = {}

-- Will be set by init.lua
M.getEnvVar = nil

--- Fetch tasks from a single Notion database
--- @param apiKey string The Notion API key
--- @param databaseId string The database ID
--- @param userId string|nil Optional user ID to filter by
--- @param statuses table Array of status names to filter
--- @param callback function Callback with (tasks, error)
local function fetchFromDatabase(apiKey, databaseId, userId, statuses, statusType, callback)
	-- Build status filters (support both 'status' and 'select' property types)
	local statusFilters = {}
	local propType = statusType or "status"
	for _, status in ipairs(statuses) do
		if propType == "select" then
			table.insert(statusFilters, {
				property = "Status",
				select = { equals = status },
			})
		else
			table.insert(statusFilters, {
				property = "Status",
				status = { equals = status },
			})
		end
	end

	-- Build the filter
	local filter = {
		["and"] = {
			{ ["or"] = statusFilters },
		},
	}

	-- Add user filter if provided (try common property names)
	if userId then
		table.insert(filter["and"], {
			property = "Person",
			people = { contains = userId },
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
					local titleProp = props.Activity and props.Activity.title
						or props.Name and props.Name.title
						or {}
					local statusProp = props.Status and (props.Status.status or props.Status.select) or {}
					local domainProp = props.Domain and props.Domain.select or {}
					local tagsProp = props.Tags and props.Tags.multi_select or {}

					local identifier = ""
					if idProp.prefix and idProp.number then
						identifier = idProp.prefix .. "-" .. idProp.number
					end

					local title = ""
					if titleProp[1] and titleProp[1].plain_text then
						title = titleProp[1].plain_text
					end

					-- Extract domain
					local domain = domainProp.name or nil

					-- Extract tags as array of names
					local tags = {}
					for _, tag in ipairs(tagsProp) do
						if tag.name then
							table.insert(tags, tag.name)
						end
					end

					table.insert(tasks, {
						identifier = identifier,
						title = title,
						status = statusProp.name or "",
						url = page.url,
						id = page.id,
						domain = domain,
						tags = tags,
					})
				end
				callback(tasks)
			else
				callback(nil, "Failed to parse Notion response")
			end
		end
	)
end

--- Fetch Notion tasks assigned to user with specific statuses
--- Supports both single database_id and multiple databases array
--- @param config table Integration config { api_key, database_id, databases, user_id, statuses }
--- @param callback function Callback with (tasks, error)
function M.fetchTasksWithConfig(config, callback)
	local apiKey = config.api_key
	if not apiKey then
		callback(nil, "Notion API key not provided")
		return
	end

	local defaultStatuses = config.statuses or { "In Progress", "Ready" }
	local userId = config.user_id

	-- Build list of databases to query
	local databasesToQuery = {}

	-- Support multiple databases with per-database statuses
	if config.databases and #config.databases > 0 then
		for _, db in ipairs(config.databases) do
			table.insert(databasesToQuery, {
				id = db.database_id,
				statuses = db.statuses or defaultStatuses,
				status_type = db.status_type,
			})
		end
	elseif config.database_id then
		-- Legacy single database support
		table.insert(databasesToQuery, {
			id = config.database_id,
			statuses = defaultStatuses,
		})
	else
		callback(nil, "No Notion database configured")
		return
	end

	-- Fetch from all databases in parallel
	local allTasks = {}
	local pending = #databasesToQuery
	local hasError = false

	local function checkDone()
		pending = pending - 1
		if pending == 0 then
			callback(allTasks)
		end
	end

	print("[Attention] Fetching from " .. #databasesToQuery .. " Notion database(s)")
	for _, db in ipairs(databasesToQuery) do
		print("[Attention] Querying Notion DB: " .. db.id .. " with statuses: " .. table.concat(db.statuses, ", ") .. " (type: " .. (db.status_type or "status") .. ")")
		fetchFromDatabase(apiKey, db.id, userId, db.statuses, db.status_type, function(tasks, err)
			if err then
				print("[Attention] Notion database " .. db.id .. " error: " .. err)
			elseif tasks then
				print("[Attention] Notion database " .. db.id .. " returned " .. #tasks .. " tasks")
				for _, task in ipairs(tasks) do
					table.insert(allTasks, task)
				end
			end
			checkDone()
		end)
	end
end

--- Fetch page detail including blocks (content)
--- @param pageId string The Notion page ID
--- @param apiKey string The Notion API key
--- @param callback function Callback with (pageDetail, error)
function M.fetchDetail(pageId, apiKey, callback)
	if not apiKey then
		callback(nil, "Notion API key not provided")
		return
	end

	-- Fetch page properties first
	hs.http.asyncGet(
		"https://api.notion.com/v1/pages/" .. pageId,
		{
			["Authorization"] = "Bearer " .. apiKey,
			["Notion-Version"] = "2022-06-28",
		},
		function(status, response)
			if status ~= 200 then
				callback(nil, "Notion API error: " .. tostring(status))
				return
			end

			local pageData = hs.json.decode(response)
			if not pageData then
				callback(nil, "Failed to parse page response")
				return
			end

			-- Now fetch blocks (content)
			hs.http.asyncGet(
				"https://api.notion.com/v1/blocks/" .. pageId .. "/children?page_size=100",
				{
					["Authorization"] = "Bearer " .. apiKey,
					["Notion-Version"] = "2022-06-28",
				},
				function(blockStatus, blockResponse)
					local blocks = {}
					if blockStatus == 200 then
						local blockData = hs.json.decode(blockResponse)
						if blockData and blockData.results then
							blocks = blockData.results
						end
					end

					-- Parse properties
					local props = pageData.properties or {}
					local idProp = props.ID and props.ID.unique_id or {}
					local titleProp = props.Activity and props.Activity.title or {}
					local statusProp = props.Status and (props.Status.status or props.Status.select) or {}
					local domainProp = props.Domain and props.Domain.select or {}

					-- Try common property names for tags (multi-select)
					local tagsProp = {}
					for _, propName in ipairs({ "Tags", "Tag", "tags", "tag", "Labels", "labels" }) do
						if props[propName] and props[propName].multi_select then
							tagsProp = props[propName].multi_select
							break
						end
					end

					local identifier = ""
					if idProp.prefix and idProp.number then
						identifier = idProp.prefix .. "-" .. idProp.number
					end

					local title = ""
					if titleProp[1] and titleProp[1].plain_text then
						title = titleProp[1].plain_text
					end

					-- Extract domain
					local domain = domainProp.name or nil

					-- Extract tags as array of names
					local tags = {}
					for _, tag in ipairs(tagsProp) do
						if tag.name then
							table.insert(tags, tag.name)
						end
					end

					-- Convert blocks to plain text content
					local content = {}
					for _, block in ipairs(blocks) do
						local blockType = block.type
						local blockContent = block[blockType]
						if blockContent then
							local richText = blockContent.rich_text or {}
							local text = ""
							for _, rt in ipairs(richText) do
								text = text .. (rt.plain_text or "")
							end
							if text ~= "" then
								-- Add prefix based on block type
								if blockType == "heading_1" then
									text = "# " .. text
								elseif blockType == "heading_2" then
									text = "## " .. text
								elseif blockType == "heading_3" then
									text = "### " .. text
								elseif blockType == "bulleted_list_item" then
									text = "• " .. text
								elseif blockType == "numbered_list_item" then
									text = "- " .. text
								elseif blockType == "to_do" then
									local checked = blockContent.checked and "☑" or "☐"
									text = checked .. " " .. text
								elseif blockType == "code" then
									text = "```\n" .. text .. "\n```"
								elseif blockType == "quote" then
									text = "> " .. text
								end
								table.insert(content, text)
							end
						end
					end

					callback({
						id = pageData.id,
						identifier = identifier,
						title = title,
						status = statusProp.name or "",
						url = pageData.url,
						content = table.concat(content, "\n\n"),
						blocks = blocks,
						domain = domain,
						tags = tags,
					})
				end
			)
		end
	)
end

return M
