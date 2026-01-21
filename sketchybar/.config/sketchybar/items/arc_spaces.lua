---
--- Arc Browser Space Indicator
--- Shows Arc spaces as clickable letters to the right of front_app.
--- Only visible when Arc is the frontmost application.
---

---@param sbar SbarLua SketchyBar Lua API instance
---@param colors ColorPalette Color palette table
---@param styles Styles Shared styles (icons, fonts, popup settings)
---@return nil
return function(sbar, colors, styles)
  local fonts = styles.fonts
  local c = styles.c
  local home = os.getenv("HOME") or "/Users/" .. (os.getenv("USER") or "kevin")

  ---@type SbarItem[] Dynamic space items
  local space_items = {}

  ---@type boolean Track if Arc is frontmost
  local arc_is_front = false

  ---@type string|nil Last known active space (to avoid flashing)
  local last_active = nil

  ---@type string|nil Last known spaces list
  local last_spaces_str = nil

  -- Separator between front_app and arc spaces
  local arc_separator = sbar.add("item", "arc_separator", {
    position = "left",
    icon = { string = "›", font = fonts.text, color = c(colors.overlay0), padding_left = 4, padding_right = 4 },
    label = { drawing = false },
    drawing = false,
  })

  local function clear_items()
    for _, item in ipairs(space_items) do
      sbar.remove(item)
    end
    space_items = {}
  end

  local function hide_all()
    arc_separator:set({ drawing = false })
    clear_items()
    last_active = nil
    last_spaces_str = nil
  end

  local function update_arc_spaces()
    -- Check if Arc is frontmost
    sbar.exec("osascript -e 'tell application \"System Events\" to get name of first application process whose frontmost is true' 2>/dev/null", function(front_app)
      front_app = front_app and front_app:gsub("%s+$", "") or ""
      arc_is_front = (front_app == "Arc")

      if not arc_is_front then
        if last_spaces_str then hide_all() end
        return
      end

      -- Get spaces
      sbar.exec("osascript -e 'tell application \"Arc\" to get name of every space of first window' 2>/dev/null", function(spaces_csv)
        if not spaces_csv or spaces_csv == "" then
          if last_spaces_str then hide_all() end
          return
        end

        -- Get active space
        sbar.exec("osascript -e 'tell application \"Arc\" to tell first window to get name of active space' 2>/dev/null", function(active_result)
          local active_space = active_result and active_result:gsub("%s+$", "") or ""

          -- Check if anything changed
          if spaces_csv == last_spaces_str and active_space == last_active then
            return -- No change, skip redraw
          end

          last_spaces_str = spaces_csv
          last_active = active_space

          -- Write state to cache file for external scripts
          local cache = io.open("/tmp/arc_spaces_cache", "w")
          if cache then
            cache:write(spaces_csv .. "\n" .. active_space)
            cache:close()
          end

          -- Parse spaces
          local spaces = {}
          for space in spaces_csv:gmatch("[^,]+") do
            local trimmed = space:gsub("^%s+", ""):gsub("%s+$", "")
            if trimmed ~= "" then
              table.insert(spaces, trimmed)
            end
          end

          -- Update cached state for instant switching
          cached_spaces = spaces
          for i, name in ipairs(spaces) do
            if name == active_space then
              current_index = i
              break
            end
          end

          clear_items()

          if #spaces == 0 then
            arc_separator:set({ drawing = false })
            return
          end

          arc_separator:set({ drawing = true })

          for i, space_name in ipairs(spaces) do
            local is_active = space_name == active_space
            local display_text = is_active and space_name or space_name:sub(1, 1):upper()

            local item = sbar.add("item", "arc_space." .. i, {
              position = "left",
              icon = { drawing = false },
              label = {
                string = display_text,
                font = fonts.text_semibold,
                color = is_active and c(colors.blue) or c(colors.overlay1),
                padding_left = is_active and 6 or 4,
                padding_right = is_active and 6 or 4,
              },
              background = {
                color = is_active and c(colors.surface1) or c(colors.transparent),
                corner_radius = is_active and 4 or 3,
                height = is_active and 20 or 18,
              },
            })

            -- Click handler with full path
            local switch_script = home .. "/.local/bin/arc-space"
            item:subscribe("mouse.clicked", function()
              sbar.exec(switch_script .. " goto '" .. space_name .. "'")
              sbar.exec("sleep 0.3 && sketchybar --trigger arc_space_update")
            end)

            table.insert(space_items, item)
          end
        end)
      end)
    end)
  end

  -- Register custom events
  sbar.add("event", "arc_space_update")
  sbar.add("event", "arc_space_next")
  sbar.add("event", "arc_space_prev")

  ---@type string[] Cached space names for instant switching
  local cached_spaces = {}

  ---@type number Current space index (1-based)
  local current_index = 1

  -- Switch to a space by name and update UI instantly
  local function switch_to_space(space_name)
    -- Update UI immediately
    last_active = space_name
    for i, item in ipairs(space_items) do
      local is_active = cached_spaces[i] == space_name
      local display_text = is_active and space_name or cached_spaces[i]:sub(1, 1):upper()
      item:set({
        label = {
          string = display_text,
          color = is_active and c(colors.blue) or c(colors.overlay1),
          padding_left = is_active and 6 or 4,
          padding_right = is_active and 6 or 4,
        },
        background = {
          color = is_active and c(colors.surface1) or c(colors.transparent),
          corner_radius = is_active and 4 or 3,
          height = is_active and 20 or 18,
        },
      })
    end

    -- Then tell Arc to switch (no delay, assume Arc is frontmost since that's when this is used)
    sbar.exec('osascript -e \'tell application "System Events" to tell process "Arc" to click menu item "' .. space_name .. '" of menu "Spaces" of menu bar 1\'')
  end

  local function go_next()
    if #cached_spaces == 0 then return end
    current_index = (current_index % #cached_spaces) + 1
    switch_to_space(cached_spaces[current_index])
  end

  local function go_prev()
    if #cached_spaces == 0 then return end
    current_index = ((current_index - 2 + #cached_spaces) % #cached_spaces) + 1
    switch_to_space(cached_spaces[current_index])
  end

  -- Trigger item with 1s polling when Arc is front
  local arc_trigger = sbar.add("item", "arc_trigger", {
    position = "left",
    drawing = false,
    updates = true,
    update_freq = 1,
  })

  arc_trigger:subscribe("routine", function()
    if arc_is_front then
      update_arc_spaces()
    end
  end)
  arc_trigger:subscribe("arc_space_update", update_arc_spaces)
  arc_trigger:subscribe("front_app_switched", update_arc_spaces)
  arc_trigger:subscribe("arc_space_next", go_next)
  arc_trigger:subscribe("arc_space_prev", go_prev)

  update_arc_spaces()
end
