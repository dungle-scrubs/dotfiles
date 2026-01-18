local paths = require("configs.paths")
local act = Wezterm.action
local io = require("io")
local os = require("os")

---Opens the current pane's scrollback in neovim
Wezterm.on("trigger-nvim-with-scrollback", function(window, pane)
	local text = pane:get_lines_as_text(pane:get_dimensions().scrollback_rows)

	local name = os.tmpname()
	local f = io.open(name, "w+")
	if not f then
		Wezterm.log_error("trigger-nvim-with-scrollback: failed to create temp file")
		return
	end

	f:write(text)
	f:flush()
	f:close()

	window:perform_action(
		act.SpawnCommandInNewTab({
			args = { paths.nvim, name },
		}),
		pane
	)

	Wezterm.time.call_after(1, function()
		os.remove(name)
	end)
end)
