--- Attention.spoon/api/linear.lua
--- Linear API functions

local M = {}

-- Will be set by init.lua
M.getEnvVar = nil

--- Fetch Linear in-progress issues
--- @param callback function Callback with (issues, error)
function M.fetchIssues(callback)
	local apiKey = M.getEnvVar("LINEAR_API_KEY")
	if not apiKey then
		callback(nil, "LINEAR_API_KEY not found")
		return
	end

	local query = [[
		query InProgressIssues {
			issues(filter: { state: { type: { eq: "started" } } }, first: 20) {
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
				callback(data.data.issues.nodes)
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
