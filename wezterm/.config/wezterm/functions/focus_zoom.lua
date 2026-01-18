local M = {}

---Initializes focus zoom state if not set
function M.init()
	if Wezterm.GLOBAL.focus_zoom_enabled == nil then
		Wezterm.GLOBAL.focus_zoom_enabled = false
	end
end

---Checks if focus zoom mode is enabled
---@return boolean
function M.is_enabled()
	return Wezterm.GLOBAL.focus_zoom_enabled == true
end

---Returns a callback that toggles focus zoom mode
---@return fun(window: Window, pane: Pane)
function M.toggle()
	return function(window, _)
		Wezterm.GLOBAL.focus_zoom_enabled = not M.is_enabled()
	end
end

---Resizes a pane to a target percentage of the tab on the given axis
---@param window Window
---@param pane Pane
---@param axis "x"|"y"
---@param percentage number
local function resize_to_percentage(window, pane, axis, percentage)
	local tab = window:active_tab()
	local tab_size = tab:get_size()

	local size_key = axis == "x" and "cols" or "rows"
	local pane_size_key = axis == "x" and "cols" or "viewport_rows"

	local total_size = tab_size[size_key]
	local target_size = math.floor(total_size * percentage)
	local current_size = pane:get_dimensions()[pane_size_key]

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

---Returns a callback that navigates and optionally zooms the target pane
---@param direction "Left"|"Right"|"Up"|"Down"
---@param axis "x"|"y"
---@return fun(window: Window, pane: Pane)
function M.navigate_with_zoom(direction, axis)
	return function(window, pane)
		local tab = window:active_tab()
		local panes = tab:panes()

		if #panes <= 1 then
			window:perform_action(Wezterm.action.ActivatePaneDirection(direction), pane)
			return
		end

		local original_pane_id = pane:pane_id()

		window:perform_action(Wezterm.action.ActivatePaneDirection(direction), pane)

		if not M.is_enabled() then
			return
		end

		local new_pane = tab:active_pane()

		if new_pane:pane_id() == original_pane_id then
			return
		end

		resize_to_percentage(window, new_pane, axis, 0.8)
	end
end

return M
