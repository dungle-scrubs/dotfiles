-- wezterm utils

local M = {}

-- Get the filename from a path
M.basename = function(s)
	if not s then
		return
	end

	return string.gsub(s, "(.*[/\\])(.*)", "%2")
end

M.filter = function(tbl, callback)
	local filt_table = {}

	for i, v in ipairs(tbl) do
		if callback(v, i) then
			table.insert(filt_table, v)
		end
	end
	return filt_table
end

M.file_exists = function(name)
	local f = io.open(name, "r")
	if f ~= nil then
		io.close(f)
		return true
	else
		return false
	end
end

--- Check if a file or directory exists in this path
M.exists = function(file)
	local ok, err, code = os.rename(file, file)
	if not ok then
		if code == 13 then
			-- Permission denied, but it exists
			return true
		end
	end
	return ok, err
end

--- Check if a directory exists in this path
M.dir_exists = function(path)
	-- "/" works on both Unix and Windows
	return M.exists(path .. "/")
end

return M
