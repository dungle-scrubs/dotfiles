---@type Wezterm
Wezterm = require("wezterm")

local design = require("configs.design")
local keybinds = require("configs.keybinds")
local launch_menu = require("configs.launch_menu")
local startup = require("configs.gui_startup")
local status = require("configs.status")

local config = Wezterm.config_builder()

config.set_environment_variables = {
	-- prepend the path to your utility and include the rest of the PATH
	PATH = Wezterm.home_dir .. "/.local/bin:" .. os.getenv("PATH"),
}

config.unix_domains = {
	{
		name = "unix",
	},
}

-- disables mac unicode symbol input via ALT/META
config.send_composed_key_when_left_alt_is_pressed = true
config.send_composed_key_when_right_alt_is_pressed = true

config.max_fps = 120
config.prefer_egl = true
config.front_end = "WebGpu"
config.audible_bell = "Disabled"
config.default_workspace = "admin"
config.automatically_reload_config = false
config.status_update_interval = 200

config.window_close_confirmation = "NeverPrompt"

design.apply(config)
keybinds.apply(config)
launch_menu.apply(config)

status.load(config)
startup.start()

return config
