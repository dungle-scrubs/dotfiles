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

	Wezterm.run_child_process({ "mkdir", new_workspace })

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

M.duplicate_workspace = function(window, pane)
	local current_workspace = window:active_workspace()
	local cwd = pane:get_current_working_dir()

	if not cwd then
		Wezterm.log_warn("Cannot duplicate: no current working directory")
		return
	end

	-- Extract the file path from the URL object
	local dir_path = cwd.file_path or tostring(cwd):gsub("^file://", "")

	-- Find next available suffix (workspace-2, workspace-3, etc.)
	local existing_workspaces = Wezterm.mux.get_workspace_names()
	local base_name = current_workspace:gsub("%-(%d+)$", "") -- strip existing -N suffix
	local max_suffix = 1

	for _, ws in ipairs(existing_workspaces) do
		-- Check if workspace matches pattern "basename" or "basename-N"
		if ws == base_name then
			max_suffix = math.max(max_suffix, 1)
		else
			local suffix = ws:match("^" .. base_name:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1") .. "%-(%d+)$")
			if suffix then
				max_suffix = math.max(max_suffix, tonumber(suffix))
			end
		end
	end

	local new_workspace = base_name .. "-" .. (max_suffix + 1)

	window:perform_action(
		act.SwitchToWorkspace({
			name = new_workspace,
			spawn = { cwd = dir_path },
		}),
		pane
	)

	Wezterm.GLOBAL.previous_workspace = current_workspace
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
