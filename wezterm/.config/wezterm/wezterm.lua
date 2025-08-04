---@type Wezterm
Wezterm = require("wezterm")

local design = require("configs.design")
local keybinds = require("configs.keybinds")
local launch_menu = require("configs.launch_menu")
local startup = require("configs.gui_startup")
local status = require("configs.status")

local config = Wezterm.config_builder()

config = {
	set_environment_variables = {
		-- prepend the path to your utility and include the rest of the PATH
		PATH = Wezterm.home_dir .. os.getenv("PATH"),
	},

	unix_domains = {
		{
			name = "unix",
		},
	},

	-- disables mac unicode symbol input via ALT/META
	send_composed_key_when_left_alt_is_pressed = true,
	send_composed_key_when_right_alt_is_pressed = true,

	max_fps = 120,
	prefer_egl = true,
	front_end = "WebGpu",
	audible_bell = "Disabled",
	default_workspace = "admin",
	automatically_reload_config = false,
	status_update_interval = 200,

	skip_close_confirmation_for_processes_named = {
		"bash",
		"sh",
		"zsh",
	},
}

design.apply(config)
keybinds.apply(config)
launch_menu.apply(config)

status.load(config)
startup.start()

return config
