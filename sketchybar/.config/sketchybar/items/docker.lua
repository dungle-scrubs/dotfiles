---
--- Docker Container Monitor Item
--- Displays running container count with health status popup.
--- Groups containers by Docker Compose project.
---

---
--- Creates the Docker container monitor item with popup details.
---
---@param sbar SbarLua SketchyBar Lua API instance
---@param colors ColorPalette Color palette table
---@param styles Styles Shared styles (icons, fonts, popup settings)
---@return SbarItem The created Docker monitor item
return function(sbar, colors, styles)
  local icons = styles.icons
  local fonts = styles.fonts
  local popup = styles.popup
  local c = styles.c

  local docker = sbar.add("item", "docker", {
    position = "e",
    icon = { string = icons.docker, font = fonts.icon_small, color = c(colors.blue) },
    label = { string = "0", font = fonts.text_semibold, color = c(colors.text) },
    update_freq = 30,
    popup = {
      align = "center",
      height = popup.height,
      background = {
        color = c(colors.surface0),
        border_width = 2,
        corner_radius = 9,
        border_color = c(colors.blue),
      },
    },
  })

  ---@type SbarItem[] Dynamically created popup items for cleanup
  local docker_popup_items = {}

  ---
  --- Queries Docker for running containers and updates the popup.
  --- Displays container health, uptime, and memory usage.
  --- Groups containers by Docker Compose project name.
  ---
  ---@return nil
  local function update_docker()
    docker:set({ label = { string = "...", color = c(colors.subtext0) } })

    local cmd = [[
      /usr/local/bin/docker ps --format '{{.Names}}|{{.Status}}|{{.Label "com.docker.compose.project"}}|{{.Label "com.docker.compose.service"}}' 2>/dev/null | while read line; do
        cname=$(echo "$line" | cut -d'|' -f1)
        cstatus=$(echo "$line" | cut -d'|' -f2)
        project=$(echo "$line" | cut -d'|' -f3)
        service=$(echo "$line" | cut -d'|' -f4)
        [ -z "$service" ] && service="$cname"
        [ -z "$project" ] && project="_standalone"
        health=""
        if echo "$cstatus" | grep -q "(healthy)"; then health="healthy"
        elif echo "$cstatus" | grep -q "(unhealthy)"; then health="unhealthy"
        elif echo "$cstatus" | grep -q "Restarting"; then health="crashing"
        elif echo "$cstatus" | grep -q "Exited"; then health="exited"
        else health="up"; fi
        uptime=$(echo "$cstatus" | sed -E '
          s/.*Up ([0-9]+) hours?.*/\1h/
          s/.*Up ([0-9]+) minutes?.*/\1m/
          s/.*Up ([0-9]+) seconds?.*/\1s/
          s/.*Up About a minute.*/~1m/
          s/.*Up About an hour.*/~1h/
          s/.*Restarting.*/--/
          s/.*Exited.*/--/
        ')
        mem=$(/usr/local/bin/docker stats --no-stream --format '{{.MemUsage}}' "$cname" 2>/dev/null | cut -d'/' -f1 | tr -d ' ')
        [ -z "$mem" ] && mem="0B"
        echo "$project|$service|$health|$uptime|$mem"
      done
    ]]

    sbar.exec(cmd, function(result)
      local lines = {}
      if type(result) == "string" and result ~= "" then
        for line in result:gmatch("[^\n]+") do
          table.insert(lines, line)
        end
      end

      local has_broken = false
      for _, line in ipairs(lines) do
        local _, _, health = line:match("([^|]+)|([^|]+)|([^|]+)")
        if health == "crashing" or health == "exited" or health == "unhealthy" then
          has_broken = true
          break
        end
      end

      local count_str = tostring(#lines)
      if has_broken then
        docker:set({ label = { string = count_str .. " !", color = c(colors.red) } })
      else
        docker:set({ label = { string = count_str, color = c(colors.text) } })
      end

      for _, item in ipairs(docker_popup_items) do
        sbar.remove(item)
      end
      docker_popup_items = {}

      if #lines == 0 then
        local item = sbar.add("item", "docker.none", {
          position = "popup.docker",
          icon = { drawing = false },
          label = {
            string = "No containers running",
            font = fonts.popup,
            color = c(colors.subtext0),
            padding_left = popup.padding,
            padding_right = popup.padding,
          },
        })
        table.insert(docker_popup_items, item)
      else
        local groups = {}
        local group_order = {}
        for _, line in ipairs(lines) do
          local project, service, health, uptime, mem = line:match("([^|]+)|([^|]+)|([^|]+)|([^|]+)|(.+)")
          if project then
            if not groups[project] then
              groups[project] = {}
              table.insert(group_order, project)
            end
            table.insert(groups[project], { service = service, health = health, uptime = uptime, mem = mem })
          end
        end

        local item_idx = 0
        for gi, group in ipairs(group_order) do
          local is_standalone = (group == "_standalone")

          if gi > 1 then
            item_idx = item_idx + 1
            local sep = sbar.add("item", "docker.sep." .. item_idx, {
              position = "popup.docker",
              icon = { drawing = false },
              label = {
                string = "────────────────────────────────────────",
                font = "Hack Nerd Font:Regular:8.0",
                color = c(colors.surface1),
                padding_left = popup.padding,
                padding_right = popup.padding,
              },
              background = { height = popup.separator_height },
            })
            table.insert(docker_popup_items, sep)
          end

          if not is_standalone then
            item_idx = item_idx + 1
            local header = sbar.add("item", "docker.hdr." .. item_idx, {
              position = "popup.docker",
              icon = { drawing = false },
              label = {
                string = group,
                font = fonts.popup_bold,
                color = c(colors.mauve),
                padding_left = popup.padding,
                padding_right = popup.padding,
              },
              background = { height = popup.header_height },
            })
            table.insert(docker_popup_items, header)
          end

          for _, c_data in ipairs(groups[group]) do
            item_idx = item_idx + 1
            local status_color = colors.green
            local label_color = colors.text
            local status_icon = "●"
            local is_bad = c_data.health == "crashing" or c_data.health == "exited" or c_data.health == "unhealthy"
            if is_bad then
              status_color = colors.red
              label_color = colors.red
              status_icon = "○"
            end

            local display = string.format("%-20s %-10s %5s %10s", c_data.service, c_data.health, c_data.uptime, c_data.mem)

            local item = sbar.add("item", "docker." .. item_idx, {
              position = "popup.docker",
              icon = {
                string = status_icon,
                font = "Hack Nerd Font:Regular:8.0",
                color = c(status_color),
                padding_left = popup.padding,
                padding_right = popup.padding,
                y_offset = 1,
              },
              label = {
                string = display,
                font = fonts.popup,
                color = c(label_color),
                padding_right = popup.padding,
                padding_left = 0,
              },
            })
            table.insert(docker_popup_items, item)
          end
        end
      end
    end)
  end

  update_docker()
  docker:subscribe("routine", update_docker)

  docker:subscribe("mouse.clicked", function()
    sbar.exec("sketchybar --set apple popup.drawing=off --set api_usage popup.drawing=off --set releases popup.drawing=off --set wifi popup.drawing=off")
    docker:set({ popup = { drawing = "toggle" } })
  end)

  return docker
end
