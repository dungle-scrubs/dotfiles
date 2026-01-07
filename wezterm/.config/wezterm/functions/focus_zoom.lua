-- Focus Zoom: Toggle mode where pane navigation auto-resizes to 80%
local M = {}

-- Initialize state if not set
function M.init()
	if Wezterm.GLOBAL.focus_zoom_enabled == nil then
		Wezterm.GLOBAL.focus_zoom_enabled = false
	end
end

-- Check if focus zoom is enabled
function M.is_enabled()
	return Wezterm.GLOBAL.focus_zoom_enabled == true
end

-- Toggle focus zoom mode
function M.toggle()
	return function(window, _)
		Wezterm.GLOBAL.focus_zoom_enabled = not M.is_enabled()
	end
end

-- Resize pane to target percentage of tab on given axis
local function resize_to_percentage(window, pane, axis, percentage)
	local tab = window:active_tab()
	local tab_size = tab:get_size()

	local size_key = axis == "x" and "cols" or "rows"
	local pane_size_key = axis == "x" and "cols" or "viewport_rows"

	local total_size = tab_size[size_key]
	local target_size = math.floor(total_size * percentage)
	local current_size = pane:get_dimensions()[pane_size_key]

	-- Skip if already within 5% of target
	local threshold = math.floor(total_size * 0.05)
	if math.abs(current_size - target_size) <= threshold then
		return
	end

	local diff = target_size - current_size
	local direction

	if axis == "x" then
		direction = diff > 0 and "Right" or "Left"
	else
		direction = diff > 0 and "Down" or "Up"
	end

	window:perform_action(Wezterm.action.AdjustPaneSize({ direction, math.abs(diff) }), pane)
end

-- Navigate and optionally zoom
-- direction: "Left", "Right", "Up", "Down"
-- axis: "x" for Left/Right, "y" for Up/Down
function M.navigate_with_zoom(direction, axis)
	return function(window, pane)
		local tab = window:active_tab()
		local panes = tab:panes()

		-- If only one pane, just navigate (does nothing but keeps consistency)
		if #panes <= 1 then
			window:perform_action(Wezterm.action.ActivatePaneDirection(direction), pane)
			return
		end

		local original_pane_id = pane:pane_id()

		-- Navigate first
		window:perform_action(Wezterm.action.ActivatePaneDirection(direction), pane)

		-- If focus zoom not enabled, we're done
		if not M.is_enabled() then
			return
		end

		-- Get the new active pane after navigation
		local new_pane = tab:active_pane()

		-- If navigation didn't change panes, skip resize
		if new_pane:pane_id() == original_pane_id then
			return
		end

		-- Resize the new pane to ~80%
		resize_to_percentage(window, new_pane, axis, 0.8)
	end
end

return M
