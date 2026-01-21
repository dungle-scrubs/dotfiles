---
--- Apple Menu Item
--- Displays Apple logo with popup menu for system actions.
---
--- @module items.apple
---

---
--- Creates the Apple menu bar item with popup.
---
---@param sbar SbarLua SketchyBar Lua API instance
---@param colors ColorPalette Color palette table
---@param styles Styles Shared styles (icons, fonts, popup settings)
---@return SbarItem The created Apple menu item
return function(sbar, colors, styles)
  local icons = styles.icons
  local fonts = styles.fonts
  local c = styles.c

  ---@type SbarItem
  local apple = sbar.add("item", "apple", {
    position = "left",
    icon = {
      string = icons.apple,
      font = fonts.icon,
      color = c(colors.text),
      padding_left = 4,
      padding_right = 4,
    },
    label = { drawing = false },
    popup = {
      height = 35,
      blur_radius = 50,
      background = {
        color = c(colors.surface0),
        border_width = 2,
        corner_radius = 9,
        border_color = c(colors.blue),
      },
    },
  })

  ---@class ApplePopupItem
  ---@field name string Item identifier
  ---@field icon string Nerd Font icon
  ---@field label string Display label
  ---@field cmd string Shell command to execute on click

  ---@type ApplePopupItem[]
  local popup_items = {
    { name = "apple.prefs", icon = "󰒓", label = "System Settings", cmd = "open -a 'System Settings'" },
    { name = "apple.activity", icon = "󰍛", label = "Activity Monitor", cmd = "open -a 'Activity Monitor'" },
    { name = "apple.lock", icon = "󰌾", label = "Lock Screen", cmd = "pmset displaysleepnow" },
  }

  -- Create popup menu items
  for _, item in ipairs(popup_items) do
    local popup_item = sbar.add("item", item.name, {
      position = "popup.apple",
      icon = {
        string = item.icon,
        font = fonts.icon,
        padding_left = 8,
        padding_right = 4,
      },
      label = {
        string = item.label,
        font = fonts.text_semibold,
        padding_right = 8,
      },
    })

    --- Executes command and closes popup on click
    popup_item:subscribe("mouse.clicked", function()
      sbar.exec(item.cmd)
      apple:set({ popup = { drawing = false } })
    end)
  end

  --- Toggles popup, closing other popups first
  apple:subscribe("mouse.clicked", function()
    sbar.exec("sketchybar --set api_usage popup.drawing=off --set docker popup.drawing=off --set releases popup.drawing=off --set wifi popup.drawing=off")
    apple:set({ popup = { drawing = "toggle" } })
  end)

  --- Closes popup when mouse exits globally
  apple:subscribe("mouse.exited.global", function()
    apple:set({ popup = { drawing = false } })
  end)

  return apple
end
