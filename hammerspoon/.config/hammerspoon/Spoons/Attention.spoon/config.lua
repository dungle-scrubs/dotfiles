--- Attention.spoon/config.lua
--- Configuration loading and validation

local M = {}

-- Cache for loaded config
local configCache = nil
local configPath = os.getenv("HOME") .. "/.config/hammerspoon/attention-config.lua"

--- Get environment variable from ~/.env/services/.env
--- @param varName string The variable name to look up
--- @return string|nil value The value, or nil if not found
local function getEnvVar(varName)
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

--- Resolve an env var reference from config
--- @param envVarName string The name of the env var (e.g., "SLACK_USER_TOKEN")
--- @return string|nil value The resolved value
function M.resolveEnvVar(envVarName)
	return getEnvVar(envVarName)
end

--- Load config from attention-config.lua
--- @return table|nil config The loaded config, or nil if not found
local function loadConfigFile()
	local f = io.open(configPath, "r")
	if not f then
		return nil
	end
	f:close()

	local success, result = pcall(dofile, configPath)
	if success and type(result) == "table" then
		return result
	else
		print("[Attention] Failed to load config: " .. tostring(result))
		return nil
	end
end

--- Build a legacy fallback config from environment variables
--- @return table config A config object with a single "default" project
local function buildLegacyConfig()
	return {
		projects = {
			{
				id = "default",
				name = "Default",
				color = "#5e6ad2",
				integrations = {
					slack = {
						token_env = "SLACK_USER_TOKEN",
						channels = {},
					},
					linear = {
						api_key_env = "LINEAR_API_KEY",
						team_ids = {},
					},
				},
			},
		},
		calendar = {
			enabled = true,
			calendar_names = {},
		},
	}
end

--- Get the full config (loads from file or builds legacy fallback)
--- @param forceReload boolean|nil Force reload from disk
--- @return table config The configuration object
function M.getConfig(forceReload)
	if configCache and not forceReload then
		return configCache
	end

	local config = loadConfigFile()
	if config then
		print("[Attention] Loaded project config with " .. #config.projects .. " projects")
	else
		config = buildLegacyConfig()
		print("[Attention] Using legacy env-var config (no attention-config.lua found)")
	end

	configCache = config
	return config
end

--- Get a project by ID
--- @param projectId string The project ID
--- @return table|nil project The project config, or nil if not found
function M.getProjectById(projectId)
	local config = M.getConfig()
	for _, project in ipairs(config.projects) do
		if project.id == projectId then
			return project
		end
	end
	return nil
end

--- Get all projects
--- @return table[] projects Array of project configs
function M.getProjects()
	local config = M.getConfig()
	return config.projects or {}
end

--- Get calendar config
--- @return table calendar The calendar configuration
function M.getCalendarConfig()
	local config = M.getConfig()
	return config.calendar or { enabled = true, calendar_names = {} }
end

--- Check if config file exists
--- @return boolean exists True if attention-config.lua exists
function M.hasConfigFile()
	local f = io.open(configPath, "r")
	if f then
		f:close()
		return true
	end
	return false
end

--- Get the config file path
--- @return string path Path to attention-config.lua
function M.getConfigPath()
	return configPath
end

--- Reload config from disk
function M.reload()
	configCache = nil
	return M.getConfig(true)
end

return M
