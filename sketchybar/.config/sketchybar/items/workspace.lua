---
--- AeroSpace Workspace Indicator
--- Shows the currently focused AeroSpace workspace.
--- Hidden when AeroSpace is not running.
---

---
--- Creates the workspace indicator item.
---
---@param sbar SbarLua SketchyBar Lua API instance
---@param colors ColorPalette Color palette table
---@param styles Styles Shared styles (icons, fonts, popup settings)
---@param close_popups function Callback to close all popups
---@return SbarItem The created workspace item
return function(sbar, colors, styles, close_popups)
  local fonts = styles.fonts
  local c = styles.c

  ---@type SbarItem
  local workspace = sbar.add("item", "workspace", {
    position = "q",
    icon = { drawing = false },
    label = {
      string = "",
      font = fonts.text_semibold,
      color = c(colors.base),
      padding_left = 6,
      padding_right = 6,
    },
    background = {
      color = c(colors.overlay0),
      corner_radius = 4,
      height = 20,
    },
    drawing = false, -- Hidden by default until AeroSpace reports a workspace
  })

  -- Register for AeroSpace workspace change events
  sbar.add("event", "aerospace_workspace_change")

  ---
  --- Fetches current workspace from AeroSpace and updates display.
  ---
  ---@return nil
  local function update_workspace()
    sbar.exec("aerospace list-workspaces --focused 2>/dev/null", function(result)
      local ws = type(result) == "string" and result:gsub("%s+", "") or ""
      if ws ~= "" then
        workspace:set({ drawing = true, label = { string = ws } })
      else
        workspace:set({ drawing = false })
      end
    end)
  end

  -- Initial update and subscribe to events
  update_workspace()
  workspace:subscribe("aerospace_workspace_change", update_workspace)

  --- Closes all popups when clicked
  workspace:subscribe("mouse.clicked", close_popups)

  -- Spacer between workspace indicator and CPU stats
  sbar.add("item", "workspace_cpu_spacer", {
    position = "q",
    width = 10,
    icon = { drawing = false },
    label = { drawing = false },
  })

  return workspace
end
