local utils = require("configs.util")
local mux = Wezterm.mux
local M = {}

local icons = {
	["pane"] = Wezterm.nerdfonts.cod_layout,
	["tab"] = Wezterm.nerdfonts.md_tab,
	["workspace"] = Wezterm.nerdfonts.cod_multiple_windows,
}

-- The following is related to tracking the nested state of key tables
--
-- At the top level of your module
M.key_table_stack = {} -- Track the hierarchy of key tables
-- Function to push a key table onto the stack
function M.push_key_table(name)
	table.insert(M.key_table_stack, name)
end
-- Function to pop a key table from the stack
function M.pop_key_table()
	if #M.key_table_stack > 0 then
		return table.remove(M.key_table_stack)
	end
	return nil
end
-- Function to get the current key table path
function M.get_key_table_path()
	return M.key_table_stack
end

function M.load(config)
	M.config = config
	-- doc: https://wezfurlong.org/wezterm/config/lua/window/set_right_status.html
	Wezterm.on("update-right-status", function(window, pane)
		local elements = {}
		local bg = "#1a1c23"
		local yellow = "#d8a274"
		local workspace = mux.get_active_workspace()

		local function getActiveKeytableKeys()
			local name = window:active_key_table()
			if name then
				-- Add key bindings with colors
				local key_elements = M.get_key_bindings(name)
				if key_elements then
					-- Add all the pre-formatted elements directly
					for _, element in ipairs(key_elements) do
						table.insert(elements, element)
					end
				end
			end
		end

		local function getActiveKeytable()
			local name = window:active_key_table()
			if name then
				if icons[name] then
					table.insert(elements, { Foreground = { Color = yellow } })
					table.insert(elements, { Background = { Color = bg } })
					table.insert(elements, { Text = " " .. icons[name] .. " " })
				end
				-- Add the key table name
				table.insert(elements, { Foreground = { Color = yellow } })
				table.insert(elements, { Background = { Color = bg } })
				table.insert(elements, { Text = " " .. name .. " " })

				table.insert(elements, { Text = "|" })
			end
		end

		local function getWorkspace()
			if workspace then
				table.insert(elements, "ResetAttributes")
				table.insert(elements, { Text = "  " .. workspace .. "  " })
			end
		end

		local function getProcessName()
			local process = utils.basename(pane:get_foreground_process_name())
			if process then
				table.insert(elements, { Foreground = { Color = yellow } })
				table.insert(elements, { Background = { Color = bg } })
				table.insert(elements, { Text = " " .. Wezterm.nerdfonts.fa_code .. " " .. process .. " " })
			end
		end

		getActiveKeytableKeys()
		getActiveKeytable()
		getProcessName()
		getWorkspace()

		window:set_right_status(Wezterm.format(elements))
	end)
end

-- Inspired by vim's which-key
function M.get_key_bindings(key_table_name)
	-- Confirm access to config
	if not M.config or not M.config.key_tables or not M.config.key_tables[key_table_name] then
		return nil
	end

	local key_table = M.config.key_tables[key_table_name]
	local formatted_elements = {}

	local key_color = "#6cb6ff"
	local text_color = "#808080"

	local need_comma = false

	-- Iterate through all key bindings in the table
	for _, binding in ipairs(key_table) do
		if binding.key then
			-- Skip if the key is "escape" (case insensitive)
			local key_lower = string.lower(binding.key)
			if key_lower ~= "escape" then
				if need_comma then
					table.insert(formatted_elements, { Foreground = { Color = text_color } })
					table.insert(formatted_elements, { Text = ", " })
				end

				local key_name = binding.key
				local description = binding.desc or key_name

				-- Add key
				table.insert(formatted_elements, { Foreground = { Color = key_color } })
				table.insert(formatted_elements, { Text = key_name })

				-- Add arrow splitter
				table.insert(formatted_elements, { Foreground = { Color = text_color } })
				table.insert(formatted_elements, { Text = " " .. Wezterm.nerdfonts.cod_arrow_small_right .. "  " })

				-- Add desc of action
				table.insert(formatted_elements, { Foreground = { Color = text_color } })
				table.insert(formatted_elements, { Attribute = { Italic = true } })
				table.insert(formatted_elements, { Text = description })
				table.insert(formatted_elements, { Attribute = { Italic = false } })

				need_comma = true
			end
		end
	end

	table.insert(formatted_elements, { Text = " " })

	if #formatted_elements > 0 then
		return formatted_elements
	end

	return nil
end

return M
