local paths = require("configs.paths")
local M = {}

local home = Wezterm.home_dir
local env_paths = paths.env_paths()
Wezterm.log_info(env_paths)

local function edit_config(dir)
	return {
		label = "edit" .. " " .. dir,
		cwd = home .. "/.config/" .. dir,
		set_environment_variables = {
			PATH = env_paths,
		},
		args = { "zsh", "-c", "-l", 'FILE=$(fd -t f | fzf); if [ -n "$FILE" ]; then nvim "$FILE"; fi' },
	}
end

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
		-- edit_config("aerc"),
		-- {
		-- 	label = "log",
		-- 	cwd = tjex_site .. "/src/content",
		-- 	set_environment_variables = {
		-- 		PATH = env_paths,
		-- 	},
		-- 	args = { "zsh", "-c", "-l", "zk log" },
		-- },
		-- {
		-- 	label = "navi",
		-- 	cwd = home .. "/.local/share/navi",
		-- 	set_environment_variables = {
		-- 		PATH = env_paths,
		-- 	},
		-- 	-- for some reason, this folder needs to be explicityly cd'd into?
		-- 	args = { "zsh", "-c", "cd" .. home .. "/.local/share/navi && nvim $(fd -t f | fzf)" },
		-- },
	}
end
return M
