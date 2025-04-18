local mux = Wezterm.mux
local home = Wezterm.home_dir
local M = {}

local function admin()
	local admin_tab = mux.spawn_window({
		workspace = "admin",
		cwd = home .. "/docs/",
	})

	admin_tab:set_title("admin")
end

local function sys()
	local sys_tab = mux.spawn_window({
		workspace = "config",
		cwd = home .. "/.config",
	})
	sys_tab:set_title("config")
end

function M.start()
	Wezterm.on("gui-startup", function()
		-- admin()
		-- sys()
	end)
end

return M
