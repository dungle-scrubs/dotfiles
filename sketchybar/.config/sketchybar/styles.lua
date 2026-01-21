---
--- Shared Styles Module
--- Contains icons, fonts, popup styles, and helper functions for SketchyBar items.
---

---@class Icons
---@field apple string Apple logo icon
---@field brain string Brain/AI icon
---@field openai string OpenAI icon
---@field terminal string Terminal icon
---@field api string API/network icon
---@field docker string Docker whale icon
---@field wifi string WiFi connected icon
---@field wifi_off string WiFi disconnected icon
---@field vpn string VPN/shield icon
---@field battery string[] Battery level icons (0-100% in 11 steps)
---@field battery_charging string Battery charging icon
---@field volume_high string Volume high icon
---@field volume_mid string Volume medium icon
---@field volume_low string Volume low icon
---@field volume_mute string Volume muted icon

---@class Fonts
---@field text string Regular body text (SF Pro 12pt)
---@field text_semibold string Semibold text (SF Pro Semibold 12pt)
---@field text_heavy string Heavy text (SF Pro Heavy 12pt)
---@field icon string Standard icon font (Hack Nerd 16pt)
---@field icon_small string Small icon font (Hack Nerd 14pt)
---@field label_tiny string Tiny label (SF Pro Semibold 7pt)
---@field label_small string Small label (SF Pro Semibold 9pt)
---@field popup string Popup text (Hack Nerd 11pt)
---@field popup_bold string Popup bold text (Hack Nerd Bold 11pt)

---@class PopupStyles
---@field height integer Minimum row height in pixels
---@field padding integer Horizontal padding in pixels
---@field separator_height integer Separator line height
---@field header_height integer Header row height

---@class Styles
---@field icons Icons Nerd Font icons
---@field fonts Fonts Font definitions
---@field popup PopupStyles Popup dimensions
---@field c fun(color: integer): string Color formatter

---@type Styles
local M = {}

--- Nerd Font icons (Material Design + Font Awesome)
---@type Icons
M.icons = {
  apple = "󰀵",
  brain = "󰠭",
  openai = "󰧑",
  terminal = "",
  api = "󰍛",
  docker = "󰡨",
  wifi = "󰖩",
  wifi_off = "󰖪",
  vpn = "󰦝",
  battery = {
    "󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹",
  },
  battery_charging = "󰂄",
  volume_high = "󰕾",
  volume_mid = "󰖀",
  volume_low = "󰕿",
  volume_mute = "󰝟",
}

--- Font definitions for various UI elements
---@type Fonts
M.fonts = {
  text = "SF Pro:Regular:12.0",
  text_semibold = "SF Pro:Semibold:12.0",
  text_heavy = "SF Pro:Heavy:12.0",
  icon = "Hack Nerd Font:Regular:16.0",
  icon_small = "Hack Nerd Font:Regular:14.0",
  label_tiny = "SF Pro:Semibold:7.0",
  label_small = "SF Pro:Semibold:9.0",
  popup = "Hack Nerd Font:Regular:11.0",
  popup_bold = "Hack Nerd Font:Bold:11.0",
}

--- Popup dimensions and spacing
---@type PopupStyles
M.popup = {
  height = 20,
  padding = 2,
  separator_height = 14,
  header_height = 20,
}

---
--- Formats an integer color value for SketchyBar.
--- Converts 0xAARRGGBB integer to "0xAARRGGBB" string.
---
---@param color integer 32-bit ARGB color value
---@return string Formatted color string for SketchyBar
function M.c(color)
  return string.format("0x%08x", color)
end

return M
