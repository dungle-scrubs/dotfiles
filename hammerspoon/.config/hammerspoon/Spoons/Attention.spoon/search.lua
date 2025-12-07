--- Attention.spoon/search.lua
--- Fuzzy search/filter logic

local M = {}

--- Substring match: checks if query appears as substring in target (case-insensitive)
--- @param query string The search query
--- @param target string The text to search in
--- @return boolean matches True if query is found in target
function M.fuzzyMatch(query, target)
	if not query or query == "" then
		return true
	end
	if not target then
		return false
	end

	local lowerQuery = query:lower()
	local lowerTarget = target:lower()

	return lowerTarget:find(lowerQuery, 1, true) ~= nil
end

--- Check if a calendar event matches the search query
--- @param event table Calendar event
--- @param query string Search query
--- @return boolean matches
function M.matchCalendarEvent(event, query)
	if not query or query == "" then
		return true
	end
	return M.fuzzyMatch(query, event.title or "")
		or M.fuzzyMatch(query, event.location or "")
		or M.fuzzyMatch(query, event.calendar or "")
end

--- Check if a Linear issue matches the search query
--- @param issue table Linear issue
--- @param query string Search query
--- @return boolean matches
function M.matchLinearIssue(issue, query)
	if not query or query == "" then
		return true
	end
	return M.fuzzyMatch(query, issue.identifier or "")
		or M.fuzzyMatch(query, issue.title or "")
		or M.fuzzyMatch(query, issue.project and issue.project.name or "")
end

--- Check if a Slack message matches the search query
--- @param msg table Slack message
--- @param query string Search query
--- @return boolean matches
function M.matchSlackMessage(msg, query)
	if not query or query == "" then
		return true
	end
	return M.fuzzyMatch(query, msg.text or "")
		or M.fuzzyMatch(query, msg.username or "")
		or M.fuzzyMatch(query, msg.channel and msg.channel.name or "")
end

--- Check if a Notion task matches the search query
--- @param task table Notion task
--- @param query string Search query
--- @return boolean matches
function M.matchNotionTask(task, query)
	if not query or query == "" then
		return true
	end
	return M.fuzzyMatch(query, task.identifier or "")
		or M.fuzzyMatch(query, task.title or "")
		or M.fuzzyMatch(query, task.status or "")
end

--- Check if a project matches the search query (by name)
--- @param projectName string Project name
--- @param query string Search query
--- @return boolean matches
function M.matchProject(projectName, query)
	if not query or query == "" then
		return true
	end
	return M.fuzzyMatch(query, projectName)
end

--- Filter calendar events by query
--- @param events table[] Calendar events
--- @param query string Search query
--- @return table[] filtered Matching events
function M.filterCalendarEvents(events, query)
	if not query or query == "" then
		return events
	end

	local filtered = {}
	for _, event in ipairs(events or {}) do
		if M.matchCalendarEvent(event, query) then
			table.insert(filtered, event)
		end
	end
	return filtered
end

--- Filter Linear issues by query
--- @param issues table[] Linear issues
--- @param query string Search query
--- @return table[] filtered Matching issues
function M.filterLinearIssues(issues, query)
	if not query or query == "" then
		return issues
	end

	local filtered = {}
	for _, issue in ipairs(issues or {}) do
		if M.matchLinearIssue(issue, query) then
			table.insert(filtered, issue)
		end
	end
	return filtered
end

--- Filter Slack messages by query
--- @param messages table[] Slack messages
--- @param query string Search query
--- @return table[] filtered Matching messages
function M.filterSlackMessages(messages, query)
	if not query or query == "" then
		return messages
	end

	local filtered = {}
	for _, msg in ipairs(messages or {}) do
		if M.matchSlackMessage(msg, query) then
			table.insert(filtered, msg)
		end
	end
	return filtered
end

--- Filter Notion tasks by query
--- @param tasks table[] Notion tasks
--- @param query string Search query
--- @return table[] filtered Matching tasks
function M.filterNotionTasks(tasks, query)
	if not query or query == "" then
		return tasks
	end

	local filtered = {}
	for _, task in ipairs(tasks or {}) do
		if M.matchNotionTask(task, query) then
			table.insert(filtered, task)
		end
	end
	return filtered
end

--- Filter entire data set by query
--- @param data table The full data { projects, calendar }
--- @param query string Search query
--- @return table filtered Filtered data with same structure
function M.filterAll(data, query)
	if not query or query == "" then
		return data
	end

	local filtered = {
		projects = {},
		calendar = M.filterCalendarEvents(data.calendar or {}, query),
	}

	for projectId, projectData in pairs(data.projects or {}) do
		local filteredLinear = M.filterLinearIssues(projectData.linear or {}, query)
		local filteredNotion = M.filterNotionTasks(projectData.notion or {}, query)
		local filteredDms = M.filterSlackMessages(projectData.slack and projectData.slack.dms or {}, query)
		local filteredChannels = M.filterSlackMessages(projectData.slack and projectData.slack.channels or {}, query)

		filtered.projects[projectId] = {
			linear = filteredLinear,
			notion = filteredNotion,
			slack = {
				dms = filteredDms,
				channels = filteredChannels,
			},
		}
	end

	return filtered
end

--- Check if a project has any items
--- @param projectData table The project data { linear, notion, slack }
--- @return boolean hasItems True if project has any items
function M.projectHasItems(projectData)
	if not projectData then
		return false
	end

	local linearCount = #(projectData.linear or {})
	local notionCount = #(projectData.notion or {})
	local slackDms = projectData.slack and projectData.slack.dms or {}
	local slackChannels = projectData.slack and projectData.slack.channels or {}
	local slackCount = #slackDms + #slackChannels

	return (linearCount + notionCount + slackCount) > 0
end

return M
