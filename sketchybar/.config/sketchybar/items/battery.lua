---
--- Battery Status Item
--- Displays battery percentage with icon reflecting charge level.
--- Icon color indicates: green (>50%), yellow (20-50% or charging), red (<20%).
---

---
--- Creates the battery status bar item.
---
---@param sbar SbarLua SketchyBar Lua API instance
---@param colors ColorPalette Color palette table
---@param styles Styles Shared styles (icons, fonts, popup settings)
---@param close_popups function Callback to close all popups
---@return SbarItem The created battery item
return function(sbar, colors, styles, close_popups)
  local icons = styles.icons
  local fonts = styles.fonts
  local c = styles.c

  ---@type SbarItem
  local battery = sbar.add("item", "battery", {
    position = "right",
    update_freq = 60,
    icon = { string = icons.battery[11], font = fonts.icon, color = c(colors.green) },
    label = { string = "100%" },
  })

  -- Register for power source change events
  sbar.add("event", "power_source_change", "com.apple.system.config.powerSourceChange")

  ---
  --- Fetches battery status via pmset and updates icon/label.
  --- Handles three states: charging, plugged (not charging), on battery.
  ---
  ---@return nil
  local function update_battery()
    sbar.exec("pmset -g batt", function(result)
      local output = type(result) == "string" and result or ""
      local pct = tonumber(output:match("(%d+)%%")) or 0
      local on_ac = output:find("AC Power")
      local charging = output:find("charging") and not output:find("discharging")

      -- Calculate battery icon index (1-11 for 0-100%)
      local idx = math.floor(pct / 10) + 1
      idx = math.min(idx, 11)

      local icon, icon_color
      if charging then
        -- Actively charging: show charging icon in yellow
        icon = icons.battery_charging
        icon_color = c(colors.yellow)
      elseif on_ac then
        -- Plugged in but not charging: show level icon in yellow
        icon = icons.battery[idx]
        icon_color = c(colors.yellow)
      else
        -- On battery: color based on percentage
        icon = icons.battery[idx]
        if pct > 50 then
          icon_color = c(colors.green)
        elseif pct > 20 then
          icon_color = c(colors.yellow)
        else
          icon_color = c(colors.red)
        end
      end

      battery:set({
        icon = { string = icon, color = icon_color },
        label = { string = pct .. "%" },
      })
    end)
  end

  -- Initial update and subscribe to events
  update_battery()
  battery:subscribe({ "routine", "system_woke", "power_source_change" }, update_battery)

  --- Closes all popups when clicked
  battery:subscribe("mouse.clicked", close_popups)

  return battery
end
