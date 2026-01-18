local paths = require("configs.paths")
local util = require("configs.util")
local act = Wezterm.action

local M = {}

---Kills all panes in a workspace and switches to the previous workspace
---@param window Window
---@param pane Pane
---@param workspace string
function M.kill(window, pane, workspace)
	local success, stdout = Wezterm.run_child_process({
		paths.wezterm,
		"cli",
		"list",
		"--format=json",
	})

	if not success then
		Wezterm.log_error("workspace.kill: failed to list panes")
		return
	end

	local json = Wezterm.json_parse(stdout)
	if not json then
		Wezterm.log_error("workspace.kill: failed to parse JSON")
		return
	end

	local workspace_panes = util.filter(json, function(p)
		return p.workspace == workspace
	end)

	M.switch_to_previous(window, pane)
	Wezterm.GLOBAL.previous_workspace = nil

	for _, p in ipairs(workspace_panes) do
		Wezterm.run_child_process({
			paths.wezterm,
			"cli",
			"kill-pane",
			"--pane-id=" .. p.pane_id,
		})
	end
end

---Switches to a workspace, storing the current one as previous
---@param window Window
---@param pane Pane
---@param workspace string
function M.switch(window, pane, workspace)
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

---Switches to the previously active workspace
---@param window Window
---@param pane Pane
function M.switch_to_previous(window, pane)
	local current_workspace = window:active_workspace()
	local workspace = Wezterm.GLOBAL.previous_workspace

	if not workspace or current_workspace == workspace then
		return
	end

	M.switch(window, pane, workspace)
end

---Duplicates the current workspace with an incremented suffix
---@param window Window
---@param pane Pane
function M.duplicate(window, pane)
	local current_workspace = window:active_workspace()
	local cwd = pane:get_current_working_dir()

	if not cwd then
		Wezterm.log_warn("workspace.duplicate: no current working directory")
		return
	end

	local dir_path = cwd.file_path
	if not dir_path then
		dir_path = tostring(cwd):gsub("^file://[^/]*/", "/")
	end

	local existing_workspaces = Wezterm.mux.get_workspace_names()
	local base_name = current_workspace:gsub("%-(%d+)$", "")
	local max_suffix = 1

	for _, ws in ipairs(existing_workspaces) do
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

return M
