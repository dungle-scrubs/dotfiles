local act = Wezterm.action

local M = {}

local home_dir = Wezterm.home_dir .. "/"

local fd = "/opt/homebrew/bin/fd"
local lsrc = home_dir .. ".local/src"
local dev = home_dir .. "dev"

-- from https://github.com/wez/wezterm/discussions/4796
M.open = function(window, pane)
	local repos = {}
	local home = home_dir

	local ok, stdout, stderr = Wezterm.run_child_process({
		fd,
		"-HI",
		".git$",
		"--max-depth=4",
		-- `prune` means it won't waste time searching inside of the dirs, fd will stop once it reaches them
		"--prune",
		"-E",
		"*_archive*", -- Exclude any path containing _archive
		lsrc,
		dev,
		-- projects,
		-- scratch,
		-- add more paths here
	})

	if not ok then
		Wezterm.log_error("Sessionizera: failed to run fd. " .. stderr)
		return
	end

	-- define variables from from file paths extractions and
	-- fill table with results
	for line in stdout:gmatch("([^\n]*)\n?") do
		-- create label from file path
		local project = line:gsub("/.git.*", "")
		project = project:gsub("/$", "")
		local label = project:gsub(home, "")

		-- extract id. Used for workspace name
		local _, _, id = string.find(project, ".*/(.+)")
		id = id:gsub(".git", "") -- bare repo dirs typically end in .git, remove if so.

		table.insert(repos, { label = tostring(label), id = tostring(id) })
	end

	-- update previous_workspace before changing to new workspace.
	Wezterm.GLOBAL.previous_workspace = window:active_workspace()
	window:perform_action(
		act.InputSelector({
			action = Wezterm.action_callback(function(win, _, id, label)
				if not id and not label then
					return
				else
					win:perform_action(
						act.SwitchToWorkspace({
							name = id,
							spawn = { cwd = home .. label },
						}),
						pane
					)
				end
			end),
			fuzzy = true,
			title = "Select project",
			choices = repos,
		}),
		pane
	)
end

return M
