---
--- System Statistics Items
--- Displays CPU, Disk, and RAM usage as vertically stacked labels.
--- Positioned in notch-adjacent left area (position "q").
---

---
--- Creates CPU, Disk, and RAM display items.
---
---@param sbar SbarLua SketchyBar Lua API instance
---@param colors ColorPalette Color palette table
---@param styles Styles Shared styles (icons, fonts, popup settings)
---@return nil
return function(sbar, colors, styles)
  local fonts = styles.fonts
  local c = styles.c

  -- Open Activity Monitor on click
  local open_activity_monitor = 'open -a "Activity Monitor"'

  -- ═══════════════════════════════════════════════════════════════════════════
  -- CPU Usage
  -- ═══════════════════════════════════════════════════════════════════════════

  ---@type SbarItem
  local cpu_percent = sbar.add("item", "cpu_percent", {
    position = "q",
    icon = { drawing = false },
    label = { string = "0%", font = fonts.text_heavy, color = c(colors.text) },
    y_offset = -4,
    update_freq = 2,
    width = 0, -- Zero width allows stacking with label
  })

  ---@type SbarItem
  local cpu_label = sbar.add("item", "cpu_label", {
    position = "q",
    icon = { drawing = false },
    label = { string = "CPU", font = fonts.label_tiny, color = c(colors.overlay1) },
    y_offset = 6,
  })

  -- Spacer between CPU and Disk
  sbar.add("item", "cpu_disk_spacer", {
    position = "q", width = 14, icon = { drawing = false }, label = { drawing = false },
  })

  ---
  --- Calculates CPU usage from process stats.
  --- Sums user and system CPU, divides by core count.
  ---
  ---@return nil
  local function update_cpu()
    sbar.exec([[
      CORE_COUNT=$(sysctl -n machdep.cpu.thread_count)
      CPU_INFO=$(ps -eo pcpu,user)
      CPU_SYS=$(echo "$CPU_INFO" | grep -v $(whoami) | sed "s/[^ 0-9\.]//g" | awk "{sum+=\$1} END {print sum/(100.0 * $CORE_COUNT)}")
      CPU_USER=$(echo "$CPU_INFO" | grep $(whoami) | sed "s/[^ 0-9\.]//g" | awk "{sum+=\$1} END {print sum/(100.0 * $CORE_COUNT)}")
      echo "$CPU_SYS $CPU_USER" | awk '{printf "%.0f", ($1 + $2)*100}'
    ]], function(result)
      local pct = type(result) == "string" and result:gsub("%s+", "") or "0"
      if pct == "" then pct = "0" end
      cpu_percent:set({ label = { string = pct .. "%" } })
    end)
  end

  update_cpu()
  cpu_percent:subscribe("routine", update_cpu)

  -- Click to open Activity Monitor
  cpu_percent:subscribe("mouse.clicked", function() sbar.exec(open_activity_monitor) end)
  cpu_label:subscribe("mouse.clicked", function() sbar.exec(open_activity_monitor) end)

  -- ═══════════════════════════════════════════════════════════════════════════
  -- Disk Usage
  -- ═══════════════════════════════════════════════════════════════════════════

  ---@type SbarItem
  local disk_percent = sbar.add("item", "disk_percent", {
    position = "q",
    icon = { drawing = false },
    label = { string = "0%", font = fonts.text_heavy, color = c(colors.text) },
    y_offset = -4,
    update_freq = 60,
    width = 0,
  })

  ---@type SbarItem
  local disk_label = sbar.add("item", "disk_label", {
    position = "q",
    icon = { drawing = false },
    label = { string = "DISK", font = fonts.label_tiny, color = c(colors.overlay1) },
    y_offset = 6,
  })

  -- Spacer between Disk and RAM
  sbar.add("item", "disk_ram_spacer", {
    position = "q", width = 14, icon = { drawing = false }, label = { drawing = false },
  })

  ---
  --- Gets root filesystem usage percentage.
  ---
  ---@return nil
  local function update_disk()
    sbar.exec("df -H / | awk 'NR==2 {print $5}'", function(result)
      local pct = type(result) == "string" and result:gsub("%s+", "") or "0%"
      if pct == "" then pct = "0%" end
      disk_percent:set({ label = { string = pct } })
    end)
  end

  update_disk()
  disk_percent:subscribe("routine", update_disk)

  -- Click to open Activity Monitor
  disk_percent:subscribe("mouse.clicked", function() sbar.exec(open_activity_monitor) end)
  disk_label:subscribe("mouse.clicked", function() sbar.exec(open_activity_monitor) end)

  -- ═══════════════════════════════════════════════════════════════════════════
  -- RAM Usage
  -- ═══════════════════════════════════════════════════════════════════════════

  ---@type SbarItem
  local ram_percent = sbar.add("item", "ram_percent", {
    position = "q",
    icon = { drawing = false },
    label = { string = "0%", font = fonts.text_heavy, color = c(colors.text) },
    y_offset = -4,
    update_freq = 5,
    width = 0,
  })

  ---@type SbarItem
  local ram_label = sbar.add("item", "ram_label", {
    position = "q",
    icon = { drawing = false },
    label = { string = "RAM", font = fonts.label_tiny, color = c(colors.overlay1) },
    y_offset = 6,
  })

  ---
  --- Sums memory usage from all processes.
  ---
  ---@return nil
  local function update_ram()
    sbar.exec("ps -A -o %mem | awk '{sum+=$1} END {printf \"%.0f\", sum}'", function(result)
      local pct = type(result) == "string" and result:gsub("%s+", "") or "0"
      if pct == "" then pct = "0" end
      ram_percent:set({ label = { string = pct .. "%" } })
    end)
  end

  update_ram()
  ram_percent:subscribe("routine", update_ram)

  -- Click to open Activity Monitor
  ram_percent:subscribe("mouse.clicked", function() sbar.exec(open_activity_monitor) end)
  ram_label:subscribe("mouse.clicked", function() sbar.exec(open_activity_monitor) end)
end
