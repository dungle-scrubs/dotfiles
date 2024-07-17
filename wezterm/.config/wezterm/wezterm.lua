term = " wezterm"
-- https://hackernoon.com/get-the-most-out-of-your-terminal-a-comprehensive-guide-to-wezterm-configuration
-- that's a good setup guide

-- Pull in the wezterm API
local wezterm = require("wezterm")
local act = wezterm.action

-- This will hold the configuration.
local config = wezterm.config_builder()
-- config.font = wezterm.font("JetBrains Mono", { weight = "Bold", italic = true })
-- config.term = "wezterm"
config.font_size = 16
config.bold_brightens_ansi_colors = true
config.line_height = 1.2
config.adjust_window_size_when_changing_font_size = false
config.hide_tab_bar_if_only_one_tab = true
config.use_dead_keys = false
config.scrollback_lines = 5000
config.window_frame = {
	font = wezterm.font({ family = "Noto Sans", weight = "Regular" }),
}
config.disable_default_key_bindings = true
config.window_decorations = "RESIZE"
config.keys = {
	{ key = "c", mods = "CMD", action = act.CopyTo("Clipboard") },
	{ key = "v", mods = "CMD", action = act.PasteFrom("Clipboard") },
}

-- Enable ANSI color support
config.enable_kitty_graphics = true

config.set_environment_variables = {
	TERM = "xterm-256color",
}
-- and finally, return the configuration to wezterm
return config
