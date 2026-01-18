local paths = require("configs.paths")
local act = Wezterm.action

local M = {}

local home = Wezterm.home_dir

---@class FindReposOpts
---@field max_depth? number Max depth for fd search (default 4)
---@field search_paths? string[] Paths to search (default {paths.dev})

---Finds git repositories using fd
---@param opts? FindReposOpts
---@return table[] repos Array of {path, name, relative} tables
local function find_git_repos(opts)
	opts = opts or {}
	local max_depth = opts.max_depth or 4
	local search_paths = opts.search_paths or { paths.dev }

	local args = {
		paths.fd,
		"-HI",
		".git$",
		"--max-depth=" .. max_depth,
		"--prune",
		"-E",
		"_*",
	}

	for _, p in ipairs(search_paths) do
		table.insert(args, p)
	end

	local ok, stdout, stderr = Wezterm.run_child_process(args)

	if not ok then
		Wezterm.log_error("projects: failed to run fd: " .. (stderr or "unknown error"))
		return {}
	end

	local repos = {}
	for line in stdout:gmatch("([^\n]*)\n?") do
		local path = line:gsub("/.git.*", ""):gsub("/$", "")
		local name = path:match("([^/]+)$")
		local relative = path:gsub(home .. "/", "")

		if name then
			name = name:gsub(".git", "")
			table.insert(repos, {
				path = path,
				name = name,
				relative = relative,
			})
		end
	end

	return repos
end

---Opens a fuzzy picker to select a project, then switches to a workspace
---@param window Window
---@param pane Pane
function M.open_workspace(window, pane)
	local repos = find_git_repos()

	local choices = {}
	for _, repo in ipairs(repos) do
		table.insert(choices, {
			label = repo.relative,
			id = repo.name,
		})
	end

	Wezterm.GLOBAL.previous_workspace = window:active_workspace()

	window:perform_action(
		act.InputSelector({
			action = Wezterm.action_callback(function(win, _, id, label)
				if not id or not label then
					return
				end

				win:perform_action(
					act.SwitchToWorkspace({
						name = id,
						spawn = { cwd = home .. "/" .. label },
					}),
					pane
				)
			end),
			fuzzy = true,
			title = "Select project",
			choices = choices,
		}),
		pane
	)
end

---Opens a fuzzy picker to select a project, then spawns a new tab
---@param window Window
---@param pane Pane
function M.open_tab(window, pane)
	local repos = find_git_repos({ max_depth = 3, search_paths = { paths.dev } })

	local choices = {}
	for _, repo in ipairs(repos) do
		table.insert(choices, {
			label = repo.name .. "  " .. repo.relative,
			id = repo.path,
		})
	end

	window:perform_action(
		act.InputSelector({
			action = Wezterm.action_callback(function(win, _, id)
				if not id then
					return
				end

				local project_name = id:match("([^/]+)$")

				win:perform_action(
					act.SpawnCommandInNewTab({
						cwd = id,
					}),
					pane
				)

				Wezterm.time.call_after(0.1, function()
					local tab = win:active_tab()
					if tab and project_name then
						tab:set_title(project_name)
					end
				end)
			end),
			fuzzy = true,
			title = "Open project in new tab",
			choices = choices,
		}),
		pane
	)
end

return M
