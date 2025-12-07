--- Attention Dashboard Configuration
--- This file defines projects and their integrations.
---
--- Each project can have multiple integrations (Slack, Linear).
--- Token env vars reference keys in ~/.env/services/.env

return {
	projects = {
		{
			id = "fuse",
			name = "Fuse",
			color = "#5e6ad2", -- Linear purple
			integrations = {
				slack = {
					token_env = "FUSE_SLACK_USER_TOKEN",
					channels = {},
				},
				notion = {
					api_key_env = "FUSE_NOTION",
					database_id = "25354d7d-0f21-804a-8f4f-d53f59468fc7",
					user_id = "261d872b-594c-81e4-818a-0002156198c7", -- Kevin Frilot
					statuses = { "In Progress", "Ready" },
				},
			},
		},
		{
			id = "rack",
			name = "Rack Warehouse",
			color = "#10b981", -- Green
			integrations = {
				slack = {
					token_env = "SEVEN_EIGHT_SLACK_USER_TOKEN",
					dm_channels = {
						{ channel_id = "D027S0146P7", name = "Jeff" },
					},
				},
			},
		},
		{
			id = "reviewsion",
			name = "Reviewsion",
			color = "#f97316", -- Orange
			integrations = {
				linear = {
					api_key_env = "LINEAR_API_KEY",
					project_names = { "Reviewsion" },
				},
			},
		},
		{
			id = "personal",
			name = "Personal",
			color = "#8b5cf6", -- Purple
			integrations = {
				linear = {
					api_key_env = "LINEAR_API_KEY",
					project_names = { "Personal" },
				},
			},
		},
	},

	-- Calendar stays global (not project-specific)
	calendar = {
		enabled = true,
		-- Optional: filter to specific calendars by name
		calendar_names = {}, -- Empty = all calendars
	},
}
