--- Attention.spoon/api/linear.lua
--- Linear API functions

local M = {}

-- Will be set by init.lua
M.getEnvVar = nil

--- Filter issues by team prefix
--- @param issues table[] Array of issues
--- @param teamIds table Array of team prefixes (e.g., {"FUSE", "REV"})
--- @return table[] filtered Issues matching the team filter
local function filterByTeam(issues, teamIds)
	if not teamIds or #teamIds == 0 then
		return issues
	end

	local filtered = {}
	for _, issue in ipairs(issues) do
		local identifier = issue.identifier or ""
		for _, teamId in ipairs(teamIds) do
			if identifier:match("^" .. teamId .. "%-") then
				table.insert(filtered, issue)
				break
			end
		end
	end
	return filtered
end

--- Filter issues by project name
--- @param issues table[] Array of issues
--- @param projectNames table Array of project names (e.g., {"Personal", "Reviewsion"})
--- @return table[] filtered Issues matching the project filter
local function filterByProject(issues, projectNames)
	if not projectNames or #projectNames == 0 then
		return issues
	end

	-- Build lookup set for faster matching
	local projectSet = {}
	for _, name in ipairs(projectNames) do
		projectSet[name] = true
	end

	local filtered = {}
	for _, issue in ipairs(issues) do
		local projectName = issue.project and issue.project.name
		if projectName and projectSet[projectName] then
			table.insert(filtered, issue)
		end
	end
	return filtered
end

--- Fetch Linear in-progress issues (legacy - uses env var directly)
--- @param callback function Callback with (issues, error)
function M.fetchIssues(callback)
	local apiKey = M.getEnvVar("LINEAR_API_KEY")
	if not apiKey then
		callback(nil, "LINEAR_API_KEY not found")
		return
	end

	M.fetchIssuesWithConfig({ api_key = apiKey, team_ids = {} }, callback)
end

--- Fetch Linear in-progress issues with config
--- @param config table Integration config { api_key, team_ids, project_names }
--- @param callback function Callback with (issues, error)
function M.fetchIssuesWithConfig(config, callback)
	local apiKey = config.api_key
	if not apiKey then
		callback(nil, "Linear API key not provided")
		return
	end

	local query = [[
		query InProgressIssues {
			issues(filter: { state: { type: { eq: "started" } } }, first: 50) {
				nodes {
					identifier
					title
					project { name }
				}
			}
		}
	]]

	hs.http.asyncPost(
		"https://api.linear.app/graphql",
		hs.json.encode({ query = query }),
		{ ["Authorization"] = apiKey, ["Content-Type"] = "application/json" },
		function(status, response)
			if status ~= 200 then
				callback(nil, "Linear API error: " .. tostring(status))
				return
			end
			local data = hs.json.decode(response)
			if data and data.data and data.data.issues then
				local issues = data.data.issues.nodes
				-- Filter by project name if specified (preferred)
				if config.project_names and #config.project_names > 0 then
					issues = filterByProject(issues, config.project_names)
				-- Fall back to team filter for backwards compatibility
				elseif config.team_ids and #config.team_ids > 0 then
					issues = filterByTeam(issues, config.team_ids)
				end
				callback(issues)
			else
				callback(nil, "Failed to parse Linear response")
			end
		end
	)
end

--- Fetch Linear issue details
--- @param identifier string The issue identifier (e.g., "PROJ-123")
--- @param callback function Callback with (issue, error)
function M.fetchDetail(identifier, callback)
	local apiKey = M.getEnvVar("LINEAR_API_KEY")
	if not apiKey then
		callback(nil, "LINEAR_API_KEY not found")
		return
	end

	M.fetchDetailWithConfig(identifier, { api_key = apiKey }, callback)
end

--- Fetch Linear issue details with config
--- @param identifier string The issue identifier
--- @param config table Integration config { api_key }
--- @param callback function Callback with (issue, error)
function M.fetchDetailWithConfig(identifier, config, callback)
	local apiKey = config.api_key
	if not apiKey then
		callback(nil, "Linear API key not provided")
		return
	end

	local query = [[
		query IssueDetail($id: String!) {
			issue(id: $id) {
				identifier
				title
				description
				state { name }
				priority
				project { name }
				url
				comments(first: 10) {
					nodes {
						body
						user { name }
						createdAt
					}
				}
			}
		}
	]]

	hs.http.asyncPost(
		"https://api.linear.app/graphql",
		hs.json.encode({ query = query, variables = { id = identifier } }),
		{ ["Authorization"] = apiKey, ["Content-Type"] = "application/json" },
		function(status, response)
			if status ~= 200 then
				callback(nil, "Linear API error: " .. tostring(status))
				return
			end
			local data = hs.json.decode(response)
			if data and data.data and data.data.issue then
				callback(data.data.issue)
			else
				callback(nil, "Failed to parse Linear issue")
			end
		end
	)
end

return M
