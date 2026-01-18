local balance = require("functions.balance")
local projects = require("functions.projects")
local workspace = require("functions.workspace")
local focus_zoom = require("functions.focus_zoom")
local paths = require("configs.paths")
local act = Wezterm.action

local M = {}

require("configs.events")

function M.apply(config)
	config.leader = {
		mods = "ALT",
		key = "Space",
	}

	config.keys = {
		-- TIER 1: Direct keys (no leader)
		-- Shift+Enter for newlines (useful for Claude Code multi-line input)
		{ key = "Enter", mods = "SHIFT", action = act.SendString("\n") },

		-- Pane navigation (Alt+hjkl)
		{
			key = "h",
			mods = "ALT",
			action = Wezterm.action_callback(focus_zoom.navigate_with_zoom("Left", "x")),
		},
		{
			key = "j",
			mods = "ALT",
			action = Wezterm.action_callback(focus_zoom.navigate_with_zoom("Down", "y")),
		},
		{
			key = "k",
			mods = "ALT",
			action = Wezterm.action_callback(focus_zoom.navigate_with_zoom("Up", "y")),
		},
		{
			key = "l",
			mods = "ALT",
			action = Wezterm.action_callback(focus_zoom.navigate_with_zoom("Right", "x")),
		},

		-- Tab navigation (Ctrl+Alt+h/l)
		{ key = "h", mods = "CTRL|ALT", action = act.ActivateTabRelative(-1) },
		{ key = "l", mods = "CTRL|ALT", action = act.ActivateTabRelative(1) },

		-- Workspace navigation (Ctrl+Alt+Shift+h/l)
		{
			key = "h",
			mods = "CTRL|ALT|SHIFT",
			action = Wezterm.action_callback(function(window, pane)
				local workspaces = Wezterm.mux.get_workspace_names()
				table.sort(workspaces)
				local current = window:active_workspace()
				for i, ws in ipairs(workspaces) do
					if ws == current then
						local prev_idx = i > 1 and i - 1 or #workspaces
						workspace.switch(window, pane, workspaces[prev_idx])
						return
					end
				end
			end),
		},
		{
			key = "l",
			mods = "CTRL|ALT|SHIFT",
			action = Wezterm.action_callback(function(window, pane)
				local workspaces = Wezterm.mux.get_workspace_names()
				table.sort(workspaces)
				local current = window:active_workspace()
				for i, ws in ipairs(workspaces) do
					if ws == current then
						local next_idx = i < #workspaces and i + 1 or 1
						workspace.switch(window, pane, workspaces[next_idx])
						return
					end
				end
			end),
		},

		-- Debug overlay
		{ key = "L", mods = "CTRL", action = Wezterm.action.ShowDebugOverlay },

		-- TIER 2: Leader + single key
		-- o = open project picker (workspace)
		{
			key = "o",
			mods = "LEADER",
			action = Wezterm.action_callback(projects.open_workspace),
		},
		-- p = pane key table
		{
			key = "p",
			mods = "LEADER",
			action = act.ActivateKeyTable({
				name = "pane",
				one_shot = true,
			}),
		},
		-- t = tab key table
		{
			key = "t",
			mods = "LEADER",
			action = act.ActivateKeyTable({
				name = "tab",
				one_shot = true,
			}),
		},
		-- w = workspace key table
		{
			key = "w",
			mods = "LEADER",
			action = act.ActivateKeyTable({
				name = "workspace",
				one_shot = true,
			}),
		},
		-- y = yank (copy mode)
		{
			key = "y",
			mods = "LEADER",
			action = act.ActivateCopyMode,
		},
		-- s = scrollback to nvim
		{
			key = "s",
			mods = "LEADER",
			action = act.EmitEvent("trigger-nvim-with-scrollback"),
		},
		-- q = quickselect
		{
			key = "q",
			mods = "LEADER",
			action = act.QuickSelectArgs({
				patterns = {
					"https?://\\S+", -- URLs
					"[a-f0-9]{7,40}", -- git hashes (7-40 hex chars)
					"(?:/[\\w.-]+)+", -- file paths
					"\\b[\\w.+-]+@[\\w.-]+\\.[a-z]{2,}\\b", -- emails
					"\\b(?:sha256-)?[A-Za-z0-9+/=]{40,}\\b", -- SRI hashes, base64 tokens
				},
			}),
		},
		-- u = unicode/emoji picker
		{
			key = "u",
			mods = "LEADER",
			action = act.CharSelect({
				copy_on_select = true,
				copy_to = "ClipboardAndPrimarySelection",
			}),
		},
		-- b = balance panes
		{
			key = "b",
			mods = "LEADER",
			action = act.Multiple({
				Wezterm.action_callback(balance.balance_panes("x")),
			}),
		},
		-- z = zoom (focus zoom toggle)
		{
			key = "z",
			mods = "LEADER",
			action = Wezterm.action_callback(focus_zoom.toggle()),
		},
		-- r = rotate panes
		{
			key = "r",
			mods = "LEADER",
			action = act.RotatePanes("Clockwise"),
		},
		-- k = keys (command palette)
		{
			key = "k",
			mods = "LEADER",
			action = act.ActivateCommandPalette,
		},
		-- l = launch menu
		{
			key = "l",
			mods = "LEADER",
			action = act.ShowLauncherArgs({ flags = "FUZZY|LAUNCH_MENU_ITEMS" }),
		},
	}

	-- TIER 3: Key tables
	config.key_tables = {
		pane = {
			{ key = "d", desc = "Close", action = act.CloseCurrentPane({ confirm = false }) },
			{ key = "s", desc = "Split horiz", action = act.SplitPane({ direction = "Down", size = { Percent = 33 } }) },
			{ key = "v", desc = "Split vert", action = act.SplitPane({ direction = "Right", size = { Percent = 33 } }) },
			{
				key = "z",
				desc = "Resize",
				action = act.ActivateKeyTable({
					name = "pane_resize",
					one_shot = false,
				}),
			},
			{ key = "S", desc = "Swap", action = act.PaneSelect({ mode = "Activate" }) },
			{ key = "t", desc = "Break to tab", action = act.PaneSelect({ mode = "MoveToNewTab" }) },
			{ key = "Escape", action = "PopKeyTable" },
		},
		pane_resize = {
			{ key = "h", desc = "Left", action = act.AdjustPaneSize({ "Left", 2 }) },
			{ key = "l", desc = "Right", action = act.AdjustPaneSize({ "Right", 2 }) },
			{ key = "k", desc = "Up", action = act.AdjustPaneSize({ "Up", 2 }) },
			{ key = "j", desc = "Down", action = act.AdjustPaneSize({ "Down", 2 }) },
			{ key = "Escape", action = "PopKeyTable" },
		},
		tab = {
			{ key = "d", desc = "Close", action = Wezterm.action.CloseCurrentTab({ confirm = true }) },
			{ key = "h", desc = "Move left", action = act.MoveTabRelative(-1) },
			{ key = "l", desc = "Move right", action = act.MoveTabRelative(1) },
			{ key = "n", desc = "New", action = act.SpawnTab("CurrentPaneDomain") },
			{
				key = "N",
				desc = "New w/ name",
				action = Wezterm.action_callback(function(window, pane)
					window:perform_action(
						act.PromptInputLine({
							description = "New tab name (optional, press Enter to skip):",
							action = Wezterm.action_callback(function(inner_window, inner_pane, line)
								local project_name = line or ""
								inner_window:perform_action(
									act.SpawnCommandInNewTab({
										domain = "CurrentPaneDomain",
										args = {
											paths.scripts .. "/set_tab_name.sh",
											project_name,
										},
									}),
									inner_pane
								)
							end),
						}),
						pane
					)
				end),
			},
			{
				key = "r",
				desc = "Rename",
				action = act.PromptInputLine({
					description = "Enter new name for tab",
					action = Wezterm.action_callback(function(window, _, line)
						if line then
							window:active_tab():set_title(line)
						end
					end),
				}),
			},
			{ key = "c", desc = "Clone", action = Wezterm.action_callback(workspace.duplicate) },
			{ key = "p", desc = "Project", action = Wezterm.action_callback(projects.open_tab) },
			{ key = "Escape", action = "PopKeyTable" },
		},
		workspace = {
			{ key = "w", desc = "Workspaces", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
			{
				key = "o",
				desc = "Previous",
				action = Wezterm.action_callback(function(window, pane)
					workspace.switch_to_previous(window, pane)
				end),
			},
			{
				key = "d",
				desc = "Delete",
				action = Wezterm.action_callback(function(window, pane)
					local ws = window:active_workspace()
					workspace.kill(window, pane, ws)
				end),
			},
			{ key = "n", desc = "New", action = Wezterm.action_callback(projects.open_workspace) },
			{
				key = "r",
				desc = "Rename",
				action = act.PromptInputLine({
					description = "Enter new workspace name:",
					action = Wezterm.action_callback(function(_, _, line)
						if line then
							Wezterm.mux.rename_workspace(Wezterm.mux.get_active_workspace(), line)
						end
					end),
				}),
			},
			{ key = "Escape", action = "PopKeyTable" },
		},
	}
end

return M
