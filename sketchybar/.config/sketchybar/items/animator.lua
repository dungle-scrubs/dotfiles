---
--- Lock/Unlock Animation Item
--- Animates the bar sliding away on screen lock and back on unlock.
--- Uses sine easing for smooth transitions.
---

---
--- Creates the animator item that responds to lock/unlock events.
---
---@param sbar SbarLua SketchyBar Lua API instance
---@param colors ColorPalette Color palette table
---@param styles Styles Shared styles (icons, fonts, popup settings)
---@return SbarItem The created animator item
return function(sbar, colors, styles)
  local c = styles.c

  -- Register for macOS lock/unlock events
  sbar.add("event", "lock", "com.apple.screenIsLocked")
  sbar.add("event", "unlock", "com.apple.screenIsUnlocked")

  ---@type SbarItem
  local animator = sbar.add("item", "animator", {
    position = "left",
    drawing = false, -- Invisible item, just handles events
    updates = true,
  })

  --- Animates bar sliding up and fading on lock
  animator:subscribe("lock", function()
    sbar.exec(string.format([[
      sketchybar --animate sin 5 \
                 --bar color=%s \
                 --bar y_offset=-34 \
                       margin=-200 \
                       blur_radius=0
    ]], c(colors.transparent)))
  end)

  --- Animates bar sliding down and appearing on unlock
  animator:subscribe("unlock", function()
    sbar.exec(string.format([[
      sketchybar --animate sin 5 \
                 --bar color=%s \
                 --animate sin 25 \
                 --bar y_offset=0 \
                       margin=0
    ]], c(colors.base)))
  end)

  return animator
end
