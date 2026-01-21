---
--- WiFi Status Item
--- Displays WiFi icon with popup showing SSID and IP address.
--- Shows VPN icon when tunnel interface detected.
---

---
--- Creates the WiFi status bar item with popup.
---
---@param sbar SbarLua SketchyBar Lua API instance
---@param colors ColorPalette Color palette table
---@param styles Styles Shared styles (icons, fonts, popup settings)
---@param close_popups function Callback to close all popups
---@return SbarItem The created WiFi item
return function(sbar, colors, styles, close_popups)
  local icons = styles.icons
  local fonts = styles.fonts
  local popup = styles.popup
  local c = styles.c

  ---@type SbarItem
  local wifi = sbar.add("item", "wifi", {
    position = "right",
    update_freq = 30,
    icon = { string = icons.wifi, font = fonts.icon_small, color = c(colors.blue) },
    label = { drawing = false },
    popup = {
      align = "right",
      height = popup.height,
      background = {
        color = c(colors.surface0),
        border_width = 2,
        corner_radius = 9,
        border_color = c(colors.blue),
      },
    },
  })

  ---@type SbarItem
  local wifi_ssid = sbar.add("item", "wifi.ssid", {
    position = "popup.wifi",
    icon = { drawing = false },
    label = {
      string = "Network: --",
      font = fonts.popup,
      padding_left = popup.padding,
      padding_right = popup.padding,
    },
  })

  ---@type SbarItem
  local wifi_ip = sbar.add("item", "wifi.ip", {
    position = "popup.wifi",
    icon = { drawing = false },
    label = {
      string = "IP: --",
      font = fonts.popup,
      padding_left = popup.padding,
      padding_right = popup.padding,
    },
  })

  -- Register for network change events
  sbar.add("event", "wifi_change", "com.apple.system.config.network_change")

  ---
  --- Fetches and updates WiFi status (IP, SSID, VPN).
  --- Uses nested async callbacks to gather network info.
  ---
  ---@return nil
  local function update_wifi()
    -- Get IP address
    sbar.exec("scutil --nwi | grep address | head -1 | awk -F: '{print $2}' | tr -d ' '", function(ip)
      ip = type(ip) == "string" and ip:gsub("%s+", "") or ""

      -- Get SSID from system_profiler
      sbar.exec("system_profiler SPAirPortDataType 2>/dev/null | awk '/Current Network Information:/{getline; gsub(/^[ ]+|:$/,\"\"); print; exit}'", function(ssid_result)
        local ssid = type(ssid_result) == "string" and ssid_result:gsub("%s+$", "") or ""

        -- Check for VPN tunnel interface
        sbar.exec("scutil --nwi | grep -m1 utun || true", function(vpn)
          vpn = type(vpn) == "string" and vpn or ""

          local icon, icon_color
          if vpn:find("utun") then
            icon = icons.vpn
            icon_color = c(colors.green)
            wifi_ssid:set({ label = { string = "VPN Active" } })
          elseif ip ~= "" then
            icon = icons.wifi
            icon_color = c(colors.blue)
            wifi_ssid:set({ label = { string = ssid ~= "" and ssid or "Connected" } })
          else
            icon = icons.wifi_off
            icon_color = c(colors.overlay0)
            wifi_ssid:set({ label = { string = "Disconnected" } })
          end

          wifi:set({ icon = { string = icon, color = icon_color } })
          wifi_ip:set({ label = { string = ip ~= "" and ip or "No IP" } })
        end)
      end)
    end)
  end

  -- Initial update and subscribe to events
  update_wifi()
  wifi:subscribe({ "routine", "wifi_change" }, update_wifi)

  --- Toggles popup, closing other popups first
  wifi:subscribe("mouse.clicked", function()
    sbar.exec("sketchybar --set apple popup.drawing=off --set api_usage popup.drawing=off --set docker popup.drawing=off --set releases popup.drawing=off")
    wifi:set({ popup = { drawing = "toggle" } })
  end)

  return wifi
end
