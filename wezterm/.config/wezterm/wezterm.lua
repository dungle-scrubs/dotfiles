---@type Wezterm
Wezterm = require("wezterm")

local design = require("configs.design")
local keybinds = require("configs.keybinds")
local launch_menu = require("configs.launch_menu")
local status = require("configs.status")
local focus_zoom = require("functions.focus_zoom")
focus_zoom.init()

local resurrect = Wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")
resurrect.state_manager.periodic_save()
Wezterm.on("gui-startup", resurrect.state_manager.resurrect_on_gui_startup)

local config = Wezterm.config_builder()

config.set_environment_variables = {
	PATH = Wezterm.home_dir .. "/.local/bin:" .. os.getenv("PATH"),
}

config.unix_domains = {
	{
		name = "unix",
	},
}

config.send_composed_key_when_left_alt_is_pressed = true
config.send_composed_key_when_right_alt_is_pressed = true

config.max_fps = 120
config.prefer_egl = true
config.front_end = "WebGpu"
config.audible_bell = "Disabled"
config.detect_password_input = true
config.default_workspace = "admin"
config.automatically_reload_config = false
config.status_update_interval = 200

config.window_close_confirmation = "NeverPrompt"

design.apply(config)
keybinds.apply(config)
launch_menu.apply(config)
status.load(config)

return config
