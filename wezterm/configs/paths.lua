local M = {}

local paths = {
	"/bin:",
	"/usr/bin:",
	"/usr/local/bin:",
	"/opt/homebrew/bin:",
}

local paths_string = table.concat(paths)

function M.env_paths()
	return paths_string
end

return M
