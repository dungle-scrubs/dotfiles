---@diagnostic disable: unused-local
local b = require("functions.balance")
local func = require("functions/funcs")
local sessioniser = require("functions.sessioniser")
local focus_zoom = require("functions.focus_zoom")
local paths = require("configs.paths")
local act = Wezterm.action

-- local env_paths = paths.env_paths()

local M = {}

-- custom events
require("configs.events")

function M.apply(config)
	config.leader = {
		mods = "ALT",
		key = "Space",
		-- timeout_milliseconds = 800
	}

	-- LEADER KEYBINDS
	config.keys = {
		-- Shift+Enter for newlines (useful for Claude Code multi-line input)
		{ key = "Enter", mods = "SHIFT", action = act.SendString("\n") },

		{ key = "k", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|KEY_ASSIGNMENTS" }) },
		{
			key = "b",
			mods = "LEADER",
			action = act.Multiple({
				Wezterm.action_callback(b.balance_panes("x")),
			}),
		},
		{
			key = "y",
			mods = "LEADER",
			action = act.ActivateCopyMode,
		},
		{
			key = "s",
			mods = "LEADER",
			action = act.EmitEvent("trigger-nvim-with-scrollback"),
		},

		-- KEY TABLES
		{
			key = "p",
			mods = "LEADER",
			action = act.ActivateKeyTable({
				name = "pane",
				one_shot = true,
			}),
			-- action = Wezterm.action.QuickSelectArgs({
			-- 	alphabet = "abc",
			-- }),
			-- action = act.EmitEvent("user-activate-pane-table", "pane", false),
			-- action = act.ActivateKeyTable({
			-- 	name = "pane",
			-- 	one_shot = false,
			-- }),
		},
		{
			key = "t",
			mods = "LEADER",
			action = act.ActivateKeyTable({
				name = "tab",
				one_shot = true,
			}),
		},
		{
			key = "w",
			mods = "LEADER",
			action = act.ActivateKeyTable({
				name = "workspace",
				one_shot = true,
			}),
		},
		{
			key = "f",
			mods = "LEADER",
			action = act.ActivateKeyTable({
				name = "framework",
				desc = "create framework",
				one_shot = true,
			}),
		},

		-- "SUPER" (cmd on mac). Mainly for launching and 'generic' operations.
		-- WINDOWS / TABS / PANES
		{
			key = "w",
			mods = "SUPER",
			action = Wezterm.action.CloseCurrentTab({ confirm = true }),
		},

		-- LAUNCHERS
		{
			key = "o",
			mods = "SUPER",
			action = Wezterm.action_callback(sessioniser.open),
		},
		{
			key = "e",
			mods = "SUPER",
			action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }),
		},
		{
			key = "p",
			mods = "SUPER",
			action = act.ShowLauncherArgs({ flags = "FUZZY|LAUNCH_MENU_ITEMS" }),
		},
		{
			key = "k",
			mods = "SUPER",
			action = act.ActivateCommandPalette,
		},

		-- TABS
		{ key = "h", mods = "CTRL|ALT", action = act.ActivateTabRelative(-1) },
		{ key = "l", mods = "CTRL|ALT", action = act.ActivateTabRelative(1) },

		-- PANES (with optional focus-zoom via Alt+z toggle)
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
		{
			key = "r",
			mods = "ALT",
			action = act.RotatePanes("Clockwise"),
		},
		{
			key = "z",
			mods = "ALT",
			action = Wezterm.action_callback(focus_zoom.toggle()),
		},

		-- PASS THROUGH TO TERMINAL
		{
			key = "o",
			mods = "LEADER|CTRL",
			action = act.SendKey({ key = "o", mods = "ALT" }),
		},

		-- COMBO
		-- i.e, (ctrl + shift + l)
		{ key = "L", mods = "CTRL", action = Wezterm.action.ShowDebugOverlay },
	}

	-- KEYTABLES
	config.key_tables = {
		pane = {
			{
				key = "d",
				desc = "Close",
				action = act.CloseCurrentPane({ confirm = false }),
			},
			{
				key = "s",
				desc = "Split horiz",
				action = act.SplitPane({ direction = "Down", size = { Percent = 33 } }),
			},
			{
				key = "v",
				desc = "Split vert",
				action = act.SplitPane({ direction = "Right", size = { Percent = 33 } }),
			},
			{
				key = "z",
				desc = "Resize",
				action = act.ActivateKeyTable({
					name = "pane_resize",
					one_shot = false,
				}),
			},
			{
				key = "S",
				desc = "Swap",
				action = act.PaneSelect({ mode = "Activate" }),
			},
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
			{ key = "t", desc = "Tabs", action = act.ShowLauncherArgs({ flags = "FUZZY|TABS" }) },
			{ key = "d", desc = "Close", action = Wezterm.action.CloseCurrentTab({ confirm = true }) },
			{ key = "h", desc = "Move left", action = act.MoveTabRelative(-1) },
			{ key = "l", desc = "Move right", action = act.MoveTabRelative(1) },
			{
				key = "n",
				desc = "New",
				action = act.SpawnTab("CurrentPaneDomain"),
			},
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
											"/Users/kevin/.config/wezterm/scripts/set_tab_name.sh",
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
					action = Wezterm.action_callback(function(window, pane, line)
						-- line will be `nil` if they hit escape without entering anything
						-- An empty string if they just hit enter
						-- Or the actual line of text they wrote
						if line then
							window:active_tab():set_title(line)
						end
					end),
				}),
			},
			{ key = "Escape", action = "PopKeyTable" },
		},
		workspace = {
			{ key = "w", desc = "Workspaces", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
			{
				key = "o",
				desc = "previous",
				action = Wezterm.action_callback(function(window, pane)
					func.switch_to_previous_workspace(window, pane)
				end),
			},
			{
				key = "d",
				desc = "delete",
				action = Wezterm.action_callback(function(window, pane)
					local workspace = window:active_workspace()
					func.kill_workspace(window, pane, workspace)
				end),
			},
			-- Prompt for a name to use for a new workspace and switch to it.
			{
				key = "n",
				desc = "new",
				action = act.PromptInputLine({
					description = Wezterm.format({
						{ Attribute = { Intensity = "Bold" } },
						{ Text = "Enter name for new workspace" },
					}),
					action = Wezterm.action_callback(function(window, pane, input)
						-- line will be `nil` if they hit escape without entering anything
						-- An empty string if they just hit enter
						-- Or the actual line of text they wrote
						if input then
							func.new_scratch_workspace(window, pane, input)
						end
					end),
				}),
			},
			{
				key = "r",
				desc = "rename",
				action = act.PromptInputLine({
					description = "Enter new workspace name:",
					action = Wezterm.action_callback(function(window, pane, line)
						if line then
							Wezterm.mux.rename_workspace(Wezterm.mux.get_active_workspace(), line)
						end
					end),
				}),
			},
			{ key = "Escape", action = "PopKeyTable" },
		},
		framework = {
			{
				key = "a",
				desc = "Astro",
				action = Wezterm.action_callback(function(window, pane)
					-- Prompt the user for a project name (optional)
					window:perform_action(
						act.PromptInputLine({
							description = "Project name (optional, press Enter to skip):",
							action = Wezterm.action_callback(function(inner_window, inner_pane, line)
								local project_name = line
								if #line == 0 then
									project_name = ("scratch-" .. os.date("%Y%m%d-%H%M%S"))
								end

								-- Use the prompted input or create a "scratch-<timestamp>" name
								inner_window:perform_action(
									act.SwitchToWorkspace({
										name = project_name,
										spawn = {
											args = {
												"/Users/kevin/.config/wezterm/scripts/create_astro.sh",
												project_name,
											},
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
				key = "n",
				desc = "Next.js",
				action = Wezterm.action_callback(function(window, pane)
					-- Prompt the user for a project name (optional)
					window:perform_action(
						act.PromptInputLine({
							description = "Project name (optional, press Enter to skip):",
							action = Wezterm.action_callback(function(inner_window, inner_pane, line)
								local project_name = line
								if #line == 0 then
									project_name = ("scratch-" .. os.date("%Y%m%d-%H%M%S"))
								end

								-- Use the prompted input or create a "scratch-<timestamp>" name
								inner_window:perform_action(
									act.SwitchToWorkspace({
										name = project_name,
										spawn = {
											args = {
												"/Users/kevin/.config/wezterm/scripts/create_next.sh",
												project_name,
											},
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
			{ key = "Escape", action = "PopKeyTable" },
		},
	}
end

return M
