--- Attention.spoon/ui/tokens.lua
--- Reads and caches design tokens from tokens.json
--- Single source of truth for colors, fonts, spacing across Lua and TypeScript

-- Use global path set by init.lua
local spoonPath = _G.AttentionSpoonPath

---@class AttentionTokens
local M = {}

-- Cache for loaded tokens
local _cache = nil

--- Load tokens from JSON file
--- @return table tokens The parsed token structure
local function loadTokens()
	if _cache then
		return _cache
	end

	local path = spoonPath .. "/tokens.json"
	local file = io.open(path, "r")
	if not file then
		print("[Tokens] WARNING: Could not open tokens.json at " .. path)
		return {}
	end

	local content = file:read("*all")
	file:close()

	local tokens = hs.json.decode(content)
	if not tokens then
		print("[Tokens] WARNING: Failed to parse tokens.json")
		return {}
	end

	_cache = tokens
	return tokens
end

--- Get all tokens
--- @return table tokens The full token structure
function M.getAll()
	return loadTokens()
end

--- Get color by path (e.g., "bg.primary", "accent.slack")
--- @param path string Dot-separated path to color
--- @return string|nil color The hex color value
function M.color(path)
	local tokens = loadTokens()
	local colors = tokens.colors or {}
	local parts = {}
	for part in path:gmatch("[^.]+") do
		table.insert(parts, part)
	end

	local current = colors
	for _, part in ipairs(parts) do
		if type(current) == "table" then
			current = current[part]
		else
			return nil
		end
	end

	return current
end

--- Get font configuration
--- @return table fonts Font configuration with mono and sizes
function M.fonts()
	local tokens = loadTokens()
	return tokens.fonts or {}
end

--- Get font family name
--- @return string font The monospace font family name
function M.font()
	local fonts = M.fonts()
	return fonts.mono or "CaskaydiaCove Nerd Font Mono"
end

--- Get font size by name
--- @param name string Size name (xs, sm, base, lg, xl, xxl)
--- @return number size The font size in pixels
function M.fontSize(name)
	local fonts = M.fonts()
	local sizes = fonts.sizes or {}
	return sizes[name] or sizes.base or 14
end

--- Get spacing by name
--- @param name string Spacing name (xs, sm, md, lg, xl)
--- @return number spacing The spacing value in pixels
function M.spacing(name)
	local tokens = loadTokens()
	local spacing = tokens.spacing or {}
	return spacing[name] or 16
end

--- Get border radius by name
--- @param name string Radius name (sm, md, lg)
--- @return number radius The radius value in pixels
function M.radius(name)
	local tokens = loadTokens()
	local radii = tokens.radii or {}
	return radii[name] or 6
end

--- Get dimension by name
--- @param name string Dimension name
--- @return number dimension The dimension value in pixels
function M.dimension(name)
	local tokens = loadTokens()
	local dimensions = tokens.dimensions or {}
	return dimensions[name] or 0
end

--- Get all dimensions
--- @return table dimensions All dimension values
function M.dimensions()
	local tokens = loadTokens()
	return tokens.dimensions or {}
end

--- Get all colors as flat table for CSS generation
--- @return table colors Flattened color table
function M.colors()
	local tokens = loadTokens()
	return tokens.colors or {}
end

--- Clear cached tokens (useful for hot reload during development)
function M.clearCache()
	_cache = nil
end

return M
