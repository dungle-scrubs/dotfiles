--- Attention.spoon/fetch.lua
--- Multi-project fetch orchestrator

local M = {}

-- Dependencies will be injected
M.config = nil
M.linearApi = nil
M.slackApi = nil
M.calendarApi = nil
M.notionApi = nil

--- Fetch data for a single project
--- @param project table The project config
--- @param callback function Callback with (projectId, { linear, slack })
local function fetchProject(project, callback)
	local results = { linear = {}, slack = { dms = {}, channels = {} }, notion = {} }
	local pending = 0

	local function checkDone()
		pending = pending - 1
		if pending <= 0 then
			callback(project.id, results)
		end
	end

	-- Count integrations
	if project.integrations then
		if project.integrations.linear then
			pending = pending + 1
		end
		if project.integrations.slack then
			pending = pending + 1
		end
		if project.integrations.notion then
			pending = pending + 1
		end
	end

	if pending == 0 then
		callback(project.id, results)
		return
	end

	-- Fetch Linear issues
	if project.integrations and project.integrations.linear then
		local linearConfig = project.integrations.linear
		local apiKey = M.config.resolveEnvVar(linearConfig.api_key_env)
		if apiKey then
			M.linearApi.fetchIssuesWithConfig({
				api_key = apiKey,
				team_ids = linearConfig.team_ids or {},
				project_names = linearConfig.project_names or {},
			}, function(issues, err)
				if err then
					print("[Attention] Linear error for " .. project.id .. ": " .. err)
				end
				results.linear = issues or {}
				checkDone()
			end)
		else
			print("[Attention] No Linear API key for " .. project.id)
			checkDone()
		end
	end

	-- Fetch Slack mentions or DM latest
	if project.integrations and project.integrations.slack then
		local slackConfig = project.integrations.slack
		local token = M.config.resolveEnvVar(slackConfig.token_env)
		if token then
			-- Check if using dm_channels mode (fetch latest from specific DMs)
			if slackConfig.dm_channels and #slackConfig.dm_channels > 0 then
				M.slackApi.fetchDMLatestWithConfig({
					token = token,
					dm_channels = slackConfig.dm_channels,
				}, function(slackData, err)
					if err then
						print("[Attention] Slack error for " .. project.id .. ": " .. err)
					end
					results.slack = slackData or { dms = {}, channels = {} }
					checkDone()
				end)
			else
				-- Default: fetch mentions
				M.slackApi.fetchMentionsWithConfig({
					token = token,
					channels = slackConfig.channels or {},
				}, function(slackData, err)
					if err then
						print("[Attention] Slack error for " .. project.id .. ": " .. err)
					end
					results.slack = slackData or { dms = {}, channels = {} }
					checkDone()
				end)
			end
		else
			print("[Attention] No Slack token for " .. project.id)
			checkDone()
		end
	end

	-- Fetch Notion tasks
	if project.integrations and project.integrations.notion then
		local notionConfig = project.integrations.notion
		local apiKey = M.config.resolveEnvVar(notionConfig.api_key_env)
		if apiKey then
			M.notionApi.fetchTasksWithConfig({
				api_key = apiKey,
				database_id = notionConfig.database_id,
				user_id = notionConfig.user_id,
				statuses = notionConfig.statuses or { "In Progress", "Ready" },
			}, function(tasks, err)
				if err then
					print("[Attention] Notion error for " .. project.id .. ": " .. err)
				end
				results.notion = tasks or {}
				checkDone()
			end)
		else
			print("[Attention] No Notion API key for " .. project.id)
			checkDone()
		end
	end
end

--- Fetch data for all projects in parallel
--- @param callback function Callback with { projects: { [id]: { linear, slack } }, calendar: [] }
function M.fetchAll(callback)
	local config = M.config.getConfig()
	local projects = config.projects or {}
	local calendarConfig = config.calendar or { enabled = true }

	local results = {
		projects = {},
		calendar = {},
	}

	-- Count total pending operations (all projects + calendar if enabled)
	local pending = #projects
	if calendarConfig.enabled then
		pending = pending + 1
	end

	if pending == 0 then
		callback(results)
		return
	end

	local function checkDone()
		pending = pending - 1
		if pending <= 0 then
			callback(results)
		end
	end

	-- Fetch each project in parallel
	for _, project in ipairs(projects) do
		fetchProject(project, function(projectId, projectResults)
			results.projects[projectId] = projectResults
			checkDone()
		end)
	end

	-- Fetch calendar (global, not project-specific)
	if calendarConfig.enabled then
		M.calendarApi.fetchUpcomingEvents(nil, function(events, err)
			if err then
				print("[Attention] Calendar error: " .. err)
			end
			results.calendar = events or {}
			checkDone()
		end)
	end
end

--- Count total items across all projects and calendar
--- @param data table The fetched data
--- @return number count Total item count
function M.countItems(data)
	local count = 0

	-- Count calendar events
	count = count + #(data.calendar or {})

	-- Count items per project
	for _, projectData in pairs(data.projects or {}) do
		count = count + #(projectData.linear or {})
		count = count + #(projectData.notion or {})
		if projectData.slack then
			count = count + #(projectData.slack.dms or {})
			count = count + #(projectData.slack.channels or {})
		end
	end

	return count
end

--- Get projects in display order (preserves config order)
--- @param data table The fetched data
--- @return table[] projects Array of { id, name, color, data }
function M.getProjectsInOrder(data)
	local config = M.config.getConfig()
	local orderedProjects = {}

	for _, project in ipairs(config.projects or {}) do
		local projectData = data.projects[project.id]
		if projectData then
			table.insert(orderedProjects, {
				id = project.id,
				name = project.name,
				color = project.color or "#5e6ad2",
				data = projectData,
			})
		end
	end

	return orderedProjects
end

return M
