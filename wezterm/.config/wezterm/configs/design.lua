local colors = require("configs.colors")

local M = {}

local TAB_MAX_WIDTH = 28
local TAB_PADDING = 4
local MAX_TITLE_LENGTH = TAB_MAX_WIDTH - TAB_PADDING

---Formats a tab title with index prefix, truncating if needed
---@param tab_info table
---@return string
local function tab_title(tab_info)
	local usr_title = tab_info.tab_title
	local index = tab_info.tab_index + 1 .. " : "

	local title
	if usr_title and #usr_title > 0 then
		title = index .. usr_title
	else
		title = tostring(tab_info.tab_index + 1)
	end

	if #title > MAX_TITLE_LENGTH then
		title = title:sub(1, MAX_TITLE_LENGTH - 2) .. ".."
	end

	return title
end

Wezterm.on("format-tab-title", function(tab)
	local title = tab_title(tab)
	local fg = tab.is_active and colors.yellow or colors.inactive_fg

	return {
		{ Background = { Color = colors.background } },
		{ Foreground = { Color = fg } },
		{ Text = "  " .. title .. "  " },
	}
end)

---Applies design configuration to WezTerm
---@param config table
function M.apply(config)
	config.window_decorations = "RESIZE"
	config.window_padding = {
		left = 10,
		right = 10,
		top = 15,
		bottom = 10,
	}
	config.window_frame = {
		active_titlebar_bg = colors.background,
	}

	config.inactive_pane_hsb = {
		saturation = 0.1,
		brightness = 0.5,
	}

	config.underline_thickness = "1pt"
	config.underline_position = "-4pt"

	config.use_fancy_tab_bar = false
	config.tab_bar_at_bottom = true
	config.tab_max_width = TAB_MAX_WIDTH

	config.command_palette_rows = 24
	config.command_palette_bg_color = colors.background
	config.command_palette_fg_color = colors.foreground
	config.command_palette_font_size = 16

	config.cursor_blink_rate = 0
	config.cursor_thickness = 2

	config.font = Wezterm.font("JetBrainsMono Nerd Font Mono")
	config.font_size = 16
	config.harfbuzz_features = {
		"ss01", "ss02", "ss03", "ss04", "ss05", "ss07",
		"cv02", "cv14", "cv27", "cv29", "cv30",
	}

	config.allow_square_glyphs_to_overflow_width = "Never"
	config.treat_east_asian_ambiguous_as_wide = false
	config.unicode_version = 14

	config.bold_brightens_ansi_colors = false
	config.colors = {
		background = colors.background,
		foreground = colors.foreground,
		cursor_bg = colors.foreground,
		selection_bg = colors.soft_red,
		selection_fg = colors.black,
		ansi = {
			colors.black,
			colors.soft_red,
			colors.foreground,
			colors.yellow,
			colors.blue,
			colors.purple,
			colors.blue_alt,
			colors.white,
		},
	}
end

return M
