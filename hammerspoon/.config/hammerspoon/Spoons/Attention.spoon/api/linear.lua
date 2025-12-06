--- Attention.spoon/api/linear.lua
--- Linear API integration for fetching issues and details
--- @module api.linear

local utils = require("Spoons.Attention.spoon.utils")

local M = {}

--- GraphQL query for fetching assigned issues
--- @private
local ISSUES_QUERY = [[
	query {
		viewer {
			assignedIssues(
				filter: {
					state: { type: { nin: ["completed", "canceled"] } }
				}
				orderBy: updatedAt
				first: 20
			) {
				nodes {
					identifier
					title
					state { name }
					priority
					project { name }
					url
				}
			}
		}
	}
]]

--- GraphQL query for fetching issue details with comments
--- @private
local DETAIL_QUERY = [[
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

--- Fetch all assigned issues from Linear
--- Returns issues that are not completed or canceled
--- @param callback function Callback function(issues, error)
---   - issues: Array of issue objects, or nil on error
---   - error: Error message string, or nil on success
--- @example
---   linear.fetchIssues(function(issues, err)
---     if issues then
---       for _, issue in ipairs(issues) do
---         print(issue.identifier, issue.title)
---       end
---     end
---   end)
function M.fetchIssues(callback)
	local apiKey = utils.getEnvVar("LINEAR_API_KEY")
	if not apiKey then
		callback(nil, "LINEAR_API_KEY not found")
		return
	end

	hs.http.asyncPost(
		"https://api.linear.app/graphql",
		hs.json.encode({ query = ISSUES_QUERY }),
		{ ["Authorization"] = apiKey, ["Content-Type"] = "application/json" },
		function(status, response)
			if status ~= 200 then
				callback(nil, "Linear API error: " .. tostring(status))
				return
			end
			local data = hs.json.decode(response)
			if data and data.data and data.data.viewer then
				callback(data.data.viewer.assignedIssues.nodes)
			else
				callback(nil, "Failed to parse Linear response")
			end
		end
	)
end

--- Fetch detailed information for a specific issue
--- Includes description and comments
--- @param identifier string The issue identifier (e.g., "PROJ-123")
--- @param callback function Callback function(issue, error)
---   - issue: Issue object with full details, or nil on error
---   - error: Error message string, or nil on success
--- @example
---   linear.fetchDetail("PROJ-123", function(issue, err)
---     if issue then
---       print(issue.description)
---       for _, comment in ipairs(issue.comments.nodes) do
---         print(comment.user.name, comment.body)
---       end
---     end
---   end)
function M.fetchDetail(identifier, callback)
	local apiKey = utils.getEnvVar("LINEAR_API_KEY")
	if not apiKey then
		callback(nil, "LINEAR_API_KEY not found")
		return
	end

	hs.http.asyncPost(
		"https://api.linear.app/graphql",
		hs.json.encode({ query = DETAIL_QUERY, variables = { id = identifier } }),
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

--- Get priority label and color for a priority level
--- @param priority number Priority level (0-4, where 0 is no priority)
--- @return string label Human-readable priority label
--- @return string color Hex color code for the priority
--- @example
---   local label, color = linear.getPriorityInfo(1)
---   -- label = "Urgent", color = "#f87171"
function M.getPriorityInfo(priority)
	local priorities = {
		[0] = { label = "No Priority", color = "#666666" },
		[1] = { label = "Urgent", color = "#f87171" },
		[2] = { label = "High", color = "#fb923c" },
		[3] = { label = "Medium", color = "#facc15" },
		[4] = { label = "Low", color = "#94a3b8" },
	}
	local info = priorities[priority] or priorities[0]
	return info.label, info.color
end

return M
