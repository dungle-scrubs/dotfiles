local colors = require("configs.colors")
local util = require("configs.util")
local focus_zoom = require("functions.focus_zoom")

local M = {}

local icons = {
	pane = Wezterm.nerdfonts.cod_layout,
	tab = Wezterm.nerdfonts.md_tab,
	workspace = Wezterm.nerdfonts.cod_multiple_windows,
	git = Wezterm.nerdfonts.dev_git_branch,
	code = Wezterm.nerdfonts.fa_code,
	zoom = Wezterm.nerdfonts.cod_screen_full,
	arrow_up = Wezterm.nerdfonts.fa_arrow_up,
	arrow_down = Wezterm.nerdfonts.fa_arrow_down,
	arrow_right = Wezterm.nerdfonts.cod_arrow_small_right,
	claude = Wezterm.nerdfonts.md_robot,
}

---Adds key table hints to the status elements
---@param elements table
---@param name string
---@param config table
local function add_keytable_hints(elements, name, config)
	if not config or not config.key_tables or not config.key_tables[name] then
		return
	end

	local key_table = config.key_tables[name]
	local need_comma = false

	for _, binding in ipairs(key_table) do
		if binding.key and string.lower(binding.key) ~= "escape" then
			if need_comma then
				table.insert(elements, { Foreground = { Color = colors.text } })
				table.insert(elements, { Text = ", " })
			end

			local description = binding.desc or binding.key

			table.insert(elements, { Foreground = { Color = colors.key } })
			table.insert(elements, { Text = binding.key })
			table.insert(elements, { Foreground = { Color = colors.text } })
			table.insert(elements, { Text = " " .. icons.arrow_right .. "  " })
			table.insert(elements, { Attribute = { Italic = true } })
			table.insert(elements, { Text = description })
			table.insert(elements, { Attribute = { Italic = false } })

			need_comma = true
		end
	end

	table.insert(elements, { Text = " " })
end

---Adds the active key table name with icon to status elements
---@param elements table
---@param name string
local function add_keytable_name(elements, name)
	if icons[name] then
		table.insert(elements, { Foreground = { Color = colors.yellow_alt } })
		table.insert(elements, { Background = { Color = colors.background } })
		table.insert(elements, { Text = " " .. icons[name] .. " " })
	end

	table.insert(elements, { Foreground = { Color = colors.yellow_alt } })
	table.insert(elements, { Background = { Color = colors.background } })
	table.insert(elements, { Text = " " .. name .. " " })
	table.insert(elements, { Text = "|" })
end

---Adds git branch and ahead/behind info to status elements
---@param elements table
---@param pane Pane
local function add_git_info(elements, pane)
	local cwd = pane:get_current_working_dir()
	if not cwd then
		return
	end

	local cwd_path = cwd.file_path or ""

	local branch_ok, branch_stdout = Wezterm.run_child_process({
		"git", "-C", cwd_path, "branch", "--show-current",
	})

	if not branch_ok then
		return
	end

	local branch = branch_stdout:gsub("%s+", "")
	if branch == "" then
		return
	end

	local count_ok, count_stdout = Wezterm.run_child_process({
		"git", "-C", cwd_path, "rev-list", "--left-right", "--count", "HEAD...@{upstream}",
	})

	local ahead, behind = 0, 0
	if count_ok and count_stdout then
		ahead, behind = count_stdout:match("(%d+)%s+(%d+)")
		ahead = tonumber(ahead) or 0
		behind = tonumber(behind) or 0
	end

	local project_name = util.basename(cwd_path)
	if project_name and #project_name > 9 then
		project_name = project_name:sub(1, 9) .. "…"
	end

	if project_name and project_name ~= "" then
		table.insert(elements, { Foreground = { Color = colors.purple_alt } })
		table.insert(elements, { Background = { Color = colors.background } })
		table.insert(elements, { Text = " " .. project_name .. " " })
	end

	table.insert(elements, { Foreground = { Color = colors.green } })
	table.insert(elements, { Background = { Color = colors.background } })
	table.insert(elements, { Text = icons.git .. " " .. branch })

	if ahead > 0 or behind > 0 then
		table.insert(elements, { Foreground = { Color = colors.blue_bright } })
		table.insert(elements, { Text = " " })

		if ahead > 0 then
			table.insert(elements, { Text = icons.arrow_up .. ahead })
		end

		if behind > 0 then
			if ahead > 0 then
				table.insert(elements, { Text = " " })
			end
			table.insert(elements, { Foreground = { Color = colors.red } })
			table.insert(elements, { Text = icons.arrow_down .. behind })
		end
	end

	table.insert(elements, { Text = " " })
	table.insert(elements, { Text = "|" })
end

---Adds workspace indicator squares to status elements
---@param elements table
---@param active_workspace string
local function add_workspace_indicators(elements, active_workspace)
	local workspaces = Wezterm.mux.get_workspace_names()
	if #workspaces <= 1 then
		return
	end

	table.sort(workspaces)

	table.insert(elements, { Background = { Color = colors.background } })
	table.insert(elements, { Text = " " })
	for i, ws in ipairs(workspaces) do
		if ws == active_workspace then
			table.insert(elements, { Foreground = { Color = colors.green } })
		else
			table.insert(elements, { Foreground = { Color = colors.inactive_fg } })
		end
		table.insert(elements, { Background = { Color = colors.background } })
		table.insert(elements, { Text = "■" })
		if i < #workspaces then
			table.insert(elements, { Text = " " })
		end
	end
end

---Adds workspace name to status elements
---@param elements table
---@param workspace string|nil
local function add_workspace(elements, workspace)
	if workspace then
		table.insert(elements, "ResetAttributes")
		table.insert(elements, { Foreground = { Color = colors.inactive_fg } })
		table.insert(elements, { Text = " " .. workspace .. " " })
		add_workspace_indicators(elements, workspace)
	end
end

---Adds focus zoom indicator to status elements
---@param elements table
local function add_focus_zoom_indicator(elements)
	if focus_zoom.is_enabled() then
		table.insert(elements, { Foreground = { Color = colors.cyan } })
		table.insert(elements, { Background = { Color = colors.background } })
		table.insert(elements, { Text = " " .. icons.zoom .. " ZOOM " })
		table.insert(elements, { Text = "|" })
	end
end

---Load work directories from config file
---@return table
local function load_work_dirs()
	local home = os.getenv("HOME") or ""
	local path = home .. "/.config/claude-work-dirs"
	local file = io.open(path, "r")
	if not file then
		return {}
	end

	local dirs = {}
	for line in file:lines() do
		line = line:gsub("^%s+", ""):gsub("%s+$", "")
		if line ~= "" and not line:match("^#") then
			local dir = line:match("^([^:]+)")
			if dir then
				table.insert(dirs, dir)
			end
		end
	end
	file:close()
	return dirs
end

local work_dirs = load_work_dirs()

---Adds Claude account indicator to status elements
---@param elements table
---@param pane Pane
local function add_claude_indicator(elements, pane)
	local cwd = pane:get_current_working_dir()
	if not cwd then
		return
	end

	local cwd_path = cwd.file_path or ""
	for _, dir in ipairs(work_dirs) do
		if cwd_path:find(dir, 1, true) then
			table.insert(elements, { Foreground = { Color = colors.cyan } })
			table.insert(elements, { Background = { Color = colors.background } })
			table.insert(elements, { Text = " " .. icons.claude .. " WORK " })
			table.insert(elements, { Text = "|" })
			return
		end
	end
end

---Adds current process name to status elements
---@param elements table
---@param pane Pane
local function add_process_name(elements, pane)
	local process = util.basename(pane:get_foreground_process_name())
	if process then
		table.insert(elements, { Foreground = { Color = colors.yellow_alt } })
		table.insert(elements, { Background = { Color = colors.background } })
		table.insert(elements, { Text = " " .. icons.code .. " " .. process .. " " })
	end
end

---Loads the status bar configuration
---@param config table
function M.load(config)
	M.config = config

	Wezterm.on("update-right-status", function(window, pane)
		local elements = {}
		local active_key_table = window:active_key_table()

		-- Store globally so format-tab-title can access it
		Wezterm.GLOBAL.active_key_table = active_key_table

		if active_key_table then
			-- When key table active, put hints in left status (full width)
			local left_elements = {}
			add_keytable_name(left_elements, active_key_table)
			add_keytable_hints(left_elements, active_key_table, M.config)
			window:set_left_status(Wezterm.format(left_elements))
			window:set_right_status("")
		else
			window:set_left_status("")
			add_claude_indicator(elements, pane)
			add_focus_zoom_indicator(elements)
			add_process_name(elements, pane)
			add_git_info(elements, pane)
			add_workspace(elements, Wezterm.mux.get_active_workspace())
			window:set_right_status(Wezterm.format(elements))
		end
	end)
end

return M
