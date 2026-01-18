local M = {}

---Extracts the filename from a path
---@param s string|nil
---@return string|nil
function M.basename(s)
	if not s then
		return nil
	end
	return string.gsub(s, "(.*[/\\])(.*)", "%2")
end

---Filters a table by a predicate function
---@param tbl table
---@param callback fun(value: any, index: number): boolean
---@return table
function M.filter(tbl, callback)
	local result = {}
	for i, v in ipairs(tbl) do
		if callback(v, i) then
			table.insert(result, v)
		end
	end
	return result
end

---Checks if a file exists and is readable
---@param name string
---@return boolean
function M.file_exists(name)
	local f = io.open(name, "r")
	if f then
		io.close(f)
		return true
	end
	return false
end

---Checks if a file or directory exists at the given path
---@param file string
---@return boolean
---@return string|nil error
function M.exists(file)
	local ok, err, code = os.rename(file, file)
	if not ok and code == 13 then
		return true, nil
	end
	return ok or false, err
end

---Checks if a directory exists at the given path
---@param path string
---@return boolean
function M.dir_exists(path)
	return M.exists(path .. "/")
end

---Lists files in a directory as selector choices
---@param path string
---@return table[] choices Array of {label, id} tables
function M.get_files_in_directory(path)
	local files = {}
	local pfile = io.popen('ls -1 "' .. path .. '"')
	if not pfile then
		Wezterm.log_error("get_files_in_directory: failed to list " .. path)
		return {}
	end

	for filename in pfile:lines() do
		table.insert(files, {
			label = filename,
			id = path .. "/" .. filename,
		})
	end

	pfile:close()
	return files
end

return M
