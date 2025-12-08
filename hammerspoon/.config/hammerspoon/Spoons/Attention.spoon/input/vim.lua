--- Attention.spoon/input/vim.lua
--- Shared vim-style navigation and scroll helpers

---@class AttentionVimHelpers
local M = {}

-- Key codes for common keys
M.keyCodes = {
	escape = 53,
	enter = 36,
	backspace = 51,
	space = 49,
	tab = 48,
	j = 38,
	k = 40,
	h = 4,
	l = 37,
	g = 5,
	d = 2,
	u = 32,
	b = 11,
	s = 1,
	o = 31,
	f = 3,
}

-- Scroll amounts
M.scrollLine = 60
M.scrollPage = 0.8 -- multiplier of view height

--- Check if key matches a vim scroll down command
--- @param keyCode number The key code
--- @param mods table The modifier flags
--- @return boolean
function M.isScrollDown(keyCode, mods)
	-- j or Ctrl+d
	return keyCode == M.keyCodes.j or (mods.ctrl and keyCode == M.keyCodes.d)
end

--- Check if key matches a vim scroll up command
--- @param keyCode number The key code
--- @param mods table The modifier flags
--- @return boolean
function M.isScrollUp(keyCode, mods)
	-- k or Ctrl+u
	return keyCode == M.keyCodes.k or (mods.ctrl and keyCode == M.keyCodes.u)
end

--- Calculate scroll offset for line scroll
--- @param currentOffset number Current scroll offset
--- @param direction number 1 for down, -1 for up
--- @param maxScroll number Maximum scroll offset
--- @return number newOffset The new scroll offset
function M.scrollByLine(currentOffset, direction, maxScroll)
	local newOffset = currentOffset + (direction * M.scrollLine)
	return math.max(0, math.min(newOffset, maxScroll))
end

--- Calculate scroll offset for page scroll
--- @param currentOffset number Current scroll offset
--- @param direction number 1 for down, -1 for up
--- @param viewHeight number Height of the visible area
--- @param maxScroll number Maximum scroll offset
--- @return number newOffset The new scroll offset
function M.scrollByPage(currentOffset, direction, viewHeight, maxScroll)
	local pageAmount = viewHeight * M.scrollPage
	local newOffset = currentOffset + (direction * pageAmount)
	return math.max(0, math.min(newOffset, maxScroll))
end

--- Count modifier keys pressed
--- @param mods table The modifier flags
--- @return number count Number of modifiers pressed
function M.modifierCount(mods)
	local count = 0
	if mods.ctrl then count = count + 1 end
	if mods.alt then count = count + 1 end
	if mods.shift then count = count + 1 end
	if mods.cmd then count = count + 1 end
	return count
end

--- Check if modifiers represent a system-level hotkey (meh, hyper)
--- @param mods table The modifier flags
--- @return boolean
function M.isSystemHotkey(mods)
	return M.modifierCount(mods) >= 3
end

--- Check if no modifiers are pressed (except optionally shift)
--- @param mods table The modifier flags
--- @param allowShift boolean Whether shift is allowed
--- @return boolean
function M.noModifiers(mods, allowShift)
	if mods.cmd or mods.ctrl or mods.alt then
		return false
	end
	if not allowShift and mods.shift then
		return false
	end
	return true
end

--- Check if character is printable (for typing)
--- @param char string The character
--- @return boolean
function M.isPrintable(char)
	if not char or #char ~= 1 then
		return false
	end
	local charCode = char:byte()
	return charCode >= 32 and charCode <= 126
end

--- Check if character is alphanumeric
--- @param char string The character
--- @return boolean
function M.isAlphaNumeric(char)
	if not char or #char ~= 1 then
		return false
	end
	return char:match("^[a-zA-Z0-9]$") ~= nil
end

--- Check if character is lowercase letter
--- @param char string The character
--- @return boolean
function M.isLowercase(char)
	if not char or #char ~= 1 then
		return false
	end
	return char:match("^[a-z]$") ~= nil
end

--- Fuzzy match for search
--- @param text string The text to search in
--- @param query string The search query
--- @return boolean
function M.fuzzyMatch(text, query)
	if not query or query == "" then return true end
	local lowerText = text:lower()
	local lowerQuery = query:lower()
	local queryIndex = 1
	for i = 1, #lowerText do
		if lowerText:sub(i, i) == lowerQuery:sub(queryIndex, queryIndex) then
			queryIndex = queryIndex + 1
		end
		if queryIndex > #lowerQuery then
			return true
		end
	end
	return false
end

return M
