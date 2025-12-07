--- Attention.spoon/api/calendar.lua
--- Calendar API using EventKit (Swift binary)

local M = {}

-- Store active tasks to prevent garbage collection
M._activeTasks = {}

-- Path to Swift EventKit binary (bundled with spoon)
-- Uses global set by init.lua since hs.spoons.scriptPath() won't work in sub-module
local function getCalendarBin()
	local spoonPath = _G.AttentionSpoonPath or hs.spoons.scriptPath()
	return spoonPath .. "bin/calendar_events"
end

--- Extract meeting URL from location or notes
--- @param text string Location or notes text
--- @return string|nil url Meeting URL if found
local function extractMeetingUrl(text)
	if not text then return nil end
	-- Zoom
	local zoom = text:match("(https://[%w%-]+%.zoom%.us/[^\"%s<>]+)")
	if zoom then return zoom end
	-- Google Meet
	local meet = text:match("(https://meet%.google%.com/[^\"%s<>]+)")
	if meet then return meet end
	-- Microsoft Teams
	local teams = text:match("(https://teams%.microsoft%.com/[^\"%s<>]+)")
	if teams then return teams end
	-- Around
	local around = text:match("(https://[%w%-]+%.around%.co/[^\"%s<>]+)")
	if around then return around end
	-- Generic video call URL
	local generic = text:match("(https://[^\"%s<>]+)")
	if generic and (generic:match("zoom") or generic:match("meet") or generic:match("teams") or generic:match("webex") or generic:match("call")) then
		return generic
	end
	return nil
end

--- Parse icalBuddy output into structured events
--- @param output string Raw output from icalBuddy
--- @return table[] events Array of event objects
local function parseEvents(output)
	local events = {}
	if not output or output == "" then
		return events
	end

	-- Parse line by line
	local currentEvent = nil
	for line in output:gmatch("[^\n]+") do
		-- Event title line starts with bullet
		local title = line:match("^• (.+)$")
		if title then
			if currentEvent then
				-- Extract meeting URL before saving
				currentEvent.meetingUrl = extractMeetingUrl(currentEvent.location)
					or extractMeetingUrl(currentEvent.notes)
				table.insert(events, currentEvent)
			end
			currentEvent = {
				title = title,
				time = "",
				location = nil,
				notes = nil,
				calendar = nil,
				isAllDay = false,
				meetingUrl = nil,
			}
		elseif currentEvent then
			-- Time line (indented, contains date)
			local timeStr = line:match("^%s+(%d%d%d%d%-%d%d%-%d%d.+)$")
			if timeStr then
				currentEvent.time = timeStr
				-- Check if all-day event
				if not timeStr:match("%d%d:%d%d") then
					currentEvent.isAllDay = true
				end
			end
			-- Location line
			local loc = line:match("^%s+location:%s*(.+)$")
			if loc then
				currentEvent.location = loc
			end
			-- Notes line
			local notes = line:match("^%s+notes:%s*(.+)$")
			if notes then
				currentEvent.notes = (currentEvent.notes or "") .. notes
			end
			-- Calendar line
			local cal = line:match("^%s+calendar:%s*(.+)$")
			if cal then
				currentEvent.calendar = cal
			end
		end
	end

	-- Don't forget the last event
	if currentEvent then
		currentEvent.meetingUrl = extractMeetingUrl(currentEvent.location)
			or extractMeetingUrl(currentEvent.notes)
		table.insert(events, currentEvent)
	end

	return events
end

--- Format event time for display
--- @param timeStr string Raw time string from icalBuddy
--- @return string formatted Formatted time like "09:00 - 10:30" or "All day"
local function formatEventTime(timeStr)
	if not timeStr or timeStr == "" then
		return ""
	end

	-- Extract just the time portion
	-- Format: "2025-12-08 at 09:00 - 10:00" or "2025-12-08" (all day)
	local startTime, endTime = timeStr:match("at (%d%d:%d%d)%s*%-?%s*(%d%d:%d%d)?")
	if startTime then
		if endTime then
			return startTime .. " - " .. endTime
		else
			return startTime
		end
	end

	-- All day event
	if timeStr:match("^%d%d%d%d%-%d%d%-%d%d$") then
		return "All day"
	end

	return timeStr
end

--- Fetch today's calendar events
--- @param callback function Callback with (events, error)
function M.fetchTodayEvents(callback)
	-- Check if icalBuddy exists
	if not hs.fs.attributes(ICAL_BUDDY) then
		callback(nil, "icalBuddy not found at " .. ICAL_BUDDY)
		return
	end

	local task = hs.task.new(
		ICAL_BUDDY,
		function(exitCode, stdout, stderr)
			if exitCode ~= 0 then
				callback(nil, "icalBuddy error: " .. (stderr or "unknown"))
				return
			end
			local events = parseEvents(stdout)
			-- Add formatted time to each event
			for _, event in ipairs(events) do
				event.displayTime = formatEventTime(event.time)
			end
			callback(events)
		end,
		{
			"-nc", -- no calendar names in title
			"-nrd", -- no relative dates
			"-ea", -- exclude all-day events from separators
			"-b", "• ", -- bullet prefix
			"-po", "datetime,title,location,notes,calendar", -- property order
			"-df", "%Y-%m-%d", -- date format
			"-tf", "%H:%M", -- time format
			"-iep", "datetime,title,location,notes,calendar", -- include these properties
			"eventsToday",
		}
	)

	if task then
		task:start()
	else
		callback(nil, "Failed to start icalBuddy task")
	end
end

--- Calculate days to look ahead based on day of week
--- On weekends, include Monday; otherwise just tomorrow
--- @return number days Number of days to look ahead
local function getDaysToLookAhead()
	local dayOfWeek = tonumber(os.date("%w")) -- 0 = Sunday, 6 = Saturday
	if dayOfWeek == 6 then -- Saturday: show Sat, Sun, Mon
		return 2
	elseif dayOfWeek == 0 then -- Sunday: show Sun, Mon
		return 1
	else -- Weekday: show today, tomorrow
		return 1
	end
end

--- Fetch upcoming events - currently disabled due to permission issues
--- TODO: Fix calendar access when Hammerspoon spawns subprocesses
--- @param days number|nil Number of days to look ahead (nil = auto based on day of week)
--- @param callback function Callback with (events, error)
function M.fetchUpcomingEvents(days, callback)
	-- Calendar disabled - the Swift binary needs calendar permission
	-- which isn't inherited from Hammerspoon
	callback({})
end

--- Get events grouped by date
--- @param events table[] Array of events
--- @return table grouped Events grouped by date string
function M.groupByDate(events)
	local grouped = {}
	local dateOrder = {}

	for _, event in ipairs(events) do
		local date = event.time:match("^(%d%d%d%d%-%d%d%-%d%d)")
		if date then
			if not grouped[date] then
				grouped[date] = {}
				table.insert(dateOrder, date)
			end
			table.insert(grouped[date], event)
		end
	end

	return grouped, dateOrder
end

--- Format date for display
--- @param dateStr string Date in YYYY-MM-DD format
--- @return string formatted Human-readable date
function M.formatDate(dateStr)
	if not dateStr then
		return ""
	end

	local year, month, day = dateStr:match("(%d%d%d%d)%-(%d%d)%-(%d%d)")
	if not year then
		return dateStr
	end

	local timestamp = os.time({ year = tonumber(year), month = tonumber(month), day = tonumber(day) })
	local today = os.time({ year = tonumber(os.date("%Y")), month = tonumber(os.date("%m")), day = tonumber(os.date("%d")) })
	local tomorrow = today + 86400

	if timestamp == today then
		return "Today"
	elseif timestamp == tomorrow then
		return "Tomorrow"
	else
		return os.date("%a, %b %d", timestamp)
	end
end

return M
