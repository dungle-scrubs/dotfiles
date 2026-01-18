local M = {}

---Walks panes on the same axis as the active pane, optionally applying a function
---@param axis "x"|"y"
---@param tab MuxTab
---@param window Window
---@param pane Pane
---@param do_func? fun(pane: Pane): any
---@return any[]
local function walk_siblings(axis, tab, window, pane, do_func)
	local initial_pane = pane
	local siblings = { do_func and do_func(initial_pane) or initial_pane }
	local prev_dir = axis == "x" and "Left" or "Up"
	local next_dir = axis == "x" and "Right" or "Down"
	local max_iter = 8

	local initial_pane_idx = 1
	local panes_info = tab:panes_with_info()
	for _, pi in ipairs(panes_info) do
		if pi.is_active then
			initial_pane_idx = pi.index
		end
	end

	for _, step_dir in ipairs({ "prev", "next" }) do
		local last_pane = tab:active_pane()
		window:perform_action(
			Wezterm.action.ActivatePaneDirection(step_dir == "prev" and prev_dir or next_dir),
			tab:active_pane()
		)
		local new_pane = tab:active_pane()

		local i = 0
		while new_pane:pane_id() ~= last_pane:pane_id() and i < max_iter do
			if step_dir == "prev" then
				table.insert(siblings, 1, do_func and do_func(new_pane) or new_pane)
			else
				table.insert(siblings, do_func and do_func(new_pane) or new_pane)
			end
			last_pane = tab:active_pane()
			window:perform_action(
				Wezterm.action.ActivatePaneDirection(step_dir == "prev" and prev_dir or next_dir),
				tab:active_pane()
			)
			new_pane = tab:active_pane()
			i = i + 1
		end

		window:perform_action(Wezterm.action.ActivatePaneByIndex(initial_pane_idx), tab:active_pane())
	end

	return siblings
end

---Returns a callback that balances panes on the given axis
---@param axis "x"|"y"
---@return fun(window: Window, pane: Pane)
function M.balance_panes(axis)
	return function(window, pane)
		local tab = window:active_tab()
		local prev_dir = axis == "x" and "Left" or "Up"
		local next_dir = axis == "x" and "Right" or "Down"
		local siblings = walk_siblings(axis, tab, window, pane)
		local tab_size = tab:get_size()[axis == "x" and "cols" or "rows"]
		local balanced_size = math.floor(tab_size / #siblings)
		local pane_size_key = axis == "x" and "cols" or "viewport_rows"

		walk_siblings(axis, tab, window, pane, function(p)
			local pane_size = p:get_dimensions()[pane_size_key]
			local adj_amount = pane_size - balanced_size
			local adj_dir = adj_amount < 0 and next_dir or prev_dir
			adj_amount = math.abs(adj_amount)
			window:perform_action(Wezterm.action.AdjustPaneSize({ adj_dir, adj_amount }), p)
		end)
	end
end

Wezterm.on("augment-command-palette", function()
	return {
		{
			brief = "Balance panes horizontally",
			action = Wezterm.action_callback(M.balance_panes("x")),
		},
		{
			brief = "Balance panes vertically",
			action = Wezterm.action_callback(M.balance_panes("y")),
		},
	}
end)

return M
