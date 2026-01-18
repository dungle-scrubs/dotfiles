---@class Paths
---@field fd string Path to fd binary
---@field wezterm string Path to wezterm binary
---@field nvim string Path to neovim binary
---@field dev string Path to dev directory
---@field scripts string Path to wezterm scripts directory
---@field env_paths fun(): string Returns PATH string for shell environments

local M = {}

local home = Wezterm.home_dir

--- Binary paths
M.fd = "/opt/homebrew/bin/fd"
M.wezterm = "/opt/homebrew/bin/wezterm"
M.nvim = "/opt/homebrew/bin/nvim"

--- Directory paths
M.dev = home .. "/dev"
M.scripts = home .. "/.config/wezterm/scripts"

--- Standard PATH directories
local path_dirs = {
	"/bin",
	"/usr/bin",
	"/usr/local/bin",
	"/opt/homebrew/bin",
}

---Returns concatenated PATH string for shell environments
---@return string
function M.env_paths()
	return table.concat(path_dirs, ":")
end

return M
