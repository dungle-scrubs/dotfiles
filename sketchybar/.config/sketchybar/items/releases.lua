---
--- Release Notes Dropdown Item
--- Displays recent release news for Claude Code, Codex, and Clawdbot.
--- Fetches from CHANGELOG.md or GitHub Releases API.
---

---
--- Creates the releases dropdown item with popup news feed.
---
---@param sbar SbarLua SketchyBar Lua API instance
---@param colors ColorPalette Color palette table
---@param styles Styles Shared styles (icons, fonts, popup settings)
---@return SbarItem The created releases item
return function(sbar, colors, styles)
  local fonts = styles.fonts
  local popup = styles.popup
  local c = styles.c

  local releases = sbar.add("item", "releases", {
    position = "e",
    icon = { string = "󰋼", font = fonts.icon_small, color = c(colors.peach) },
    label = { string = "News", font = fonts.text_semibold, color = c(colors.text) },
    update_freq = 3600,
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
  local releases_popup_items = {}

  ---@type number Maximum characters per line before wrapping
  local MAX_LINE_WIDTH = 135

  ---
  --- Wraps text into multiple lines at word boundaries.
  ---
  ---@param text string The text to wrap
  ---@param max_width number Maximum characters per line
  ---@return string[] Array of wrapped lines
  local function wrap_text(text, max_width)
    if #text <= max_width then return { text } end
    local lines = {}
    local current = ""
    for word in text:gmatch("%S+") do
      if #current + #word + 1 <= max_width then
        current = current == "" and word or current .. " " .. word
      else
        if current ~= "" then table.insert(lines, current) end
        current = word
      end
    end
    if current ~= "" then table.insert(lines, current) end
    return lines
  end

  ---@class AppConfig Release source configuration
  ---@field name string Display name
  ---@field url string URL to fetch releases from
  ---@field icon string Nerd Font icon codepoint
  ---@field color string Accent color for header
  ---@field parse_mode string Parser type: "added", "github_release", or "sections"
  ---@field sections? string[] Section headers to extract (for section-based parsing)
  ---@field max_releases? number Maximum releases to show (default 3)

  ---@type AppConfig[] Configured release sources
  local apps = {
    {
      name = "Claude Code",
      url = "https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md",
      icon = "󰧑",
      color = colors.peach,
      parse_mode = "added", -- Look for "- Added ..."
    },
    {
      name = "Codex",
      url = "https://api.github.com/repos/openai/codex/releases/latest",
      icon = "",
      color = colors.green,
      parse_mode = "github_release",
      sections = { "New Features" },
    },
    {
      name = "Clawdbot",
      url = "https://api.github.com/repos/clawdbot/clawdbot/releases/latest",
      icon = "🤖",
      color = colors.blue,
      parse_mode = "github_release",
      sections = { "Changes" },
    },
  }

  ---
  --- Parses CHANGELOG.md for "- Added ..." entries (Claude Code style).
  ---
  ---@param content string Raw changelog content
  ---@param max_releases number Maximum releases to parse
  ---@return table[] Array of {version, items} release objects
  local function parse_added_style(content, max_releases)
    local results = {}
    local current_version = nil
    local current_items = {}

    for line in content:gmatch("[^\n]+") do
      local version = line:match("^## (%d+%.%d+%.%d+)")
      if version then
        if current_version and #current_items > 0 then
          table.insert(results, { version = current_version, items = current_items })
          if #results >= max_releases then break end
        end
        current_version = version
        current_items = {}
      else
        local added_text = line:match("^%- [Aa]dded (.+)")
        if added_text and current_version then
                    table.insert(current_items, { section = "Added", text = added_text })
        end
      end
    end

    if current_version and #current_items > 0 and #results < max_releases then
      table.insert(results, { version = current_version, items = current_items })
    end

    return results
  end

  ---
  --- Parses GitHub Releases API response (pre-processed by jq).
  --- Extracts version and body, filters by wanted section headers.
  ---
  ---@param content string jq-formatted "VERSION:...\nBODY:..." content
  ---@param wanted_sections string[] Section headers to include
  ---@return table[] Array of {version, items} release objects
  local function parse_github_release(content, wanted_sections)
    local results = {}
    local wanted_set = {}
    for _, s in ipairs(wanted_sections) do wanted_set[s:lower()] = s end

    -- Extract version and body from jq-formatted output
    local version = content:match("VERSION:([^\n]+)")
    local body = content:match("BODY:(.*)")

    if not version or not body then return results end

    local current_items = {}
    local current_section = nil

    for line in body:gmatch("[^\n]+") do
      -- Match both ## and ### section headers
      local section = line:match("^###? (.+)")
      if section then
        current_section = wanted_set[section:lower()]
      elseif current_section then
        local item_text = line:match("^%- (.+)")
        if item_text then
          if current_section == "Breaking" then
            item_text = item_text:gsub("^%*%*BREAKING:%*%*%s*", "")
          end
                    table.insert(current_items, { section = current_section, text = item_text })
        end
      end
    end

    if #current_items > 0 then
      table.insert(results, { version = version:gsub("^v", ""), items = current_items })
    end

    return results
  end

  ---
  --- Parses CHANGELOG with ### section headers (Clawdbot style).
  --- Filters entries by section name (e.g., "Highlights", "Breaking").
  ---
  ---@param content string Raw changelog content
  ---@param max_releases number Maximum releases to parse
  ---@param wanted_sections string[] Section headers to include
  ---@return table[] Array of {version, items} release objects
  local function parse_sections_style(content, max_releases, wanted_sections)
    local results = {}
    local current_version = nil
    local current_items = {}
    local current_section = nil
    local wanted_set = {}
    for _, s in ipairs(wanted_sections) do wanted_set[s:lower()] = s end

    for line in content:gmatch("[^\n]+") do
      -- Version header (## YYYY.M.DD or ## x.x.x)
      local version = line:match("^## ([%d%.%-]+)")
      if version then
        if current_version and #current_items > 0 then
          table.insert(results, { version = current_version, items = current_items })
          if #results >= max_releases then break end
        end
        current_version = version
        current_items = {}
        current_section = nil
      else
        -- Section header (### Something)
        local section = line:match("^### (.+)")
        if section then
          current_section = wanted_set[section:lower()]
        elseif current_section and current_version then
          -- Bullet item
          local item_text = line:match("^%- (.+)")
          if item_text then
            -- Clean up BREAKING prefix if in Breaking section
            if current_section == "Breaking" then
              item_text = item_text:gsub("^%*%*BREAKING:%*%*%s*", "")
            end
                        table.insert(current_items, { section = current_section, text = item_text })
          end
        end
      end
    end

    if current_version and #current_items > 0 and #results < max_releases then
      table.insert(results, { version = current_version, items = current_items })
    end

    return results
  end

  ---
  --- Fetches and renders release notes for all configured apps.
  --- Creates popup items dynamically, grouped by app and version.
  ---
  ---@return nil
  local function update_releases()
    releases:set({ label = { string = "...", color = c(colors.subtext0) } })

    for _, item in ipairs(releases_popup_items) do
      sbar.remove(item)
    end
    releases_popup_items = {}

    local item_idx = 0
    local apps_processed = 0

    for app_idx, app in ipairs(apps) do
      local curl_cmd = "curl -s '" .. app.url .. "'"
      if app.parse_mode == "github_release" then
        curl_cmd = curl_cmd .. " | jq -r '\"VERSION:\" + .tag_name + \"\\nBODY:\" + .body'"
      end
      sbar.exec(curl_cmd, function(result)
        apps_processed = apps_processed + 1

        if type(result) == "string" and result ~= "" then
          local max_rel = app.max_releases or 1
          local parsed
          if app.parse_mode == "github_release" then
            parsed = parse_github_release(result, app.sections)
          elseif app.parse_mode == "sections" then
            parsed = parse_sections_style(result, max_rel, app.sections)
          else
            parsed = parse_added_style(result, max_rel)
          end

          -- Get version from first release for header
          local version_str = parsed[1] and ("  v" .. parsed[1].version) or ""

          -- Separator before app (if not first)
          if app_idx > 1 then
            item_idx = item_idx + 1
            local sep = sbar.add("item", "releases.sep." .. item_idx, {
              position = "popup.releases",
              icon = { drawing = false },
              label = {
                string = "────────────────────────────────────────────────────────────────────────────────────────────────────────────",
                font = "Hack Nerd Font:Regular:8.0",
                color = c(colors.surface1),
                padding_left = popup.padding,
                padding_right = popup.padding,
              },
              background = { height = popup.separator_height },
            })
            table.insert(releases_popup_items, sep)
          end

          -- App header with version on same line
          item_idx = item_idx + 1
          local header = sbar.add("item", "releases.app." .. item_idx, {
            position = "popup.releases",
            icon = { drawing = false },
            label = {
              string = app.name .. version_str,
              font = fonts.popup_bold,
              color = c(app.color),
              padding_left = popup.padding,
              padding_right = popup.padding,
            },
            background = { height = popup.header_height },
          })
          table.insert(releases_popup_items, header)

          -- Releases (only items, version is in header now)
          for _, rel in ipairs(parsed) do
            -- Items grouped by section
            local last_section = nil
            for _, entry in ipairs(rel.items) do
              -- Section label if changed
              if entry.section ~= last_section then
                item_idx = item_idx + 1
                local section_color = entry.section == "Breaking" and colors.red or colors.yellow
                local sec_item = sbar.add("item", "releases.sec." .. item_idx, {
                  position = "popup.releases",
                  icon = { drawing = false },
                  label = {
                    string = entry.section,
                    font = fonts.popup_bold,
                    color = c(section_color),
                    padding_left = popup.padding + 8,
                    padding_right = popup.padding,
                  },
                })
                table.insert(releases_popup_items, sec_item)
                last_section = entry.section
              end

              -- Item with wrapping
              local lines = wrap_text(entry.text, MAX_LINE_WIDTH)
              for line_num, line_text in ipairs(lines) do
                item_idx = item_idx + 1
                local is_first = line_num == 1
                local add_item = sbar.add("item", "releases.add." .. item_idx, {
                  position = "popup.releases",
                  icon = {
                    string = is_first and "+" or " ",
                    font = "Hack Nerd Font:Bold:9.0",
                    color = c(colors.green),
                    padding_left = popup.padding + 8,
                    padding_right = 4,
                  },
                  label = {
                    string = line_text,
                    font = fonts.popup,
                    color = c(colors.subtext0),
                    padding_right = popup.padding,
                  },
                })
                table.insert(releases_popup_items, add_item)
              end
            end
          end
        end

        if apps_processed == #apps then
          releases:set({ label = { string = "News", color = c(colors.text) } })
        end
      end)
    end
  end

  update_releases()
  releases:subscribe("routine", update_releases)

  releases:subscribe("mouse.clicked", function()
    sbar.exec("sketchybar --set apple popup.drawing=off --set api_usage popup.drawing=off --set docker popup.drawing=off --set wifi popup.drawing=off")
    releases:set({ popup = { drawing = "toggle" } })
  end)

  return releases
end
