local act = Wezterm.action

local M = {}

local home_dir = Wezterm.home_dir .. "/"
local fd = "/opt/homebrew/bin/fd"
local dev = home_dir .. "dev"

--- Opens a fuzzy picker to select a project from ~/dev, then spawns a new tab
--- at that directory with the tab named after the project folder.
M.open = function(window, pane)
	local projects = {}

	local ok, stdout, stderr = Wezterm.run_child_process({
		fd,
		"-HI",
		".git$",
		"--max-depth=3",
		"--prune",
		"-E",
		"*_archive*",
		dev,
	})

	if not ok then
		Wezterm.log_error("project_tab: failed to run fd. " .. stderr)
		return
	end

	for line in stdout:gmatch("([^\n]*)\n?") do
		local project_path = line:gsub("/.git.*", ""):gsub("/$", "")
		local label = project_path:gsub(home_dir, "")
		local _, _, name = string.find(project_path, ".*/(.+)")
		if name then
			name = name:gsub(".git", "")
			table.insert(projects, { label = label, id = name, path = project_path })
		end
	end

	window:perform_action(
		act.InputSelector({
			action = Wezterm.action_callback(function(win, _, id, label)
				if not id or not label then
					return
				end

				local path = home_dir .. label
				win:perform_action(
					act.SpawnCommandInNewTab({
						cwd = path,
					}),
					pane
				)

				-- Set tab title after spawn
				Wezterm.time.call_after(0.1, function()
					local tab = win:active_tab()
					if tab then
						tab:set_title(id)
					end
				end)
			end),
			fuzzy = true,
			title = "Open project in new tab",
			choices = projects,
		}),
		pane
	)
end

return M
