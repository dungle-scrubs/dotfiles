---
--- Volume Control Item
--- Displays current volume percentage with icon reflecting level.
--- Icon changes: mute (0%), low (<33%), mid (33-66%), high (>66%).
---

---
--- Creates the volume control bar item.
---
---@param sbar SbarLua SketchyBar Lua API instance
---@param colors ColorPalette Color palette table
---@param styles Styles Shared styles (icons, fonts, popup settings)
---@param close_popups function Callback to close all popups
---@return SbarItem The created volume item
return function(sbar, colors, styles, close_popups)
  local icons = styles.icons
  local fonts = styles.fonts
  local c = styles.c

  ---@type SbarItem
  local volume = sbar.add("item", "volume", {
    position = "right",
    icon = { string = icons.volume_high, font = fonts.icon_small, color = c(colors.lavender) },
    label = { string = "0%" },
  })

  -- Register for volume change events
  sbar.add("event", "volume_change", "com.apple.audioOutputVolumeDidChange")

  ---
  --- Fetches current volume via AppleScript and updates icon/label.
  ---
  ---@return nil
  local function update_volume()
    sbar.exec("osascript -e 'output volume of (get volume settings)'", function(result)
      local vol = tonumber(type(result) == "string" and result:gsub("%s+", "") or "0") or 0

      -- Select icon based on volume level
      local icon
      if vol == 0 then
        icon = icons.volume_mute
      elseif vol < 33 then
        icon = icons.volume_low
      elseif vol < 66 then
        icon = icons.volume_mid
      else
        icon = icons.volume_high
      end

      volume:set({
        icon = { string = icon },
        label = { string = vol .. "%" },
      })
    end)
  end

  -- Initial update and subscribe to events
  update_volume()
  volume:subscribe("volume_change", update_volume)

  --- Closes all popups when clicked
  volume:subscribe("mouse.clicked", close_popups)

  return volume
end
