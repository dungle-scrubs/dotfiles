---
--- API Usage Monitor Item
--- Displays AI provider usage/costs in a popup.
--- Fetches costs from APIs using 1Password-stored credentials.
---

---
--- Creates the API usage monitor item with popup details.
---
---@param sbar SbarLua SketchyBar Lua API instance
---@param colors ColorPalette Color palette table
---@param styles Styles Shared styles (icons, fonts, popup settings)
---@return SbarItem The created API usage item
return function(sbar, colors, styles)
  local icons = styles.icons
  local fonts = styles.fonts
  local popup = styles.popup
  local c = styles.c

  local api_usage = sbar.add("item", "api_usage", {
    position = "e",
    icon = { string = icons.api, font = fonts.icon_small, color = c(colors.mauve) },
    label = { string = "AI", font = fonts.text_semibold, color = c(colors.text) },
    update_freq = 1800,
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

  -- Format: %-10s (name left)  %8s (value right)  %8s (period right)
  local fmt = "%-10s  %8s  %8s"

  -- Alphabetical order: Anthropic, Codex, MiniMax, OpenAI, Z.ai
  local api_anthropic = sbar.add("item", "api_usage.anthropic", {
    position = "popup.api_usage",
    icon = { drawing = false },
    label = {
      string = string.format(fmt, "Anthropic", "$0.00", "30d"),
      font = fonts.popup,
      padding_left = popup.padding,
      padding_right = popup.padding,
    },
  })

  local api_codex = sbar.add("item", "api_usage.codex", {
    position = "popup.api_usage",
    icon = { drawing = false },
    label = {
      string = string.format(fmt, "Codex", "0%", "session"),
      font = fonts.popup,
      padding_left = popup.padding,
      padding_right = popup.padding,
    },
  })

  sbar.add("item", "api_usage.minimax", {
    position = "popup.api_usage",
    icon = { drawing = false },
    label = {
      string = string.format(fmt, "MiniMax", "-", "no plan"),
      font = fonts.popup,
      padding_left = popup.padding,
      padding_right = popup.padding,
    },
  })

  local api_openai = sbar.add("item", "api_usage.openai", {
    position = "popup.api_usage",
    icon = { drawing = false },
    label = {
      string = string.format(fmt, "OpenAI", "$0.00", "30d"),
      font = fonts.popup,
      padding_left = popup.padding,
      padding_right = popup.padding,
    },
  })

  sbar.add("item", "api_usage.zai", {
    position = "popup.api_usage",
    icon = { drawing = false },
    label = {
      string = string.format(fmt, "Z.ai", "-", "no bal"),
      font = fonts.popup,
      padding_left = popup.padding,
      padding_right = popup.padding,
    },
  })

  ---
  --- Fetches and updates API usage for all providers.
  --- Retrieves Anthropic and OpenAI costs via their APIs,
  --- and Codex session usage from local JSONL files.
  ---
  ---@return nil
  local function update_api_usage()
    -- Anthropic
    sbar.exec([[
      export OP_SERVICE_ACCOUNT_TOKEN=$(security find-generic-password -a dev-secrets -s OP_SERVICE_ACCOUNT_TOKEN -w 2>/dev/null)
      if [ -z "$OP_SERVICE_ACCOUNT_TOKEN" ]; then echo "0"; exit 0; fi
      KEY=$(op read "op://Models/anthropic/admin-key" 2>/dev/null)
      if [ -z "$KEY" ]; then echo "0"; exit 0; fi
      START=$(date -v-30d -u +%Y-%m-%dT00:00:00Z)
      curl -s "https://api.anthropic.com/v1/organizations/cost_report?starting_at=$START&bucket_width=1d&limit=31" \
        -H "x-api-key: $KEY" \
        -H "anthropic-version: 2023-06-01" \
        -H "Content-Type: application/json" 2>/dev/null \
      | jq '[.data[].amount] | add // 0'
    ]], function(result)
      local cost = tonumber(type(result) == "string" and result:gsub("%s+", "") or "0") or 0
      api_anthropic:set({ label = { string = string.format(fmt, "Anthropic", "$"..string.format("%.2f", cost), "30d") } })
    end)

    -- OpenAI
    sbar.exec([[
      export OP_SERVICE_ACCOUNT_TOKEN=$(security find-generic-password -a dev-secrets -s OP_SERVICE_ACCOUNT_TOKEN -w 2>/dev/null)
      if [ -z "$OP_SERVICE_ACCOUNT_TOKEN" ]; then echo "0"; exit 0; fi
      KEY=$(op read "op://Models/openai/admin-key" 2>/dev/null)
      if [ -z "$KEY" ]; then echo "0"; exit 0; fi
      START=$(date -v-30d +%s)
      END=$(date +%s)
      curl -s "https://api.openai.com/v1/organization/costs?start_time=$START&end_time=$END&bucket_width=1d" \
        -H "Authorization: Bearer $KEY" \
        -H "Content-Type: application/json" 2>/dev/null \
      | jq '[.data[].results[].amount.value] | add // 0'
    ]], function(result)
      local cost = tonumber(type(result) == "string" and result:gsub("%s+", "") or "0") or 0
      api_openai:set({ label = { string = string.format(fmt, "OpenAI", "$"..string.format("%.2f", cost), "30d") } })
    end)

    -- Codex
    sbar.exec([[
      LATEST=$(find ~/.codex/sessions -name "rollout-*.jsonl" -type f 2>/dev/null | sort -r | head -1)
      if [ -z "$LATEST" ]; then echo "0"; exit 0; fi
      grep '"token_count"' "$LATEST" 2>/dev/null | tail -1 | jq -r '.payload.rate_limits.primary.used_percent // 0'
    ]], function(result)
      local pct = tonumber(type(result) == "string" and result:gsub("%s+", "") or "0") or 0
      api_codex:set({ label = { string = string.format(fmt, "Codex", string.format("%.0f%%", pct), "session") } })
    end)

  end

  update_api_usage()
  api_usage:subscribe("routine", update_api_usage)

  api_usage:subscribe("mouse.clicked", function()
    sbar.exec("sketchybar --set apple popup.drawing=off --set docker popup.drawing=off --set releases popup.drawing=off --set wifi popup.drawing=off")
    api_usage:set({ popup = { drawing = "toggle" } })
  end)

  return api_usage
end
