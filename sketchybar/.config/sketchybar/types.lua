---
--- SketchyBar Type Definitions
--- EmmyLua annotations for SbarLua API.
--- This file uses @meta to indicate it's a type definition file.
---
--- @see https://github.com/FelixKratz/SbarLua
---

---@meta

---@class SbarLua
---@field add fun(type: string, name: string, config?: table): SbarItem Add an item or event
---@field bar fun(config: table): nil Configure the bar appearance
---@field default fun(config: table): nil Set default item properties
---@field exec fun(cmd: string, callback?: fun(result: string)): nil Execute shell command async
---@field event_loop fun(): nil Start the event loop (blocks forever)
---@field remove fun(item: SbarItem): nil Remove an item from the bar

---@class SbarItem
---@field set fun(self: SbarItem, config: table): nil Update item properties
---@field subscribe fun(self: SbarItem, event: string|string[], callback: fun(env?: table)): nil Subscribe to events
---@field query fun(self: SbarItem): table Query current item properties

-- ColorPalette is defined in colors.lua
-- Styles is defined in styles.lua
