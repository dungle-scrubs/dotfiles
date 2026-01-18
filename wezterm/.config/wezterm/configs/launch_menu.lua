local paths = require("configs.paths")

local M = {}

local home = Wezterm.home_dir
local env_paths = paths.env_paths()

---Creates a launch menu entry to edit config in a directory
---@param dir string
---@return table
local function edit_config(dir)
	return {
		label = "edit " .. dir,
		cwd = home .. "/.config/" .. dir,
		set_environment_variables = {
			PATH = env_paths,
		},
		args = { "zsh", "-c", "-l", 'FILE=$(fd -t f | fzf); if [ -n "$FILE" ]; then nvim "$FILE"; fi' },
	}
end

---Applies launch menu configuration
---@param config table
function M.apply(config)
	config.launch_menu = {
		edit_config("wezterm"),
		edit_config("nvim"),
		{
			label = "dotfiles",
			cwd = home .. "/.config",
			set_environment_variables = {
				PATH = env_paths,
			},
			args = { "zsh", "-c", "-l", 'FILE=$(fd -t f | fzf); if [ -n "$FILE" ]; then nvim "$FILE"; fi' },
		},
	}
end

return M
