---
--- Front App Display Item
--- Shows the name of the currently focused application.
--- Updates automatically when app focus changes.
---

---
--- Creates the front app display item.
---
---@param sbar SbarLua SketchyBar Lua API instance
---@param colors ColorPalette Color palette table
---@param styles Styles Shared styles (icons, fonts, popup settings)
---@param close_popups function Callback to close all popups
---@return SbarItem The created front app item
return function(sbar, colors, styles, close_popups)
  local fonts = styles.fonts
  local c = styles.c

  ---@type SbarItem
  local front_app = sbar.add("item", "front_app", {
    position = "left",
    icon = { drawing = false },
    label = {
      string = "Finder",
      font = fonts.text_semibold,
      color = c(colors.subtext0),
    },
  })

  -- Register for front app switch events (provided by SketchyBar helper)
  sbar.add("event", "front_app_switched")

  --- Updates label when front app changes, closes popups
  ---@param env table Event environment with INFO field containing app name
  front_app:subscribe("front_app_switched", function(env)
    front_app:set({ label = { string = env.INFO or "—" } })
    sbar.exec("sketchybar --set apple popup.drawing=off --set api_usage popup.drawing=off --set docker popup.drawing=off --set releases popup.drawing=off")
  end)

  --- Closes all popups when clicked
  front_app:subscribe("mouse.clicked", close_popups)

  -- Initialize with current frontmost app via AppleScript
  sbar.exec("osascript -e 'tell application \"System Events\" to get name of first application process whose frontmost is true'", function(result)
    local app = type(result) == "string" and result:gsub("%s+$", "") or "Finder"
    front_app:set({ label = { string = app } })
  end)

  return front_app
end
