--- Attention.spoon/utils.lua
--- Utility functions

local M = {}

--- Generate shortcut keys: a-z, then A-Z
--- @param index number The item index (1-52)
--- @return string|nil key The shortcut key, or nil if index > 52
function M.getShortcutKey(index)
	if index <= 26 then
		return string.char(96 + index)
	elseif index <= 52 then
		return string.char(64 + index - 26)
	end
	return nil
end

-------------------------------------------------------------------------------
-- Loading Animator
-------------------------------------------------------------------------------
-- IMPORTANT: Use these functions for ALL loading indicators in the Attention spoon.
-- DO NOT create custom loading animations elsewhere - always use this utility.
--
-- Features:
--   - Fixed-width text (no layout shift during animation)
--   - Smooth braille spinner animation
--   - Consistent look across all loading states
--
-- Usage:
--   -- Start animation (store reference to stop later)
--   self.loadingAnimator = utils.createLoadingAnimator("Loading", function(text)
--       canvas[3].text = text
--   end)
--
--   -- Stop animation when done
--   self.loadingAnimator.stop()
--
--   -- For initial/static text before animation starts
--   canvas[3].text = utils.getLoadingText()
-------------------------------------------------------------------------------

-- Spinner frames - each is a single character, so width never changes
local SPINNER_FRAMES = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

--- Create a loading text animator with spinner.
--- USE THIS FOR ALL LOADING INDICATORS - do not create custom loading animations.
--- @param prefix string The text before spinner (default "Loading")
--- @param onUpdate function Callback called with current text on each tick
--- @param interval number Seconds between updates (default 0.08 for smooth spin)
--- @return table animator Object with :stop() method
function M.createLoadingAnimator(prefix, onUpdate, interval)
	prefix = prefix or "Loading"
	interval = interval or 0.08
	local frame = 0
	local timer = hs.timer.doEvery(interval, function()
		frame = (frame % #SPINNER_FRAMES) + 1
		onUpdate(prefix .. " " .. SPINNER_FRAMES[frame])
	end)
	return {
		stop = function()
			if timer then
				timer:stop()
				timer = nil
			end
		end
	}
end

--- Get the initial loading text (for static display before animation starts).
--- USE THIS when setting initial text before calling createLoadingAnimator.
--- @param prefix string The text before spinner (default "Loading")
--- @return string text The initial loading text with spinner
function M.getLoadingText(prefix)
	return (prefix or "Loading") .. " " .. SPINNER_FRAMES[1]
end

--- Get environment variable from ~/.env/ files
--- Checks services/.env first, then models/.env
--- @param varName string The variable name to look up
--- @return string|nil value The value, or nil if not found
function M.getEnvVar(varName)
	local home = os.getenv("HOME")
	local envFiles = {
		home .. "/.env/services/.env",
		home .. "/.env/models/.env",
	}

	for _, envFile in ipairs(envFiles) do
		local output, status = hs.execute("grep '^" .. varName .. "=' " .. envFile .. " 2>/dev/null | cut -d= -f2-")
		if status and output and #output > 0 then
			local value = output:gsub("^%s+", ""):gsub("%s+$", "")
			value = value:gsub('^"', ""):gsub('"$', ""):gsub("^'", ""):gsub("'$", "")
			if #value > 0 then
				return value
			end
		end
	end
	return nil
end

return M
