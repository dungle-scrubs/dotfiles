local paths = require("configs.paths")
local util = require("configs.util")
local act = Wezterm.action
local M = {}

-- kill the current workspace and switch back to the previous workspace
M.kill_workspace = function(window, pane, workspace)
	local success, stdout = Wezterm.run_child_process({ "/opt/homebrew/bin/wezterm", "cli", "list", "--format=json" })

	if success then
		local json = Wezterm.json_parse(stdout)
		if not json then
			return
		end

		local workspace_panes = util.filter(json, function(p)
			return p.workspace == workspace
		end)

		M.switch_to_previous_workspace(window, pane)
		Wezterm.GLOBAL.previous_workspace = nil

		for _, p in ipairs(workspace_panes) do
			Wezterm.run_child_process({
				"/opt/homebrew/bin/wezterm",
				"cli",
				"kill-pane",
				"--pane-id=" .. p.pane_id,
			})
		end
	end
end

M.new_scratch_workspace = function(window, pane, workspace)
	local current_workspace = window:active_workspace()
	if current_workspace == workspace then
		return
	end

	-- check if workspace exists
	local new_workspace = Wezterm.home_dir .. "/scratch/" .. workspace
	if util.dir_exists(new_workspace) then
		-- display a warning here to the user
		Wezterm.log_warn("Creating new scratch workspace:", new_workspace, "already exists.")
		return
	end

	os.execute("mkdir " .. new_workspace)

	Wezterm.log_error(new_workspace)
	window:perform_action(
		act.SwitchToWorkspace({
			name = workspace,
			spawn = { cwd = new_workspace },
		}),
		pane
	)

	Wezterm.GLOBAL.previous_workspace = current_workspace
end

M.switch_workspace = function(window, pane, workspace)
	local current_workspace = window:active_workspace()
	if current_workspace == workspace then
		return
	end

	window:perform_action(
		act.SwitchToWorkspace({
			name = workspace,
		}),
		pane
	)
	Wezterm.GLOBAL.previous_workspace = current_workspace
end

M.switch_to_previous_workspace = function(window, pane)
	local current_workspace = window:active_workspace()
	local workspace = Wezterm.GLOBAL.previous_workspace

	if current_workspace == workspace or Wezterm.GLOBAL.previous_workspace == nil then
		return
	end

	M.switch_workspace(window, pane, workspace)
end

M.get_files_in_directory = function(path)
	local files = {}
	local pfile = io.popen('ls -1 "' .. path .. '"')
	if not pfile then
		return {}
	end

	for filename in pfile:lines() do
		table.insert(files, {
			label = filename,
			id = path .. "/" .. filename,
		})
	end

	pfile:close()

	return files
end

return M
