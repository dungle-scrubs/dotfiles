---
--- Catppuccin Macchiato Color Palette
--- All colors are 32-bit ARGB format (0xAARRGGBB) for SketchyBar.
---
--- @see https://github.com/catppuccin/catppuccin
---

---@class ColorPalette
---@field base integer Background color (darkest)
---@field mantle integer Slightly lighter background
---@field crust integer Darkest accent
---@field text integer Primary text color
---@field subtext0 integer Muted text
---@field subtext1 integer More muted text
---@field surface0 integer Surface color for popups
---@field surface1 integer Slightly lighter surface
---@field surface2 integer Lightest surface
---@field overlay0 integer Overlay/disabled color
---@field overlay1 integer Lighter overlay
---@field overlay2 integer Lightest overlay
---@field blue integer Primary accent
---@field lavender integer Secondary accent
---@field sapphire integer Tertiary accent
---@field sky integer Light blue
---@field teal integer Cyan accent
---@field green integer Success/healthy color
---@field yellow integer Warning/charging color
---@field peach integer Highlight color
---@field maroon integer Soft red
---@field red integer Error/critical color
---@field mauve integer Purple accent
---@field pink integer Pink accent
---@field flamingo integer Coral accent
---@field rosewater integer Warm accent
---@field transparent integer Fully transparent

---@type ColorPalette
return {
  -- Backgrounds
  base = 0xff24273a,
  mantle = 0xff1e2030,
  crust = 0xff181926,

  -- Text
  text = 0xffcad3f5,
  subtext0 = 0xffb8c0e0,
  subtext1 = 0xffa5adcb,

  -- Surfaces
  surface0 = 0xff363a4f,
  surface1 = 0xff494d64,
  surface2 = 0xff5b6078,

  -- Overlays
  overlay0 = 0xff6e738d,
  overlay1 = 0xff8087a2,
  overlay2 = 0xff939ab7,

  -- Accent colors
  blue = 0xff8aadf4,
  lavender = 0xffb7bdf8,
  sapphire = 0xff7dc4e4,
  sky = 0xff91d7e3,
  teal = 0xff8bd5ca,
  green = 0xffa6da95,
  yellow = 0xffeed49f,
  peach = 0xfff5a97f,
  maroon = 0xffee99a0,
  red = 0xffed8796,
  mauve = 0xffc6a0f6,
  pink = 0xfff5bde6,
  flamingo = 0xfff0c6c6,
  rosewater = 0xfff4dbd6,

  -- Special
  transparent = 0x00000000,
}
