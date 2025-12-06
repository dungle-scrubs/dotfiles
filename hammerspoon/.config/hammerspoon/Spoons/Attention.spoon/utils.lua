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

--- Get environment variable from ~/.env/services/.env
--- @param varName string The variable name to look up
--- @return string|nil value The value, or nil if not found
function M.getEnvVar(varName)
	local envFile = os.getenv("HOME") .. "/.env/services/.env"
	local output, status = hs.execute("grep '^" .. varName .. "=' " .. envFile .. " | cut -d= -f2-")
	if status and output and #output > 0 then
		local value = output:gsub("^%s+", ""):gsub("%s+$", "")
		value = value:gsub('^"', ""):gsub('"$', ""):gsub("^'", ""):gsub("'$", "")
		if #value > 0 then
			return value
		end
	end
	return nil
end

return M
