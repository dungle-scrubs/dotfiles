---
--- Date/Time Display Item
--- Shows date and time in vertically stacked format.
--- Date appears above time using y_offset positioning.
---

---
--- Creates the date/time display items (stacked vertically).
---
---@param sbar SbarLua SketchyBar Lua API instance
---@param colors ColorPalette Color palette table
---@param styles Styles Shared styles (icons, fonts, popup settings)
---@param close_popups function Callback to close all popups
---@return nil
return function(sbar, colors, styles, close_popups)
  local fonts = styles.fonts
  local c = styles.c

  ---@type SbarItem
  local date_label = sbar.add("item", "date_label", {
    position = "right",
    icon = { drawing = false },
    label = { string = "Mon Jan 20", font = fonts.label_small, color = c(colors.subtext0) },
    y_offset = 6,
    width = 0, -- Zero width allows stacking with time
  })

  ---@type SbarItem
  local time_label = sbar.add("item", "time_label", {
    position = "right",
    icon = { drawing = false },
    label = { string = "12:00", font = fonts.text_heavy, color = c(colors.text) },
    y_offset = -4,
    update_freq = 30,
  })

  ---
  --- Updates both date and time labels via shell date command.
  ---
  ---@return nil
  local function update_datetime()
    -- Update date (e.g., "Mon Jan 20")
    sbar.exec("date '+%a %b %d'", function(result)
      local d = type(result) == "string" and result:gsub("%s+$", "") or ""
      date_label:set({ label = { string = d } })
    end)

    -- Update time (e.g., "9:30 AM" - leading zero stripped)
    sbar.exec("date '+%I:%M %p'", function(result)
      local t = type(result) == "string" and result:gsub("%s+$", ""):gsub("^0", "") or ""
      time_label:set({ label = { string = t } })
    end)
  end

  -- Initial update and subscribe to routine updates
  update_datetime()
  time_label:subscribe("routine", update_datetime)

  --- Close popups when either label clicked
  time_label:subscribe("mouse.clicked", close_popups)
  date_label:subscribe("mouse.clicked", close_popups)
end
