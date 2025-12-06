require("hs.ipc")
hs.loadSpoon("EmmyLua")

----------------------------------------------------------------------------------------------------
-- Custom Alert Style
----------------------------------------------------------------------------------------------------

hs.alert.defaultStyle.fillColor = { hex = "#1a1a1a", alpha = 0.95 }
hs.alert.defaultStyle.strokeColor = { hex = "#3b82f6", alpha = 0.9 }
hs.alert.defaultStyle.strokeWidth = 2
hs.alert.defaultStyle.textColor = { hex = "#f97316", alpha = 1 }
hs.alert.defaultStyle.textFont = "CaskaydiaCove Nerd Font Mono"
hs.alert.defaultStyle.textSize = 16
hs.alert.defaultStyle.radius = 8
hs.alert.defaultStyle.atScreenEdge = 0  -- center of screen
hs.alert.defaultStyle.fadeInDuration = 0.1
hs.alert.defaultStyle.fadeOutDuration = 0.2

----------------------------------------------------------------------------------------------------
-- AeroSpace Service Mode Overlay
----------------------------------------------------------------------------------------------------

local aerospaceOverlay = {}
aerospaceOverlay.canvas = nil
aerospaceOverlay.visible = false

-- Format modifier keys for display
local function formatKey(keyStr)
	local result = keyStr
	result = result:gsub("alt%-shift%-", "⌥⇧")
	result = result:gsub("shift%-ctrl%-alt%-", "⌃⌥⇧")
	result = result:gsub("ctrl%-alt%-", "⌃⌥")
	result = result:gsub("alt%-", "⌥")
	result = result:gsub("shift%-", "⇧")
	result = result:gsub("ctrl%-", "⌃")
	result = result:gsub("cmd%-", "⌘")
	result = result:gsub("backspace", "⌫")
	result = result:gsub("esc", "Esc")
	result = result:gsub("semicolon", ";")
	result = result:gsub("comma", ",")
	result = result:gsub("slash", "/")
	return result
end

-- Shorten command for display
local function formatCommand(cmd)
	if cmd == "" then
		return "(disabled)"
	end
	-- Remove "mode main" suffix for cleaner display
	cmd = cmd:gsub("; mode main$", "")
	cmd = cmd:gsub(",mode main%]$", "]")
	-- Shorten common commands
	cmd = cmd:gsub("flatten%-workspace%-tree", "flatten")
	cmd = cmd:gsub("close%-all%-windows%-but%-current", "close others")
	cmd = cmd:gsub("layout floating tiling", "toggle float")
	cmd = cmd:gsub("reload%-config", "reload")
	cmd = cmd:gsub("join%-with ", "join ")
	cmd = cmd:gsub("enable toggle", "toggle enable")
	return cmd
end

-- Categorize a binding into a group
local function categorizeBinding(key, cmd)
	-- Directional commands
	if cmd:match("^move ") or cmd:match("^join%-with ") or cmd:match("^focus ") then
		return "directional"
	end
	-- Layout commands
	if cmd:match("^layout ") or cmd:match("fullscreen") then
		return "layout"
	end
	-- Exit/mode commands
	if cmd:match("mode main") and (key == "esc" or cmd:match("reload")) then
		return "exit"
	end
	-- Everything else is actions
	return "actions"
end

function aerospaceOverlay.show(mode)
	mode = mode or "service"

	-- Get bindings from aerospace
	local output, status = hs.execute("/opt/homebrew/bin/aerospace config --get mode." .. mode .. ".binding --json")
	if not status then
		print("Failed to get aerospace bindings")
		return
	end

	local bindings = hs.json.decode(output)
	if not bindings then
		print("Failed to parse aerospace bindings")
		return
	end

	-- Group bindings by category
	local groups = {
		{ name = "Movement", key = "directional", items = {} },
		{ name = "Layout", key = "layout", items = {} },
		{ name = "Actions", key = "actions", items = {} },
		{ name = "Exit", key = "exit", items = {} },
	}
	local groupMap = {}
	for _, g in ipairs(groups) do
		groupMap[g.key] = g.items
	end

	for key, cmd in pairs(bindings) do
		local category = categorizeBinding(key, cmd)
		table.insert(groupMap[category], { key = key, cmd = cmd })
	end

	-- Sort items within each group
	for _, g in ipairs(groups) do
		table.sort(g.items, function(a, b)
			return a.key < b.key
		end)
	end

	-- Calculate dimensions
	local font = "CaskaydiaCove Nerd Font Mono"
	local fontSize = 14
	local lineHeight = fontSize + 6
	local groupHeaderHeight = fontSize + 10
	local padding = 12
	local titleHeight = 24
	local groupSpacing = 8

	-- Count total lines needed (items + group headers + spacing)
	local totalLines = 0
	local numGroups = 0
	for _, g in ipairs(groups) do
		if #g.items > 0 then
			numGroups = numGroups + 1
			totalLines = totalLines + #g.items
		end
	end

	local contentHeight = titleHeight + (totalLines * lineHeight) + (numGroups * (groupHeaderHeight + groupSpacing)) + (padding * 2)
	local boxWidth = 320

	-- Get screen dimensions
	local screen = hs.screen.mainScreen()
	local frame = screen:frame()

	-- Position at bottom-right
	local boxX = frame.x + frame.w - boxWidth - 20
	local boxY = frame.y + frame.h - contentHeight - 20

	-- Create or reuse canvas
	if aerospaceOverlay.canvas then
		aerospaceOverlay.canvas:delete()
	end

	aerospaceOverlay.canvas = hs.canvas.new({ x = boxX, y = boxY, w = boxWidth, h = contentHeight })
	local c = aerospaceOverlay.canvas

	-- Background
	c[1] = {
		type = "rectangle",
		action = "fill",
		fillColor = { hex = "#1a1a1a", alpha = 0.95 },
		roundedRectRadii = { xRadius = 8, yRadius = 8 },
	}

	-- Border
	c[2] = {
		type = "rectangle",
		action = "stroke",
		strokeColor = { hex = "#00ff00", alpha = 0.8 },
		strokeWidth = 2,
		roundedRectRadii = { xRadius = 8, yRadius = 8 },
	}

	-- Title
	c[3] = {
		type = "text",
		text = "AeroSpace",
		textFont = font,
		textSize = fontSize + 2,
		textColor = { hex = "#00ff00", alpha = 1 },
		textAlignment = "center",
		frame = { x = padding, y = padding, w = boxWidth - (padding * 2), h = titleHeight },
	}

	-- Separator line
	c[4] = {
		type = "rectangle",
		action = "fill",
		fillColor = { hex = "#444444", alpha = 1 },
		frame = { x = padding, y = padding + titleHeight, w = boxWidth - (padding * 2), h = 1 },
	}

	-- Render grouped items
	local yPos = padding + titleHeight + 8

	for _, group in ipairs(groups) do
		if #group.items > 0 then
			-- Group header
			c[#c + 1] = {
				type = "text",
				text = group.name,
				textFont = font,
				textSize = fontSize - 1,
				textColor = { hex = "#888888", alpha = 1 },
				textAlignment = "left",
				frame = { x = padding, y = yPos, w = boxWidth - (padding * 2), h = groupHeaderHeight },
			}
			yPos = yPos + groupHeaderHeight

			-- Group items
			for _, item in ipairs(group.items) do
				local keyDisplay = formatKey(item.key)
				local cmdDisplay = formatCommand(item.cmd)

				-- Key
				c[#c + 1] = {
					type = "text",
					text = keyDisplay,
					textFont = font,
					textSize = fontSize,
					textColor = { hex = "#ffcc00", alpha = 1 },
					textAlignment = "left",
					frame = { x = padding + 8, y = yPos, w = 80, h = lineHeight },
				}

				-- Command
				c[#c + 1] = {
					type = "text",
					text = cmdDisplay,
					textFont = font,
					textSize = fontSize,
					textColor = { hex = "#aaaaaa", alpha = 1 },
					textAlignment = "left",
					frame = { x = padding + 93, y = yPos, w = boxWidth - padding - 98, h = lineHeight },
				}

				yPos = yPos + lineHeight
			end

			yPos = yPos + groupSpacing
		end
	end

	c:level(hs.canvas.windowLevels.overlay)
	c:show()
	aerospaceOverlay.visible = true
end

function aerospaceOverlay.hide()
	if aerospaceOverlay.canvas then
		aerospaceOverlay.canvas:hide()
		aerospaceOverlay.visible = false
	end
end

function aerospaceOverlay.toggle(mode)
	if aerospaceOverlay.visible then
		aerospaceOverlay.hide()
	else
		aerospaceOverlay.show(mode)
	end
end

-- Expose globally so aerospace can call it via hs CLI
_G.aerospaceOverlay = aerospaceOverlay

----------------------------------------------------------------------------------------------------
-- Arc Browser Space Control
----------------------------------------------------------------------------------------------------

local arcBrowser = {}

-- Get list of Arc spaces
function arcBrowser.getSpaces()
	local script = [[
		set _output to "["
		tell application "Arc"
			set _space_index to 1
			repeat with _space in spaces of front window
				set _title to get title of _space
				set _output to (_output & "{ \"title\": \"" & _title & "\", \"id\": " & _space_index & " }")
				if _space_index < (count spaces of front window) then
					set _output to (_output & ", ")
				end if
				set _space_index to _space_index + 1
			end repeat
		end tell
		set _output to (_output & "]")
		return _output
	]]
	local ok, result = hs.osascript.applescript(script)
	if ok then
		return hs.json.decode(result)
	end
	return nil
end

-- Select Arc space by ID (1-indexed)
function arcBrowser.selectSpace(id)
	local script = string.format([[
		tell application "Arc"
			activate
			tell front window
				tell space %d to focus
			end tell
		end tell
	]], id)
	hs.osascript.applescript(script)
end

-- Select Arc space by name
function arcBrowser.selectSpaceByName(name)
	local spaces = arcBrowser.getSpaces()
	if spaces then
		for _, space in ipairs(spaces) do
			if space.title == name then
				arcBrowser.selectSpace(space.id)
				return true
			end
		end
	end
	return false
end

-- Open Arc to a specific space, optionally on an AeroSpace workspace
function arcBrowser.openToSpace(spaceName, workspace)
	local function selectSpace()
		-- Let AppleScript handle the waiting internally
		local script = [[
			tell application "Arc"
				activate
				-- Wait for window to be available
				set _maxWait to 50
				set _waited to 0
				repeat while (count of windows) < 1 and _waited < _maxWait
					delay 0.05
					set _waited to _waited + 1
				end repeat

				if (count of windows) > 0 then
					set _space_index to 1
					repeat with _space in spaces of front window
						if title of _space is "]] .. spaceName .. [[" then
							tell front window
								tell space _space_index to focus
							end tell
							exit repeat
						end if
						set _space_index to _space_index + 1
					end repeat
				end if
			end tell
		]]
		hs.task.new("/usr/bin/osascript", nil, { "-e", script }):start()
	end

	-- Check if AeroSpace is available and switch workspace first
	if workspace then
		hs.task.new("/opt/homebrew/bin/aerospace", function(exitCode)
			if exitCode == 0 then
				hs.task.new("/opt/homebrew/bin/aerospace", function()
					hs.timer.doAfter(0.1, selectSpace)
				end, { "workspace", workspace }):start()
			else
				selectSpace()
			end
		end, { "list-workspaces", "--all" }):start()
	else
		selectSpace()
	end
end

-- Expose globally
_G.arcBrowser = arcBrowser

----------------------------------------------------------------------------------------------------
-- Project Launcher
----------------------------------------------------------------------------------------------------

local projectLauncher = {}

-- Launch app, wait for it to appear, then move to workspace
local function launchAndMove(launchFn, appName, workspace, callback)
	-- Launch the app
	launchFn()

	-- Wait for app to be running and have a window, then move it
	local attempts = 0
	local maxAttempts = 20
	local checkTimer
	checkTimer = hs.timer.doEvery(0.5, function()
		attempts = attempts + 1
		local app = hs.application.get(appName)
		if app and #app:allWindows() > 0 then
			checkTimer:stop()
			-- Move the focused window to the target workspace
			hs.task.new("/opt/homebrew/bin/aerospace", function()
				if callback then callback() end
			end, { "move-node-to-workspace", workspace }):start()
		elseif attempts >= maxAttempts then
			checkTimer:stop()
			hs.alert.show("Timeout waiting for " .. appName)
			if callback then callback() end
		end
	end)
end

-- Open a full project environment
-- config = {
--   name = "Project Name",
--   wezterm = { dir = "~/path", workspace = "T" },
--   arc = { space = "SpaceName", workspace = "B" },
--   windsurf = { dir = "~/path", workspace = "X" },
--   orbstack = { workspace = "D" },
-- }
function projectLauncher.open(config)
	local steps = {}
	local projectName = config.name or "Project"

	if config.wezterm then
		table.insert(steps, function(next)
			local dir = config.wezterm.dir:gsub("^~", os.getenv("HOME"))
			launchAndMove(
				function()
					hs.task.new("/opt/homebrew/bin/wezterm", nil, { "start", "--cwd", dir }):start()
				end,
				"WezTerm",
				config.wezterm.workspace,
				next
			)
		end)
	end

	if config.arc then
		table.insert(steps, function(next)
			local space = config.arc.space
			launchAndMove(
				function()
					local script = [[
						tell application "Arc"
							activate
							delay 0.5
							if (count of windows) > 0 then
								set _space_index to 1
								repeat with _space in spaces of front window
									if title of _space is "]] .. space .. [[" then
										tell front window to tell space _space_index to focus
										exit repeat
									end if
									set _space_index to _space_index + 1
								end repeat
							end if
						end tell
					]]
					hs.task.new("/usr/bin/osascript", nil, { "-e", script }):start()
				end,
				"Arc",
				config.arc.workspace,
				next
			)
		end)
	end

	if config.windsurf then
		table.insert(steps, function(next)
			local dir = config.windsurf.dir:gsub("^~", os.getenv("HOME"))
			launchAndMove(
				function()
					hs.task.new("/Applications/Windsurf.app/Contents/Resources/app/bin/windsurf", nil, { dir }):start()
				end,
				"Windsurf",
				config.windsurf.workspace,
				next
			)
		end)
	end

	if config.orbstack then
		table.insert(steps, function(next)
			launchAndMove(
				function()
					hs.application.launchOrFocus("OrbStack")
				end,
				"OrbStack",
				config.orbstack.workspace,
				next
			)
		end)
	end

	-- Run steps sequentially, then finalize
	local function runStep(i)
		if i <= #steps then
			steps[i](function() runStep(i + 1) end)
		else
			-- All done - show message, switch to T, focus WezTerm
			hs.alert.show(projectName .. " loaded")
			hs.task.new("/opt/homebrew/bin/aerospace", function()
				local wezterm = hs.application.get("WezTerm")
				if wezterm then
					wezterm:activate()
				end
			end, { "workspace", "T" }):start()
		end
	end
	runStep(1)
end

-- Expose globally
_G.projectLauncher = projectLauncher

----------------------------------------------------------------------------------------------------
-- Task Runner with Canvas Output
----------------------------------------------------------------------------------------------------

local taskRunner = {}
taskRunner.canvas = nil
taskRunner.task = nil
taskRunner.output = {}
taskRunner.maxLines = 30

function taskRunner.show(title)
	local screen = hs.screen.mainScreen()
	local frame = screen:frame()

	local width = 780
	local height = 520
	local x = frame.x + (frame.w - width) / 2
	local y = frame.y + (frame.h - height) / 2

	if taskRunner.canvas then
		taskRunner.canvas:delete()
	end

	taskRunner.output = {}
	taskRunner.canvas = hs.canvas.new({ x = x, y = y, w = width, h = height })
	local c = taskRunner.canvas

	-- Background
	c[1] = {
		type = "rectangle",
		action = "fill",
		fillColor = { hex = "#1a1a1a", alpha = 0.95 },
		roundedRectRadii = { xRadius = 8, yRadius = 8 },
	}

	-- Border
	c[2] = {
		type = "rectangle",
		action = "stroke",
		strokeColor = { hex = "#3b82f6", alpha = 0.9 },
		strokeWidth = 2,
		roundedRectRadii = { xRadius = 8, yRadius = 8 },
	}

	-- Title
	c[3] = {
		type = "text",
		text = title or "Running...",
		textFont = "CaskaydiaCove Nerd Font Mono",
		textSize = 14,
		textColor = { hex = "#3b82f6", alpha = 1 },
		textAlignment = "center",
		frame = { x = 12, y = 8, w = width - 24, h = 24 },
	}

	-- Output area (will be updated)
	c[4] = {
		type = "text",
		text = "",
		textFont = "CaskaydiaCove Nerd Font Mono",
		textSize = 11,
		textColor = { hex = "#aaaaaa", alpha = 1 },
		textAlignment = "left",
		frame = { x = 12, y = 36, w = width - 24, h = height - 48 },
	}

	c:level(hs.canvas.windowLevels.modalPanel)
	c:show()
end

function taskRunner.appendOutput(text)
	if not taskRunner.canvas then return end

	-- Split text into lines and add to output buffer
	for line in text:gmatch("[^\r\n]+") do
		table.insert(taskRunner.output, line)
	end

	-- Keep only last N lines
	while #taskRunner.output > taskRunner.maxLines do
		table.remove(taskRunner.output, 1)
	end

	-- Update canvas
	taskRunner.canvas[4].text = table.concat(taskRunner.output, "\n")
end

function taskRunner.hide()
	if taskRunner.canvas then
		taskRunner.canvas:delete()
		taskRunner.canvas = nil
	end
end

function taskRunner.run(title, command, args, onComplete)
	taskRunner.show(title)

	local function streamCallback(task, stdOut, stdErr)
		if stdOut and #stdOut > 0 then
			taskRunner.appendOutput(stdOut)
		end
		if stdErr and #stdErr > 0 then
			taskRunner.appendOutput(stdErr)
		end
		return true -- keep streaming
	end

	local function exitCallback(exitCode, stdOut, stdErr)
		if exitCode == 0 then
			taskRunner.appendOutput("\n✓ Done")
		else
			taskRunner.appendOutput("\n✗ Failed (exit " .. exitCode .. ")")
		end

		-- Auto-close after delay
		hs.timer.doAfter(2, function()
			taskRunner.hide()
			if onComplete then onComplete(exitCode) end
		end)
	end

	taskRunner.task = hs.task.new(command, exitCallback, streamCallback, args)
	taskRunner.task:start()
end

-- Run startup maintenance (docker cleanup + brew upgrade) in one canvas
function taskRunner.startupMaintenance()
	taskRunner.run(
		"Startup Maintenance",
		"/bin/bash",
		{ "-c", "/usr/local/bin/docker system prune --volumes -f && /opt/homebrew/bin/brew update && /opt/homebrew/bin/brew upgrade" }
	)
end

-- Expose globally
_G.taskRunner = taskRunner

----------------------------------------------------------------------------------------------------
-- Attention Dashboard (Linear + Slack)
----------------------------------------------------------------------------------------------------

local attention = {}
attention.canvas = nil
attention.visible = false
attention.cache = { linear = nil, slack = nil }
attention.lastFetchDate = nil
attention.dailyTimer = nil
attention.clickableItems = {}
attention.currentView = "main" -- "main", "linear-detail", or "slack-detail"
attention.canvasFrame = nil
attention.hoveredIndex = nil
attention.hoverWatcher = nil
attention.lastCanvasSize = nil -- Remember size for loader
attention.selectedIndex = nil -- For keyboard navigation
attention.keyMap = {} -- Maps keys to item indices
attention.loadingTimer = nil
attention.loadingDots = 0
attention.scrollOffset = 0
attention.currentIssue = nil -- Store current issue for re-rendering on scroll
attention.currentSlackMsg = nil -- Store current Slack message for re-rendering on scroll
attention.currentSlackThread = nil -- Store thread replies
attention.currentSlackChannel = nil -- Store channel ID for "up" navigation
attention.slackViewMode = "thread" -- "thread" or "history" (for DMs)
attention.webview = nil -- Webview for Slack detail
attention.slackOldestTs = nil -- Oldest message timestamp for pagination
attention.slackThreadTs = nil -- Thread parent timestamp for pagination

-- Cursor change via NSCursor doesn't work reliably from Hammerspoon
local function setHandCursor() end
local function resetCursor() end

-- Generate shortcut keys: a-z, then A-Z
local function getShortcutKey(index)
	if index <= 26 then
		return string.char(96 + index) -- a-z
	elseif index <= 52 then
		return string.char(64 + index - 26) -- A-Z
	end
	return nil
end

-- Helper to get env var from ~/.env/services/.env
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

-- Fetch Linear in-progress issues
local function fetchLinear(callback)
	local apiKey = getEnvVar("LINEAR_API_KEY")
	if not apiKey then
		callback(nil, "LINEAR_API_KEY not found")
		return
	end

	local query = [[
		query InProgressIssues {
			issues(filter: { state: { type: { eq: "started" } } }, first: 20) {
				nodes {
					identifier
					title
					project { name }
				}
			}
		}
	]]

	hs.http.asyncPost(
		"https://api.linear.app/graphql",
		hs.json.encode({ query = query }),
		{ ["Authorization"] = apiKey, ["Content-Type"] = "application/json" },
		function(status, response)
			if status ~= 200 then
				callback(nil, "Linear API error: " .. tostring(status))
				return
			end
			local data = hs.json.decode(response)
			if data and data.data and data.data.issues then
				callback(data.data.issues.nodes)
			else
				callback(nil, "Failed to parse Linear response")
			end
		end
	)
end

-- Fetch Linear issue details
local function fetchLinearDetail(identifier, callback)
	local apiKey = getEnvVar("LINEAR_API_KEY")
	if not apiKey then
		callback(nil, "LINEAR_API_KEY not found")
		return
	end

	local query = [[
		query IssueDetail($id: String!) {
			issue(id: $id) {
				identifier
				title
				description
				state { name }
				priority
				project { name }
				url
				comments(first: 10) {
					nodes {
						body
						user { name }
						createdAt
					}
				}
			}
		}
	]]

	hs.http.asyncPost(
		"https://api.linear.app/graphql",
		hs.json.encode({ query = query, variables = { id = identifier } }),
		{ ["Authorization"] = apiKey, ["Content-Type"] = "application/json" },
		function(status, response)
			if status ~= 200 then
				callback(nil, "Linear API error: " .. tostring(status))
				return
			end
			local data = hs.json.decode(response)
			if data and data.data and data.data.issue then
				callback(data.data.issue)
			else
				callback(nil, "Failed to parse Linear issue")
			end
		end
	)
end

-- Fetch Slack mentions and DMs
local function fetchSlack(callback)
	local token = getEnvVar("SLACK_USER_TOKEN")
	if not token then
		callback(nil, "SLACK_USER_TOKEN not found")
		return
	end

	-- First get user ID for @mention search
	hs.http.asyncGet(
		"https://slack.com/api/auth.test",
		{ ["Authorization"] = "Bearer " .. token },
		function(status, response)
			if status ~= 200 then
				callback(nil, "Slack auth error")
				return
			end
			local authData = hs.json.decode(response)
			if not authData or not authData.user_id then
				callback(nil, "Failed to get Slack user ID")
				return
			end

			local userId = authData.user_id
			local results = { dms = {}, channels = {} }
			local pending = 2

			local function checkDone()
				pending = pending - 1
				if pending == 0 then
					callback(results)
				end
			end

			-- Deduplicate by sender, keeping most recent
			local function dedupeByUser(messages)
				local seen = {}
				local deduped = {}
				for _, msg in ipairs(messages or {}) do
					local username = msg.username or "unknown"
					if not seen[username] then
						seen[username] = true
						table.insert(deduped, msg)
					end
				end
				return deduped
			end

			-- Fetch DMs (to:me)
			hs.http.asyncGet(
				"https://slack.com/api/search.messages?query=to:me&count=20&sort=timestamp",
				{ ["Authorization"] = "Bearer " .. token },
				function(s, r)
					if s == 200 then
						local data = hs.json.decode(r)
						if data and data.ok and data.messages then
							-- Filter to only DMs
							local dms = {}
							for _, msg in ipairs(data.messages.matches or {}) do
								if msg.channel and msg.channel.is_im then
									table.insert(dms, msg)
								end
							end
							results.dms = dedupeByUser(dms)
						end
					end
					checkDone()
				end
			)

			-- Fetch channel @mentions
			hs.http.asyncGet(
				"https://slack.com/api/search.messages?query=<@" .. userId .. ">&count=20&sort=timestamp",
				{ ["Authorization"] = "Bearer " .. token },
				function(s, r)
					if s == 200 then
						local data = hs.json.decode(r)
						if data and data.ok and data.messages then
							-- Filter to only channels (not DMs)
							local channels = {}
							for _, msg in ipairs(data.messages.matches or {}) do
								if msg.channel and not msg.channel.is_im then
									table.insert(channels, msg)
								end
							end
							results.channels = dedupeByUser(channels)
						end
					end
					checkDone()
				end
			)
		end
	)
end

-- User cache for resolving IDs to names
local slackUserCache = {}

-- Fetch user info and cache it
local function fetchSlackUser(userId, token, callback)
	if slackUserCache[userId] then
		callback(slackUserCache[userId])
		return
	end

	hs.http.asyncGet(
		"https://slack.com/api/users.info?user=" .. userId,
		{ ["Authorization"] = "Bearer " .. token },
		function(status, response)
			if status == 200 then
				local data = hs.json.decode(response)
				if data and data.ok and data.user then
					local name = data.user.real_name or data.user.name or userId
					slackUserCache[userId] = name
					callback(name)
					return
				end
			end
			callback(userId) -- fallback to ID
		end
	)
end

-- Resolve multiple user IDs to names (batch)
local function resolveSlackUsers(messages, token, callback)
	-- Collect unique user IDs
	local userIds = {}
	local seen = {}
	for _, msg in ipairs(messages or {}) do
		local uid = msg.user
		if uid and not seen[uid] and not slackUserCache[uid] then
			seen[uid] = true
			table.insert(userIds, uid)
		end
	end

	if #userIds == 0 then
		callback() -- all cached
		return
	end

	-- Fetch users in parallel (up to 10)
	local pending = math.min(#userIds, 10)
	for i = 1, pending do
		fetchSlackUser(userIds[i], token, function()
			pending = pending - 1
			if pending == 0 then
				callback()
			end
		end)
	end
end

-- Fetch Slack thread/conversation replies
local function fetchSlackThread(channelId, threadTs, callback, latest)
	local token = getEnvVar("SLACK_USER_TOKEN")
	if not token then
		callback(nil, "SLACK_USER_TOKEN not found")
		return
	end

	local url = "https://slack.com/api/conversations.replies?channel=" .. channelId .. "&ts=" .. threadTs .. "&limit=50"
	if latest then
		url = url .. "&latest=" .. latest
	end
	hs.http.asyncGet(
		url,
		{ ["Authorization"] = "Bearer " .. token },
		function(status, response)
			if status ~= 200 then
				callback(nil, "Slack API error: " .. tostring(status))
				return
			end
			local data = hs.json.decode(response)
			if data and data.ok and data.messages then
				-- Resolve user IDs to names
				resolveSlackUsers(data.messages, token, function()
					callback(data.messages)
				end)
			else
				callback({}, data and data.error)
			end
		end
	)
end

-- Fetch Slack conversation history (for DMs - full chat)
local function fetchSlackHistory(channelId, callback, latest)
	local token = getEnvVar("SLACK_USER_TOKEN")
	if not token then
		callback(nil, "SLACK_USER_TOKEN not found")
		return
	end

	local url = "https://slack.com/api/conversations.history?channel=" .. channelId .. "&limit=30"
	if latest then
		url = url .. "&latest=" .. latest
	end
	hs.http.asyncGet(
		url,
		{ ["Authorization"] = "Bearer " .. token },
		function(status, response)
			if status ~= 200 then
				callback(nil, "Slack API error: " .. tostring(status))
				return
			end
			local data = hs.json.decode(response)
			if data and data.ok and data.messages then
				-- Reverse to get chronological order (API returns newest first)
				local reversed = {}
				for i = #data.messages, 1, -1 do
					table.insert(reversed, data.messages[i])
				end
				-- Resolve user IDs to names
				resolveSlackUsers(reversed, token, function()
					callback(reversed)
				end)
			else
				callback({}, data and data.error)
			end
		end
	)
end

-- Fetch all sources
function attention.fetchAll(callback)
	local results = { linear = nil, slack = nil }
	local pending = 2

	local function checkDone()
		pending = pending - 1
		if pending == 0 then
			attention.cache = results
			attention.lastFetchDate = os.date("%Y-%m-%d")
			callback(results)
		end
	end

	fetchLinear(function(data, err)
		results.linear = data or {}
		if err then print("Linear fetch error:", err) end
		checkDone()
	end)

	fetchSlack(function(data, err)
		results.slack = data or {}
		if err then print("Slack fetch error:", err) end
		checkDone()
	end)
end

-- Check if we need to fetch (new day)
function attention.needsFetch()
	local today = os.date("%Y-%m-%d")
	return attention.lastFetchDate ~= today
end

-- Show loader (uses existing canvas size if available)
function attention.showLoader()
	-- Stop any existing loading animation
	if attention.loadingTimer then
		attention.loadingTimer:stop()
		attention.loadingTimer = nil
	end

	local font = "CaskaydiaCove Nerd Font Mono"
	local fontSize = 14

	local screen = hs.screen.mainScreen()
	local screenFrame = screen:frame()

	-- Use last known size or default
	local boxWidth, boxHeight
	if attention.lastCanvasSize then
		boxWidth = attention.lastCanvasSize.w
		boxHeight = attention.lastCanvasSize.h
	else
		boxWidth = 300
		boxHeight = 100
	end

	local boxX = screenFrame.x + (screenFrame.w - boxWidth) / 2
	local boxY = screenFrame.y + (screenFrame.h - boxHeight) / 2

	if attention.canvas then
		attention.canvas:delete()
	end

	attention.canvas = hs.canvas.new({ x = boxX, y = boxY, w = boxWidth, h = boxHeight })
	attention.canvasFrame = { x = boxX, y = boxY, w = boxWidth, h = boxHeight }
	local c = attention.canvas

	c[1] = { type = "rectangle", action = "fill", fillColor = { hex = "#1a1a1a", alpha = 0.95 }, roundedRectRadii = { xRadius = 10, yRadius = 10 } }
	c[2] = { type = "rectangle", action = "stroke", strokeColor = { hex = "#5e6ad2", alpha = 0.9 }, strokeWidth = 2, roundedRectRadii = { xRadius = 10, yRadius = 10 } }
	c[3] = { type = "text", text = "Loading.  ", textFont = font, textSize = fontSize, textColor = { hex = "#5e6ad2", alpha = 1 }, textAlignment = "center", frame = { x = 0, y = (boxHeight - fontSize) / 2, w = boxWidth, h = fontSize + 4 } }

	c:level(hs.canvas.windowLevels.overlay)
	c:clickActivating(false)
	c:show()
	attention.visible = true

	-- Animate loading dots (fixed width: ".  " -> ".. " -> "...")
	attention.loadingDots = 0
	attention.loadingTimer = hs.timer.doEvery(0.3, function()
		attention.loadingDots = (attention.loadingDots % 3) + 1
		local dots = string.rep(".", attention.loadingDots) .. string.rep(" ", 3 - attention.loadingDots)
		if attention.canvas and attention.canvas[3] then
			attention.canvas[3].text = "Loading" .. dots
		end
	end)
end

-- Render the dashboard
function attention.render(data)
	-- Stop loading animation
	if attention.loadingTimer then
		attention.loadingTimer:stop()
		attention.loadingTimer = nil
	end

	attention.currentView = "main"
	attention.clickableItems = {}
	attention.hoveredIndex = nil
	attention.keyMap = {}
	local itemIndex = 0

	local font = "CaskaydiaCove Nerd Font Mono"
	local fontSize = 14
	local lineHeight = fontSize + 10
	local sectionHeaderHeight = fontSize + 16
	local groupHeaderHeight = fontSize + 12
	local padding = 24
	local titleHeight = 36
	local sectionSpacing = 20
	local groupSpacing = 8

	-- Group Linear by project
	local linearProjects = {}
	local linearProjectOrder = {}
	for _, issue in ipairs(data.linear or {}) do
		local projectName = issue.project and issue.project.name or "No Project"
		if not linearProjects[projectName] then
			linearProjects[projectName] = {}
			table.insert(linearProjectOrder, projectName)
		end
		table.insert(linearProjects[projectName], issue)
	end

	-- Calculate content height
	local linearLines = #(data.linear or {})
	local linearGroups = #linearProjectOrder
	local slackDms = data.slack and data.slack.dms or {}
	local slackChannels = data.slack and data.slack.channels or {}
	local slackDmLines = math.min(#slackDms, 5)
	local slackChannelLines = math.min(#slackChannels, 5)

	local contentHeight = titleHeight + padding * 2 + 16
	if linearLines > 0 then
		contentHeight = contentHeight + sectionHeaderHeight + (linearLines * lineHeight) + (linearGroups * (groupHeaderHeight + groupSpacing)) + sectionSpacing
	end
	if slackChannelLines > 0 or slackDmLines > 0 then
		contentHeight = contentHeight + sectionHeaderHeight
		if slackChannelLines > 0 then
			contentHeight = contentHeight + groupHeaderHeight + (slackChannelLines * lineHeight) + groupSpacing
		end
		if slackDmLines > 0 then
			contentHeight = contentHeight + groupHeaderHeight + (slackDmLines * lineHeight)
		end
	end

	local boxWidth = 900

	local screen = hs.screen.mainScreen()
	local frame = screen:frame()
	local boxX = frame.x + (frame.w - boxWidth) / 2
	local boxY = frame.y + (frame.h - contentHeight) / 2

	if attention.canvas then
		attention.canvas:delete()
	end

	attention.canvas = hs.canvas.new({ x = boxX, y = boxY, w = boxWidth, h = contentHeight })
	attention.canvasFrame = { x = boxX, y = boxY, w = boxWidth, h = contentHeight }
	attention.lastCanvasSize = { w = boxWidth, h = contentHeight }
	local c = attention.canvas

	-- Background & border
	c[1] = { type = "rectangle", action = "fill", fillColor = { hex = "#1a1a1a", alpha = 0.95 }, roundedRectRadii = { xRadius = 10, yRadius = 10 } }
	c[2] = { type = "rectangle", action = "stroke", strokeColor = { hex = "#5e6ad2", alpha = 0.9 }, strokeWidth = 2, roundedRectRadii = { xRadius = 10, yRadius = 10 } }

	-- Title
	local totalItems = linearLines + slackChannelLines + slackDmLines
	c[3] = { type = "text", text = "Attention (" .. totalItems .. ")", textFont = font, textSize = fontSize + 4, textColor = { hex = "#5e6ad2", alpha = 1 }, textAlignment = "center", frame = { x = padding, y = padding, w = boxWidth - (padding * 2), h = titleHeight } }
	c[4] = { type = "rectangle", action = "fill", fillColor = { hex = "#444444", alpha = 1 }, frame = { x = padding, y = padding + titleHeight, w = boxWidth - (padding * 2), h = 1 } }

	-- Hover highlight placeholder (index 5)
	c[5] = { type = "rectangle", action = "fill", fillColor = { hex = "#ffffff", alpha = 0 }, frame = { x = 0, y = 0, w = 0, h = 0 } }

	local yPos = padding + titleHeight + 16

	-- Linear section
	if #(data.linear or {}) > 0 then
		c[#c + 1] = { type = "text", text = "Linear", textFont = font, textSize = fontSize + 2, textColor = { hex = "#5e6ad2", alpha = 1 }, textAlignment = "left", frame = { x = padding, y = yPos, w = boxWidth - (padding * 2), h = sectionHeaderHeight } }
		yPos = yPos + sectionHeaderHeight

		for _, projectName in ipairs(linearProjectOrder) do
			c[#c + 1] = { type = "text", text = projectName, textFont = font, textSize = fontSize, textColor = { hex = "#f97316", alpha = 1 }, textAlignment = "left", frame = { x = padding + 12, y = yPos, w = boxWidth - (padding * 2), h = groupHeaderHeight } }
			yPos = yPos + groupHeaderHeight

			for _, issue in ipairs(linearProjects[projectName]) do
				itemIndex = itemIndex + 1
				local shortcut = getShortcutKey(itemIndex)

				-- Track clickable item
				table.insert(attention.clickableItems, {
					type = "linear",
					y = yPos,
					h = lineHeight,
					x = padding,
					w = boxWidth - padding * 2,
					data = issue,
					key = shortcut
				})
				if shortcut then attention.keyMap[shortcut] = #attention.clickableItems end

				-- Shortcut key
				c[#c + 1] = { type = "text", text = shortcut or "", textFont = font, textSize = fontSize, textColor = { hex = "#5e6ad2", alpha = 1 }, textAlignment = "center", frame = { x = padding, y = yPos, w = 20, h = lineHeight } }

				c[#c + 1] = { type = "text", text = issue.identifier, textFont = font, textSize = fontSize, textColor = { hex = "#8b8b8b", alpha = 1 }, textAlignment = "left", frame = { x = padding + 28, y = yPos, w = 100, h = lineHeight } }

				local title = issue.title
				local maxChars = 85
				if #title > maxChars then title = title:sub(1, maxChars - 1) .. "…" end
				c[#c + 1] = { type = "text", text = title, textFont = font, textSize = fontSize, textColor = { hex = "#ffffff", alpha = 1 }, textAlignment = "left", frame = { x = padding + 130, y = yPos, w = boxWidth - padding - 150, h = lineHeight } }

				yPos = yPos + lineHeight
			end
			yPos = yPos + groupSpacing
		end
		yPos = yPos + sectionSpacing - groupSpacing
	end

	-- Slack section
	if #slackChannels > 0 or #slackDms > 0 then
		c[#c + 1] = { type = "text", text = "Slack", textFont = font, textSize = fontSize + 2, textColor = { hex = "#e01e5a", alpha = 1 }, textAlignment = "left", frame = { x = padding, y = yPos, w = boxWidth - (padding * 2), h = sectionHeaderHeight } }
		yPos = yPos + sectionHeaderHeight

		-- Channel mentions
		if #slackChannels > 0 then
			c[#c + 1] = { type = "text", text = "Mentions", textFont = font, textSize = fontSize, textColor = { hex = "#f97316", alpha = 1 }, textAlignment = "left", frame = { x = padding + 12, y = yPos, w = boxWidth - (padding * 2), h = groupHeaderHeight } }
			yPos = yPos + groupHeaderHeight

			for i, msg in ipairs(slackChannels) do
				if i > 5 then break end
				itemIndex = itemIndex + 1
				local shortcut = getShortcutKey(itemIndex)

				-- Track clickable item
				table.insert(attention.clickableItems, {
					type = "slack",
					y = yPos,
					h = lineHeight,
					x = padding,
					w = boxWidth - padding * 2,
					data = msg,
					key = shortcut
				})
				if shortcut then attention.keyMap[shortcut] = #attention.clickableItems end

				local from = msg.username or "unknown"
				local channel = msg.channel and msg.channel.name or ""
				local text = msg.text or ""
				text = text:gsub("<@[^>]+[^>]*>", ""):gsub("<[^>]+>", ""):gsub("%s+", " "):gsub("^%s+", "")
				local maxChars = 65
				if #text > maxChars then text = text:sub(1, maxChars - 1) .. "…" end

				-- Shortcut key
				c[#c + 1] = { type = "text", text = shortcut or "", textFont = font, textSize = fontSize, textColor = { hex = "#e01e5a", alpha = 1 }, textAlignment = "center", frame = { x = padding, y = yPos, w = 20, h = lineHeight } }

				c[#c + 1] = { type = "text", text = "#" .. channel, textFont = font, textSize = fontSize, textColor = { hex = "#8b8b8b", alpha = 1 }, textAlignment = "left", frame = { x = padding + 28, y = yPos, w = 120, h = lineHeight } }
				c[#c + 1] = { type = "text", text = from .. ": " .. text, textFont = font, textSize = fontSize, textColor = { hex = "#ffffff", alpha = 1 }, textAlignment = "left", frame = { x = padding + 155, y = yPos, w = boxWidth - padding - 175, h = lineHeight } }

				yPos = yPos + lineHeight
			end
			yPos = yPos + groupSpacing
		end

		-- DMs
		if #slackDms > 0 then
			c[#c + 1] = { type = "text", text = "DMs", textFont = font, textSize = fontSize, textColor = { hex = "#f97316", alpha = 1 }, textAlignment = "left", frame = { x = padding + 12, y = yPos, w = boxWidth - (padding * 2), h = groupHeaderHeight } }
			yPos = yPos + groupHeaderHeight

			for i, msg in ipairs(slackDms) do
				if i > 5 then break end
				itemIndex = itemIndex + 1
				local shortcut = getShortcutKey(itemIndex)

				-- Track clickable item
				table.insert(attention.clickableItems, {
					type = "slack",
					y = yPos,
					h = lineHeight,
					x = padding,
					w = boxWidth - padding * 2,
					data = msg,
					key = shortcut
				})
				if shortcut then attention.keyMap[shortcut] = #attention.clickableItems end

				local from = msg.username or "unknown"
				local text = msg.text or ""
				text = text:gsub("<@[^>]+[^>]*>", ""):gsub("<[^>]+>", ""):gsub("%s+", " "):gsub("^%s+", "")
				local maxChars = 70
				if #text > maxChars then text = text:sub(1, maxChars - 1) .. "…" end

				-- Shortcut key
				c[#c + 1] = { type = "text", text = shortcut or "", textFont = font, textSize = fontSize, textColor = { hex = "#e01e5a", alpha = 1 }, textAlignment = "center", frame = { x = padding, y = yPos, w = 20, h = lineHeight } }

				c[#c + 1] = { type = "text", text = from, textFont = font, textSize = fontSize, textColor = { hex = "#8b8b8b", alpha = 1 }, textAlignment = "left", frame = { x = padding + 28, y = yPos, w = 120, h = lineHeight } }
				c[#c + 1] = { type = "text", text = text, textFont = font, textSize = fontSize, textColor = { hex = "#ffffff", alpha = 1 }, textAlignment = "left", frame = { x = padding + 155, y = yPos, w = boxWidth - padding - 175, h = lineHeight } }

				yPos = yPos + lineHeight
			end
		end
	end

	c:level(hs.canvas.windowLevels.overlay)
	c:clickActivating(false)
	c:behaviorAsLabels({ "canJoinAllSpaces", "stationary" })
	c:show()
	attention.visible = true
	attention.setupEventHandlers()
end

-- Render Linear detail view
function attention.renderLinearDetail(issue, resetScroll)
	-- Stop loading animation
	if attention.loadingTimer then
		attention.loadingTimer:stop()
		attention.loadingTimer = nil
	end

	-- Store issue for scroll re-renders
	if issue then
		attention.currentIssue = issue
	else
		issue = attention.currentIssue
	end
	if not issue then return end

	-- Reset scroll on new issue
	if resetScroll ~= false then
		attention.scrollOffset = 0
	end

	attention.currentView = "linear-detail"
	attention.clickableItems = {}
	attention.hoveredIndex = nil
	attention.keyMap = {}
	attention.keyMap["b"] = 1 -- 'b' for back

	local font = "CaskaydiaCove Nerd Font Mono"
	local fontSize = 14
	local lineHeight = fontSize + 8
	local padding = 24
	local boxWidth = 900
	local boxHeight = 600
	local footerHeight = 36
	local contentTop = 60 -- Start of scrollable content

	local screen = hs.screen.mainScreen()
	local frame = screen:frame()
	local boxX = frame.x + (frame.w - boxWidth) / 2
	local boxY = frame.y + (frame.h - boxHeight) / 2

	if attention.canvas then
		attention.canvas:delete()
	end

	attention.canvas = hs.canvas.new({ x = boxX, y = boxY, w = boxWidth, h = boxHeight })
	attention.canvasFrame = { x = boxX, y = boxY, w = boxWidth, h = boxHeight }
	attention.lastCanvasSize = { w = boxWidth, h = boxHeight }
	local c = attention.canvas

	-- Background & border
	c[1] = { type = "rectangle", action = "fill", fillColor = { hex = "#1a1a1a", alpha = 0.95 }, roundedRectRadii = { xRadius = 10, yRadius = 10 } }
	c[2] = { type = "rectangle", action = "stroke", strokeColor = { hex = "#5e6ad2", alpha = 0.9 }, strokeWidth = 2, roundedRectRadii = { xRadius = 10, yRadius = 10 } }

	-- Back button
	table.insert(attention.clickableItems, {
		type = "back",
		y = padding,
		h = 30,
		x = padding,
		w = 90,
		key = "b"
	})
	c[3] = { type = "text", text = "b", textFont = font, textSize = fontSize, textColor = { hex = "#5e6ad2", alpha = 1 }, textAlignment = "left", frame = { x = padding, y = padding, w = 16, h = 30 } }
	c[4] = { type = "text", text = "← Back", textFont = font, textSize = fontSize, textColor = { hex = "#888888", alpha = 1 }, textAlignment = "left", frame = { x = padding + 20, y = padding, w = 70, h = 30 } }

	-- Hover highlight placeholder (index 5 - must match main view)
	c[5] = { type = "rectangle", action = "fill", fillColor = { hex = "#ffffff", alpha = 0 }, frame = { x = 0, y = 0, w = 0, h = 0 } }

	-- Title bar with identifier (fixed, not scrolled)
	local titleY = padding + 10
	c[#c + 1] = { type = "text", text = issue.identifier, textFont = font, textSize = fontSize + 2, textColor = { hex = "#8b8b8b", alpha = 1 }, textAlignment = "center", frame = { x = padding, y = titleY, w = boxWidth - (padding * 2), h = 30 } }

	-- Clipping rectangle for scrollable content (leave room for footer)
	local clipTop = padding + 45
	local clipHeight = boxHeight - clipTop - footerHeight - 8
	c[#c + 1] = {
		type = "rectangle",
		action = "clip",
		frame = { x = 0, y = clipTop, w = boxWidth, h = clipHeight }
	}

	-- Scrollable content area starts here
	local scrollY = -attention.scrollOffset
	local yPos = clipTop + 5 + scrollY

	-- Issue title
	c[#c + 1] = { type = "text", text = issue.title or "Untitled", textFont = font, textSize = fontSize + 6, textColor = { hex = "#ffffff", alpha = 1 }, textAlignment = "left", frame = { x = padding, y = yPos, w = boxWidth - (padding * 2), h = 36 } }
	yPos = yPos + 44

	-- Status & Project
	local status = issue.state and issue.state.name or "Unknown"
	local project = issue.project and issue.project.name or "No Project"
	c[#c + 1] = { type = "text", text = status .. "  •  " .. project, textFont = font, textSize = fontSize, textColor = { hex = "#f97316", alpha = 1 }, textAlignment = "left", frame = { x = padding, y = yPos, w = boxWidth - (padding * 2), h = lineHeight } }
	yPos = yPos + lineHeight + 16

	-- Separator
	c[#c + 1] = { type = "rectangle", action = "fill", fillColor = { hex = "#444444", alpha = 1 }, frame = { x = padding, y = yPos, w = boxWidth - (padding * 2), h = 1 } }
	yPos = yPos + 20

	-- Description
	c[#c + 1] = { type = "text", text = "Description", textFont = font, textSize = fontSize, textColor = { hex = "#5e6ad2", alpha = 1 }, textAlignment = "left", frame = { x = padding, y = yPos, w = boxWidth - (padding * 2), h = lineHeight } }
	yPos = yPos + lineHeight + 4

	local desc = issue.description or "(No description)"
	-- Allow longer descriptions now that we can scroll
	if #desc > 2000 then desc = desc:sub(1, 2000) .. "…" end
	-- Calculate height based on content (rough estimate: 80 chars per line, 18px per line)
	local descLines = math.ceil(#desc / 80)
	local descHeight = math.max(50, descLines * 18)
	c[#c + 1] = { type = "text", text = desc, textFont = font, textSize = fontSize - 1, textColor = { hex = "#cccccc", alpha = 1 }, textAlignment = "left", frame = { x = padding, y = yPos, w = boxWidth - (padding * 2), h = descHeight } }
	yPos = yPos + descHeight + 20

	-- Comments section
	local comments = issue.comments and issue.comments.nodes or {}
	if #comments > 0 then
		c[#c + 1] = { type = "rectangle", action = "fill", fillColor = { hex = "#444444", alpha = 1 }, frame = { x = padding, y = yPos, w = boxWidth - (padding * 2), h = 1 } }
		yPos = yPos + 20

		c[#c + 1] = { type = "text", text = "Comments (" .. #comments .. ")", textFont = font, textSize = fontSize, textColor = { hex = "#5e6ad2", alpha = 1 }, textAlignment = "left", frame = { x = padding, y = yPos, w = boxWidth - (padding * 2), h = lineHeight } }
		yPos = yPos + lineHeight + 8

		-- Show all comments now that we can scroll
		for i, comment in ipairs(comments) do
			local author = comment.user and comment.user.name or "Unknown"
			local body = comment.body or ""
			-- Allow longer comments
			if #body > 500 then body = body:sub(1, 500) .. "…" end
			local commentLines = math.ceil(#body / 80)
			local commentHeight = math.max(30, commentLines * 18)

			c[#c + 1] = { type = "text", text = author, textFont = font, textSize = fontSize - 1, textColor = { hex = "#f97316", alpha = 1 }, textAlignment = "left", frame = { x = padding, y = yPos, w = boxWidth - (padding * 2), h = lineHeight } }
			yPos = yPos + lineHeight

			c[#c + 1] = { type = "text", text = body, textFont = font, textSize = fontSize - 1, textColor = { hex = "#aaaaaa", alpha = 1 }, textAlignment = "left", frame = { x = padding + 12, y = yPos, w = boxWidth - (padding * 2) - 12, h = commentHeight } }
			yPos = yPos + commentHeight + 12
		end
	end

	-- Track total content height for scroll limits
	attention.contentHeight = yPos + attention.scrollOffset - padding
	attention.viewHeight = boxHeight - contentTop - footerHeight - 8

	-- Reset clip for footer (draw outside clipping region)
	c[#c + 1] = { type = "resetClip" }

	-- Footer bar background
	local footerY = boxHeight - footerHeight
	c[#c + 1] = { type = "rectangle", action = "fill", fillColor = { hex = "#252525", alpha = 1 }, frame = { x = 0, y = footerY, w = boxWidth, h = footerHeight }, roundedRectRadii = { xRadius = 0, yRadius = 0 } }
	c[#c + 1] = { type = "rectangle", action = "fill", fillColor = { hex = "#444444", alpha = 1 }, frame = { x = padding, y = footerY, w = boxWidth - (padding * 2), h = 1 } }

	-- Footer hotkey hints
	local hintY = footerY + 10
	local hintSize = fontSize - 2
	local keyColor = { hex = "#5e6ad2", alpha = 1 }
	local textColor = { hex = "#666666", alpha = 1 }

	-- Scroll indicators (show arrows based on scroll position)
	local canScrollUp = attention.scrollOffset > 0
	local canScrollDown = attention.contentHeight > attention.viewHeight + attention.scrollOffset
	local scrollHint = ""
	if canScrollUp and canScrollDown then
		scrollHint = "↑↓"
	elseif canScrollUp then
		scrollHint = "↑"
	elseif canScrollDown then
		scrollHint = "↓"
	end

	local xPos = padding
	-- j/k scroll
	c[#c + 1] = { type = "text", text = "j/k", textFont = font, textSize = hintSize, textColor = keyColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 30, h = 20 } }
	xPos = xPos + 32
	c[#c + 1] = { type = "text", text = "scroll " .. scrollHint, textFont = font, textSize = hintSize, textColor = textColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 80, h = 20 } }
	xPos = xPos + 90

	-- Ctrl+D/U page
	c[#c + 1] = { type = "text", text = "^d/^u", textFont = font, textSize = hintSize, textColor = keyColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 50, h = 20 } }
	xPos = xPos + 52
	c[#c + 1] = { type = "text", text = "page", textFont = font, textSize = hintSize, textColor = textColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 40, h = 20 } }
	xPos = xPos + 60

	-- b back
	c[#c + 1] = { type = "text", text = "b", textFont = font, textSize = hintSize, textColor = keyColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 14, h = 20 } }
	xPos = xPos + 16
	c[#c + 1] = { type = "text", text = "back", textFont = font, textSize = hintSize, textColor = textColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 40, h = 20 } }
	xPos = xPos + 60

	-- esc close
	c[#c + 1] = { type = "text", text = "esc", textFont = font, textSize = hintSize, textColor = keyColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 30, h = 20 } }
	xPos = xPos + 32
	c[#c + 1] = { type = "text", text = "close", textFont = font, textSize = hintSize, textColor = textColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 50, h = 20 } }

	c:level(hs.canvas.windowLevels.overlay)
	c:clickActivating(false)
	c:show()
	attention.visible = true
	attention.setupEventHandlers()
end

-- Render Slack detail view
function attention.renderSlackDetail(msg, thread, resetScroll)
	-- Stop loading animation
	if attention.loadingTimer then
		attention.loadingTimer:stop()
		attention.loadingTimer = nil
	end

	-- Store message and thread for scroll re-renders
	if msg then
		attention.currentSlackMsg = msg
		attention.currentSlackThread = thread or {}
	else
		msg = attention.currentSlackMsg
		thread = attention.currentSlackThread or {}
	end
	if not msg then return end

	-- For new messages, we'll scroll to bottom after calculating content height
	local scrollToBottom = (resetScroll ~= false)
	if scrollToBottom then
		attention.scrollOffset = 0 -- Start at 0, will adjust after measuring
	end

	attention.currentView = "slack-detail"
	attention.clickableItems = {}
	attention.hoveredIndex = nil
	attention.keyMap = {}
	attention.keyMap["b"] = 1 -- 'b' for back
	attention.keyMap["o"] = 2 -- 'o' to open in Slack
	-- Add 'u' key to go up to channel history (only in thread view)
	if attention.slackViewMode == "thread" then
		attention.keyMap["u"] = 3 -- 'u' for up to channel
	end

	local font = "CaskaydiaCove Nerd Font Mono"
	local fontSize = 14
	local lineHeight = fontSize + 8
	local padding = 24
	local boxWidth = 900
	local boxHeight = 600
	local footerHeight = 36
	local contentTop = 60

	local screen = hs.screen.mainScreen()
	local frame = screen:frame()
	local boxX = frame.x + (frame.w - boxWidth) / 2
	local boxY = frame.y + (frame.h - boxHeight) / 2

	if attention.canvas then
		attention.canvas:delete()
	end

	attention.canvas = hs.canvas.new({ x = boxX, y = boxY, w = boxWidth, h = boxHeight })
	attention.canvasFrame = { x = boxX, y = boxY, w = boxWidth, h = boxHeight }
	attention.lastCanvasSize = { w = boxWidth, h = boxHeight }
	local c = attention.canvas

	-- Background & border (Slack pink accent)
	c[1] = { type = "rectangle", action = "fill", fillColor = { hex = "#1a1a1a", alpha = 0.95 }, roundedRectRadii = { xRadius = 10, yRadius = 10 } }
	c[2] = { type = "rectangle", action = "stroke", strokeColor = { hex = "#e01e5a", alpha = 0.9 }, strokeWidth = 2, roundedRectRadii = { xRadius = 10, yRadius = 10 } }

	-- Back button
	table.insert(attention.clickableItems, {
		type = "back",
		y = padding,
		h = 30,
		x = padding,
		w = 90,
		key = "b"
	})
	c[3] = { type = "text", text = "b", textFont = font, textSize = fontSize, textColor = { hex = "#e01e5a", alpha = 1 }, textAlignment = "left", frame = { x = padding, y = padding, w = 16, h = 30 } }
	c[4] = { type = "text", text = "← Back", textFont = font, textSize = fontSize, textColor = { hex = "#888888", alpha = 1 }, textAlignment = "left", frame = { x = padding + 20, y = padding, w = 70, h = 30 } }

	-- Open in Slack button
	table.insert(attention.clickableItems, {
		type = "open-slack",
		y = padding,
		h = 30,
		x = boxWidth - padding - 120,
		w = 120,
		key = "o",
		data = msg
	})
	c[#c + 1] = { type = "text", text = "o", textFont = font, textSize = fontSize, textColor = { hex = "#e01e5a", alpha = 1 }, textAlignment = "left", frame = { x = boxWidth - padding - 120, y = padding, w = 16, h = 30 } }
	c[#c + 1] = { type = "text", text = "Open in Slack →", textFont = font, textSize = fontSize, textColor = { hex = "#888888", alpha = 1 }, textAlignment = "left", frame = { x = boxWidth - padding - 100, y = padding, w = 110, h = 30 } }

	-- Channel up button (only in thread view)
	if attention.slackViewMode == "thread" then
		table.insert(attention.clickableItems, {
			type = "channel-up",
			y = padding,
			h = 30,
			x = boxWidth / 2 - 60,
			w = 120,
			key = "u"
		})
		c[#c + 1] = { type = "text", text = "u", textFont = font, textSize = fontSize, textColor = { hex = "#e01e5a", alpha = 1 }, textAlignment = "left", frame = { x = boxWidth / 2 - 60, y = padding, w = 16, h = 30 } }
		c[#c + 1] = { type = "text", text = "↑ Channel", textFont = font, textSize = fontSize, textColor = { hex = "#888888", alpha = 1 }, textAlignment = "left", frame = { x = boxWidth / 2 - 40, y = padding, w = 80, h = 30 } }
	end

	-- Hover highlight placeholder (index must match after buttons)
	local hoverIdx = #c + 1
	c[hoverIdx] = { type = "rectangle", action = "fill", fillColor = { hex = "#ffffff", alpha = 0 }, frame = { x = 0, y = 0, w = 0, h = 0 } }

	-- Title bar with channel/DM info and view mode
	local titleY = padding + 10
	local channelName = msg.channel and msg.channel.name or "Direct Message"
	local isDM = msg.channel and msg.channel.is_im
	local modeLabel = attention.slackViewMode == "history" and " (history)" or " (thread)"
	local titleText = isDM and ("DM with " .. (msg.username or "unknown")) or ("#" .. channelName .. modeLabel)
	c[#c + 1] = { type = "text", text = titleText, textFont = font, textSize = fontSize + 2, textColor = { hex = "#8b8b8b", alpha = 1 }, textAlignment = "center", frame = { x = padding, y = titleY, w = boxWidth - (padding * 2), h = 30 } }

	-- Clipping rectangle for scrollable content (leave room for footer)
	local clipTop = padding + 45
	local clipHeight = boxHeight - clipTop - footerHeight - 8
	c[#c + 1] = {
		type = "rectangle",
		action = "clip",
		frame = { x = 0, y = clipTop, w = boxWidth, h = clipHeight }
	}

	-- Scrollable content area starts here
	local scrollY = -attention.scrollOffset
	local yPos = clipTop + 5 + scrollY

	-- Helper to clean Slack message text
	local function cleanSlackText(text)
		if not text then return "" end
		-- Remove user mentions like <@U123ABC|name> or <@U123ABC>
		text = text:gsub("<@[^>|]+|([^>]+)>", "@%1")
		text = text:gsub("<@[^>]+>", "@someone")
		-- Remove channel links <#C123|channel>
		text = text:gsub("<#[^>|]+|([^>]+)>", "#%1")
		-- Remove URLs but keep display text <http://url|display>
		text = text:gsub("<([^|>]+)|([^>]+)>", "%2")
		text = text:gsub("<([^>]+)>", "%1")
		-- Clean up whitespace but PRESERVE newlines
		text = text:gsub("[ \t]+", " ") -- collapse spaces/tabs only
		text = text:gsub("^%s+", ""):gsub("%s+$", "") -- trim start/end
		return text
	end

	-- Calculate text height accounting for newlines and wrapping
	local function calcTextHeight(text, charsPerLine, lineHeight)
		local totalLines = 0
		for line in (text .. "\n"):gmatch("([^\n]*)\n") do
			-- Each line wraps based on character count
			local wrappedLines = math.max(1, math.ceil(#line / charsPerLine))
			totalLines = totalLines + wrappedLines
		end
		return math.max(lineHeight, totalLines * lineHeight)
	end

	-- Helper to format timestamp
	local function formatTs(ts)
		if not ts then return "" end
		local timestamp = tonumber(ts:match("^(%d+)"))
		if timestamp then
			return os.date("%b %d, %H:%M", timestamp)
		end
		return ""
	end

	-- Helper to get username from cache or return ID
	local function getUserName(userId)
		if not userId then return "unknown" end
		return slackUserCache[userId] or userId
	end

	-- Show thread if we have it, otherwise show the search result message
	if thread and #thread > 0 then
		-- Show all messages (chronological order, oldest first)
		for i, threadMsg in ipairs(thread) do
			local sender = getUserName(threadMsg.user)
			local msgTime = formatTs(threadMsg.ts)
			local msgText = cleanSlackText(threadMsg.text)

			-- First message (parent) gets larger styling
			if i == 1 then
				c[#c + 1] = { type = "text", text = sender, textFont = font, textSize = fontSize + 2, textColor = { hex = "#f97316", alpha = 1 }, textAlignment = "left", frame = { x = padding, y = yPos, w = 300, h = 30 } }
				c[#c + 1] = { type = "text", text = msgTime, textFont = font, textSize = fontSize - 2, textColor = { hex = "#666666", alpha = 1 }, textAlignment = "right", frame = { x = boxWidth - padding - 150, y = yPos + 4, w = 150, h = 20 } }
				yPos = yPos + 32

				local msgHeight = calcTextHeight(msgText, 90, 20)
				c[#c + 1] = { type = "text", text = msgText, textFont = font, textSize = fontSize, textColor = { hex = "#ffffff", alpha = 1 }, textAlignment = "left", frame = { x = padding, y = yPos, w = boxWidth - (padding * 2), h = msgHeight } }
				yPos = yPos + msgHeight + 20

				-- Add separator and thread header if there are replies
				if #thread > 1 then
					c[#c + 1] = { type = "rectangle", action = "fill", fillColor = { hex = "#444444", alpha = 1 }, frame = { x = padding, y = yPos, w = boxWidth - (padding * 2), h = 1 } }
					yPos = yPos + 16
					c[#c + 1] = { type = "text", text = "Thread (" .. (#thread - 1) .. " replies)", textFont = font, textSize = fontSize, textColor = { hex = "#e01e5a", alpha = 1 }, textAlignment = "left", frame = { x = padding, y = yPos, w = boxWidth - (padding * 2), h = lineHeight } }
					yPos = yPos + lineHeight + 8
				end
			else
				-- Reply styling (indented, smaller)
				c[#c + 1] = { type = "text", text = sender, textFont = font, textSize = fontSize - 1, textColor = { hex = "#f97316", alpha = 1 }, textAlignment = "left", frame = { x = padding + 12, y = yPos, w = 200, h = lineHeight } }
				c[#c + 1] = { type = "text", text = msgTime, textFont = font, textSize = fontSize - 3, textColor = { hex = "#555555", alpha = 1 }, textAlignment = "right", frame = { x = boxWidth - padding - 120, y = yPos + 2, w = 108, h = 18 } }
				yPos = yPos + lineHeight

				local replyHeight = calcTextHeight(msgText, 85, 18)
				c[#c + 1] = { type = "text", text = msgText, textFont = font, textSize = fontSize - 1, textColor = { hex = "#cccccc", alpha = 1 }, textAlignment = "left", frame = { x = padding + 12, y = yPos, w = boxWidth - (padding * 2) - 12, h = replyHeight } }
				yPos = yPos + replyHeight + 16
			end
		end
	else
		-- No thread data - show the search result message
		local sender = msg.username or "unknown"
		local msgTime = formatTs(msg.ts)
		c[#c + 1] = { type = "text", text = sender, textFont = font, textSize = fontSize + 2, textColor = { hex = "#f97316", alpha = 1 }, textAlignment = "left", frame = { x = padding, y = yPos, w = 300, h = 30 } }
		c[#c + 1] = { type = "text", text = msgTime, textFont = font, textSize = fontSize - 2, textColor = { hex = "#666666", alpha = 1 }, textAlignment = "right", frame = { x = boxWidth - padding - 150, y = yPos + 4, w = 150, h = 20 } }
		yPos = yPos + 32

		local msgText = cleanSlackText(msg.text)
		local msgHeight = calcTextHeight(msgText, 90, 20)
		c[#c + 1] = { type = "text", text = msgText, textFont = font, textSize = fontSize, textColor = { hex = "#ffffff", alpha = 1 }, textAlignment = "left", frame = { x = padding, y = yPos, w = boxWidth - (padding * 2), h = msgHeight } }
		yPos = yPos + msgHeight + 20

		-- Show hint for channels
		c[#c + 1] = { type = "rectangle", action = "fill", fillColor = { hex = "#444444", alpha = 1 }, frame = { x = padding, y = yPos, w = boxWidth - (padding * 2), h = 1 } }
		yPos = yPos + 16
		local noThreadMsg = isDM and "(No thread replies)" or "(Press 'o' to view thread in Slack)"
		c[#c + 1] = { type = "text", text = noThreadMsg, textFont = font, textSize = fontSize - 1, textColor = { hex = "#555555", alpha = 1 }, textAlignment = "left", frame = { x = padding, y = yPos, w = boxWidth - (padding * 2), h = lineHeight } }
		yPos = yPos + lineHeight
	end

	-- Track total content height for scroll limits
	attention.contentHeight = yPos + attention.scrollOffset - padding
	attention.viewHeight = boxHeight - contentTop - footerHeight - 8

	-- If this is a new message, scroll to bottom to show latest
	if scrollToBottom and attention.contentHeight > attention.viewHeight then
		local maxScroll = attention.contentHeight - attention.viewHeight
		attention.scrollOffset = maxScroll
		-- Re-render with scroll at bottom
		return attention.renderSlackDetail(nil, nil, false)
	end

	-- Reset clip for footer
	c[#c + 1] = { type = "resetClip" }

	-- Footer bar background
	local footerY = boxHeight - footerHeight
	c[#c + 1] = { type = "rectangle", action = "fill", fillColor = { hex = "#252525", alpha = 1 }, frame = { x = 0, y = footerY, w = boxWidth, h = footerHeight } }
	c[#c + 1] = { type = "rectangle", action = "fill", fillColor = { hex = "#444444", alpha = 1 }, frame = { x = padding, y = footerY, w = boxWidth - (padding * 2), h = 1 } }

	-- Footer hotkey hints
	local hintY = footerY + 10
	local hintSize = fontSize - 2
	local keyColor = { hex = "#e01e5a", alpha = 1 }
	local textColor = { hex = "#666666", alpha = 1 }

	-- Scroll indicators
	local canScrollUp = attention.scrollOffset > 0
	local canScrollDown = attention.contentHeight > attention.viewHeight + attention.scrollOffset
	local scrollHint = ""
	if canScrollUp and canScrollDown then
		scrollHint = "↑↓"
	elseif canScrollUp then
		scrollHint = "↑"
	elseif canScrollDown then
		scrollHint = "↓"
	end

	local xPos = padding
	c[#c + 1] = { type = "text", text = "j/k", textFont = font, textSize = hintSize, textColor = keyColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 30, h = 20 } }
	xPos = xPos + 32
	c[#c + 1] = { type = "text", text = "scroll " .. scrollHint, textFont = font, textSize = hintSize, textColor = textColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 80, h = 20 } }
	xPos = xPos + 90

	c[#c + 1] = { type = "text", text = "^d/^u", textFont = font, textSize = hintSize, textColor = keyColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 50, h = 20 } }
	xPos = xPos + 52
	c[#c + 1] = { type = "text", text = "page", textFont = font, textSize = hintSize, textColor = textColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 40, h = 20 } }
	xPos = xPos + 60

	c[#c + 1] = { type = "text", text = "o", textFont = font, textSize = hintSize, textColor = keyColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 14, h = 20 } }
	xPos = xPos + 16
	c[#c + 1] = { type = "text", text = "open", textFont = font, textSize = hintSize, textColor = textColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 40, h = 20 } }
	xPos = xPos + 55

	c[#c + 1] = { type = "text", text = "b", textFont = font, textSize = hintSize, textColor = keyColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 14, h = 20 } }
	xPos = xPos + 16
	c[#c + 1] = { type = "text", text = "back", textFont = font, textSize = hintSize, textColor = textColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 40, h = 20 } }
	xPos = xPos + 55

	-- Show 'u' hint only in thread view
	if attention.slackViewMode == "thread" then
		c[#c + 1] = { type = "text", text = "u", textFont = font, textSize = hintSize, textColor = keyColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 14, h = 20 } }
		xPos = xPos + 16
		c[#c + 1] = { type = "text", text = "channel", textFont = font, textSize = hintSize, textColor = textColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 60, h = 20 } }
		xPos = xPos + 70
	end

	c[#c + 1] = { type = "text", text = "esc", textFont = font, textSize = hintSize, textColor = keyColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 30, h = 20 } }
	xPos = xPos + 32
	c[#c + 1] = { type = "text", text = "close", textFont = font, textSize = hintSize, textColor = textColor, textAlignment = "left", frame = { x = xPos, y = hintY, w = 50, h = 20 } }

	c:level(hs.canvas.windowLevels.overlay)
	c:clickActivating(false)
	c:show()
	attention.visible = true
	attention.setupEventHandlers()
end

-- Render Slack detail using webview for better text handling
-- keepScrollPosition: if true, don't scroll to bottom (for loadMore)
function attention.renderSlackDetailWebview(msg, thread, keepScrollPosition)
	-- Stop loading animation
	if attention.loadingTimer then
		attention.loadingTimer:stop()
		attention.loadingTimer = nil
	end

	-- Store for later use
	if msg then
		attention.currentSlackMsg = msg
		attention.currentSlackThread = thread or {}
	else
		msg = attention.currentSlackMsg
		thread = attention.currentSlackThread or {}
	end
	if not msg then return end

	-- Store oldest timestamp for pagination
	if thread and #thread > 0 and thread[1].ts then
		attention.slackOldestTs = thread[1].ts
	end

	attention.currentView = "slack-detail"

	-- Close canvas if open
	if attention.canvas then
		attention.canvas:delete()
		attention.canvas = nil
	end

	local boxWidth = 900
	local boxHeight = 600
	local screen = hs.screen.mainScreen()
	local frame = screen:frame()
	local boxX = frame.x + (frame.w - boxWidth) / 2
	local boxY = frame.y + (frame.h - boxHeight) / 2

	-- Helper functions
	local function escapeHtml(text)
		if not text then return "" end
		return text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&#39;")
	end

	local function formatSlackText(text)
		if not text then return "" end
		-- Process Slack formatting BEFORE escaping HTML
		-- User mentions: <@U123ABC|displayname> or <@U123ABC>
		text = text:gsub("<@([^|>]+)|([^>]+)>", function(uid, name)
			return "@" .. name
		end)
		text = text:gsub("<@([^>]+)>", function(uid)
			local name = slackUserCache[uid] or uid
			return "@" .. name
		end)
		-- Channel links: <#C123|channel-name>
		text = text:gsub("<#[^|>]+|([^>]+)>", "#%1")
		-- URL with display text: <http://url|display text>
		text = text:gsub("<(https?://[^|>]+)|([^>]+)>", function(url, display)
			return "LINK[" .. url .. "](" .. display .. ")"
		end)
		-- Plain URLs: <http://url>
		text = text:gsub("<(https?://[^>]+)>", "%1")

		-- Now escape HTML
		text = escapeHtml(text)

		-- Convert our link placeholders to actual links (after escaping)
		text = text:gsub("LINK%[([^%]]+)%]%(([^%)]+)%)", '<a href="%1" target="_blank">%2</a>')
		-- Make plain URLs clickable
		text = text:gsub("(https?://[%w%-%./_~:/?#%[%]@!$&amp;'()*+,;=%%]+)", '<a href="%1" target="_blank">%1</a>')
		-- Style @mentions
		text = text:gsub("@([%w%-_%.]+)", '<span class="mention">@%1</span>')
		-- Convert newlines to <br>
		text = text:gsub("\n", "<br>")
		return text
	end

	local function formatTs(ts)
		if not ts then return "" end
		local timestamp = tonumber(ts:match("^(%d+)"))
		if timestamp then
			return os.date("%b %d, %H:%M", timestamp)
		end
		return ""
	end

	local function getUserName(userId)
		if not userId then return "unknown" end
		return slackUserCache[userId] or userId
	end

	-- Build HTML
	local channelName = msg.channel and msg.channel.name or "Direct Message"
	local isDM = msg.channel and msg.channel.is_im
	local modeLabel = attention.slackViewMode == "history" and " (history)" or " (thread)"
	local titleText = isDM and ("DM with " .. escapeHtml(msg.username or "unknown")) or ("#" .. escapeHtml(channelName) .. modeLabel)
	local showChannelUp = attention.slackViewMode == "thread"

	local html = [[
<!DOCTYPE html>
<html>
<head>
<style>
* { margin: 0; padding: 0; box-sizing: border-box; }
body {
	font-family: 'CaskaydiaCove Nerd Font Mono', 'SF Mono', Menlo, monospace;
	font-size: 14px;
	line-height: 1.5;
	background: #1a1a1a;
	color: #ffffff;
	padding: 0;
	overflow: hidden;
}
.container {
	display: flex;
	flex-direction: column;
	height: 100vh;
	border: 2px solid #e01e5a;
	border-radius: 10px;
	overflow: hidden;
}
.header {
	padding: 16px 24px;
	border-bottom: 1px solid #333;
	display: flex;
	justify-content: space-between;
	align-items: center;
	flex-shrink: 0;
}
.header-left, .header-right { display: flex; gap: 8px; align-items: center; }
.btn {
	color: #888;
	cursor: pointer;
	padding: 4px 8px;
	border-radius: 4px;
	transition: background 0.15s;
	user-select: none;
}
.btn:hover { background: rgba(255,255,255,0.1); }
.btn .key { color: #e01e5a; margin-right: 4px; }
.mention {
	color: #36a3eb;
	background: rgba(54, 163, 235, 0.15);
	padding: 1px 4px;
	border-radius: 3px;
}
.thread-link {
	color: #36a3eb;
	cursor: pointer;
	font-size: 12px;
	margin-top: 6px;
	display: inline-block;
	padding: 2px 6px;
	border-radius: 4px;
	transition: background 0.15s;
}
.thread-link:hover { background: rgba(54, 163, 235, 0.15); text-decoration: underline; }
.title {
	color: #8b8b8b;
	font-size: 16px;
	text-align: center;
	flex: 1;
}
.content {
	flex: 1;
	overflow-y: auto;
	padding: 20px 24px;
	user-select: text;
	cursor: text;
}
.message { margin-bottom: 20px; }
.message.reply { margin-left: 16px; padding-left: 12px; border-left: 2px solid #333; }
.message-header { display: flex; justify-content: space-between; align-items: baseline; margin-bottom: 6px; }
.sender { color: #f97316; font-weight: 500; }
.message.reply .sender { font-size: 13px; }
.time { color: #666; font-size: 12px; }
.message-text { color: #fff; white-space: pre-wrap; word-wrap: break-word; }
.message.reply .message-text { color: #ccc; font-size: 13px; }
.thread-separator {
	border-top: 1px solid #444;
	margin: 20px 0 16px 0;
	padding-top: 12px;
	color: #e01e5a;
	font-size: 14px;
}
a { color: #36a3eb; text-decoration: none; cursor: pointer; }
a:hover { text-decoration: underline; }
.footer {
	padding: 10px 24px;
	border-top: 1px solid #444;
	background: #252525;
	display: flex;
	gap: 16px;
	flex-shrink: 0;
	font-size: 12px;
}
.hint .key { color: #e01e5a; }
.hint .label { color: #666; }
/* Scrollbar styling */
::-webkit-scrollbar { width: 8px; }
::-webkit-scrollbar-track { background: #252525; }
::-webkit-scrollbar-thumb { background: #444; border-radius: 4px; }
::-webkit-scrollbar-thumb:hover { background: #555; }
</style>
</head>
<body>
<div class="container">
	<div class="header">
		<div class="header-left">
			<span class="btn" onclick="window.webkit.messageHandlers.hammerspoon.postMessage('back')"><span class="key">b</span>← Back</span>
		</div>
		<div class="title">]] .. titleText .. [[</div>
		<div class="header-right">
]] .. (showChannelUp and [[			<span class="btn" onclick="window.webkit.messageHandlers.hammerspoon.postMessage('channelUp')"><span class="key">u</span>↑ Channel</span>
]] or "") .. [[
			<span class="btn" onclick="window.webkit.messageHandlers.hammerspoon.postMessage('openSlack')"><span class="key">o</span>Open in Slack →</span>
		</div>
	</div>
	<div class="content" id="content">
]]

	-- Add messages based on view mode
	if attention.slackViewMode == "history" then
		-- History mode: show messages with "X replies" links
		for i, threadMsg in ipairs(thread or {}) do
			local sender = escapeHtml(getUserName(threadMsg.user))
			local msgTime = formatTs(threadMsg.ts)
			local msgText = formatSlackText(threadMsg.text)
			local replyCount = threadMsg.reply_count or 0
			local threadTs = threadMsg.thread_ts or threadMsg.ts

			html = html .. [[
		<div class="message">
			<div class="message-header">
				<span class="sender">]] .. sender .. [[</span>
				<span class="time">]] .. msgTime .. [[</span>
			</div>
			<div class="message-text">]] .. msgText .. [[</div>
]]
			if replyCount > 0 then
				html = html .. [[
			<span class="thread-link" onclick="window.webkit.messageHandlers.hammerspoon.postMessage('thread:]] .. threadTs .. [[')">💬 ]] .. replyCount .. [[ replies</span>
]]
			end
			html = html .. [[
		</div>
]]
		end
	elseif thread and #thread > 0 then
		-- Thread mode: show all messages
		for i, threadMsg in ipairs(thread) do
			local sender = escapeHtml(getUserName(threadMsg.user))
			local msgTime = formatTs(threadMsg.ts)
			local msgText = formatSlackText(threadMsg.text)

			if i == 1 then
				html = html .. [[
		<div class="message">
			<div class="message-header">
				<span class="sender">]] .. sender .. [[</span>
				<span class="time">]] .. msgTime .. [[</span>
			</div>
			<div class="message-text">]] .. msgText .. [[</div>
		</div>
]]
				if #thread > 1 then
					html = html .. [[
		<div class="thread-separator">Thread (]] .. (#thread - 1) .. [[ replies)</div>
]]
				end
			else
				html = html .. [[
		<div class="message reply">
			<div class="message-header">
				<span class="sender">]] .. sender .. [[</span>
				<span class="time">]] .. msgTime .. [[</span>
			</div>
			<div class="message-text">]] .. msgText .. [[</div>
		</div>
]]
			end
		end
	else
		-- No thread data - show search result message
		local sender = escapeHtml(msg.username or "unknown")
		local msgTime = formatTs(msg.ts)
		local msgText = formatSlackText(msg.text)
		html = html .. [[
		<div class="message">
			<div class="message-header">
				<span class="sender">]] .. sender .. [[</span>
				<span class="time">]] .. msgTime .. [[</span>
			</div>
			<div class="message-text">]] .. msgText .. [[</div>
		</div>
		<div class="thread-separator">]] .. (isDM and "(No thread replies)" or "(Press 'o' to view thread in Slack)") .. [[</div>
]]
	end

	html = html .. [[
	</div>
	<div class="footer">
		<span class="hint"><span class="key">j/k</span> <span class="label">scroll</span></span>
		<span class="hint"><span class="key">^d/^u</span> <span class="label">page</span></span>
		<span class="hint"><span class="key">o</span> <span class="label">open</span></span>
		<span class="hint"><span class="key">b</span> <span class="label">back</span></span>
]] .. (showChannelUp and [[		<span class="hint"><span class="key">u</span> <span class="label">channel</span></span>
]] or "") .. [[
		<span class="hint"><span class="key">esc</span> <span class="label">close</span></span>
	</div>
</div>
<script>
var isLoadingMore = false;
// Scroll to bottom on load (unless keepScrollPosition)
window.onload = function() {
	var content = document.getElementById('content');
	]] .. (keepScrollPosition and "isLoadingMore = false;" or "content.scrollTop = content.scrollHeight;") .. [[
};
// Scroll event - detect when at top to load more
document.getElementById('content').addEventListener('scroll', function() {
	var content = this;
	if (content.scrollTop < 50 && !isLoadingMore) {
		isLoadingMore = true;
		window.webkit.messageHandlers.hammerspoon.postMessage('loadMore');
	}
});
// Keyboard handling
document.addEventListener('keydown', function(e) {
	var content = document.getElementById('content');
	var scrollAmount = 60;
	var pageAmount = content.clientHeight * 0.8;

	if (e.key === 'j') {
		content.scrollTop += scrollAmount;
		e.preventDefault();
	} else if (e.key === 'k') {
		content.scrollTop -= scrollAmount;
		e.preventDefault();
	} else if (e.key === 'd' && e.ctrlKey) {
		content.scrollTop += pageAmount;
		e.preventDefault();
	} else if (e.key === 'u' && e.ctrlKey) {
		content.scrollTop -= pageAmount;
		e.preventDefault();
	} else if (e.key === 'u' && !e.ctrlKey && !e.metaKey && ]] .. (showChannelUp and "true" or "false") .. [[) {
		window.webkit.messageHandlers.hammerspoon.postMessage('channelUp');
		e.preventDefault();
	} else if (e.key === 'b') {
		window.webkit.messageHandlers.hammerspoon.postMessage('back');
		e.preventDefault();
	} else if (e.key === 'o') {
		window.webkit.messageHandlers.hammerspoon.postMessage('openSlack');
		e.preventDefault();
	} else if (e.key === 'Escape') {
		window.webkit.messageHandlers.hammerspoon.postMessage('close');
		e.preventDefault();
	}
});
</script>
</body>
</html>
]]

	-- Stop canvas event watchers - they interfere with webview mouse events
	if attention.escapeWatcher then
		attention.escapeWatcher:stop()
		attention.escapeWatcher = nil
	end
	if attention.clickWatcher then
		attention.clickWatcher:stop()
		attention.clickWatcher = nil
	end
	if attention.hoverWatcher then
		attention.hoverWatcher:stop()
		attention.hoverWatcher = nil
	end

	-- Create webview with user content controller for JS callbacks
	if attention.webview then
		attention.webview:delete()
	end
	if attention.webviewUC then
		attention.webviewUC = nil
	end

	-- Store permalink for callback use
	local msgPermalink = msg.permalink

	-- Create user content controller for JS -> Lua communication
	attention.webviewUC = hs.webview.usercontent.new("hammerspoon")
	attention.webviewUC:setCallback(function(message)
		local action = message.body
		if action == "back" then
			attention.closeWebview()
			attention.scrollOffset = 0
			attention.render(attention.cache)
		elseif action == "close" then
			attention.hide()
		elseif action == "openSlack" then
			if msgPermalink then
				hs.urlevent.openURL(msgPermalink)
			end
			attention.hide()
		elseif action == "channelUp" then
			if attention.currentSlackChannel then
				attention.closeWebview()
				attention.showLoader()
				attention.slackViewMode = "history"
				fetchSlackHistory(attention.currentSlackChannel, function(messages, err)
					attention.renderSlackDetailWebview(attention.currentSlackMsg, messages)
				end)
			else
				hs.alert.show("No channel ID stored")
			end
		elseif action:match("^thread:") then
			-- Click on thread link to view thread
			local threadTs = action:match("^thread:(.+)$")
			if threadTs and attention.currentSlackChannel then
				attention.closeWebview()
				attention.showLoader()
				attention.slackViewMode = "thread"
				attention.slackThreadTs = threadTs
				fetchSlackThread(attention.currentSlackChannel, threadTs, function(threadMsgs, err)
					attention.renderSlackDetailWebview(attention.currentSlackMsg, threadMsgs)
				end)
			end
		elseif action == "loadMore" then
			if attention.slackOldestTs and attention.currentSlackChannel then
				if attention.slackViewMode == "history" then
					-- Fetch older history
					fetchSlackHistory(attention.currentSlackChannel, function(olderMessages, err)
						if olderMessages and #olderMessages > 0 then
							-- Prepend older messages to existing thread
							local combined = {}
							for _, m in ipairs(olderMessages) do
								table.insert(combined, m)
							end
							for _, m in ipairs(attention.currentSlackThread or {}) do
								table.insert(combined, m)
							end
							attention.currentSlackThread = combined
							-- Update oldest timestamp
							if combined[1] and combined[1].ts then
								attention.slackOldestTs = combined[1].ts
							end
							-- Re-render without scrolling to bottom
							attention.renderSlackDetailWebview(nil, nil, true)
						else
							-- No more messages - tell JS
							if attention.webview then
								attention.webview:evaluateJavaScript("isLoadingMore = false;", nil)
							end
						end
					end, attention.slackOldestTs)
				else
					-- Fetch older thread replies
					fetchSlackThread(attention.currentSlackChannel, attention.slackThreadTs, function(olderMessages, err)
						if olderMessages and #olderMessages > 0 then
							-- Prepend older messages (skip first if it's the parent)
							local combined = {}
							local existingFirst = attention.currentSlackThread and attention.currentSlackThread[1]
							for _, m in ipairs(olderMessages) do
								-- Skip if this is the parent message we already have
								if not (existingFirst and m.ts == existingFirst.ts) then
									table.insert(combined, m)
								end
							end
							for _, m in ipairs(attention.currentSlackThread or {}) do
								table.insert(combined, m)
							end
							attention.currentSlackThread = combined
							if combined[1] and combined[1].ts then
								attention.slackOldestTs = combined[1].ts
							end
							attention.renderSlackDetailWebview(nil, nil, true)
						else
							if attention.webview then
								attention.webview:evaluateJavaScript("isLoadingMore = false;", nil)
							end
						end
					end, attention.slackOldestTs)
				end
			else
				-- No more to load
				if attention.webview then
					attention.webview:evaluateJavaScript("isLoadingMore = false;", nil)
				end
			end
		end
	end)

	attention.webview = hs.webview.new({ x = boxX, y = boxY, w = boxWidth, h = boxHeight }, { developerExtrasEnabled = false }, attention.webviewUC)
	attention.webview:windowStyle({ "borderless", "closable" })
	attention.webview:level(hs.canvas.windowLevels.overlay)
	attention.webview:allowTextEntry(true)
	attention.webview:allowNewWindows(false)
	attention.webview:transparent(false)

	-- Handle link clicks - open in browser instead of navigating
	attention.webview:navigationCallback(function(action, wv, navType, url)
		if action == "navigationAction" and url and url ~= "about:blank" and not url:match("^data:") then
			-- External link clicked - open in browser
			hs.urlevent.openURL(url)
			return false -- prevent webview navigation
		end
		return true
	end)

	attention.webview:html(html)
	attention.webview:show()
	attention.webview:bringToFront()
	attention.visible = true
	attention.canvasFrame = { x = boxX, y = boxY, w = boxWidth, h = boxHeight }

	-- Create eventtap for keyboard handling (webview JS doesn't capture reliably)
	attention.webviewKeyWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
		local keyCode = event:getKeyCode()
		local flags = event:getFlags()

		-- Escape - close
		if keyCode == 53 then
			attention.hide()
			return true
		end

		-- 'b' - back (keycode 11)
		if keyCode == 11 and not flags.ctrl and not flags.cmd then
			attention.closeWebview()
			attention.scrollOffset = 0
			attention.render(attention.cache)
			return true
		end

		-- 'o' - open in Slack (keycode 31)
		if keyCode == 31 and not flags.ctrl and not flags.cmd then
			if msgPermalink then
				hs.urlevent.openURL(msgPermalink)
			end
			attention.hide()
			return true
		end

		-- 'u' - channel up (keycode 32) - only in thread mode
		if keyCode == 32 and not flags.ctrl and not flags.cmd and showChannelUp then
			if attention.currentSlackChannel then
				attention.closeWebview()
				attention.showLoader()
				attention.slackViewMode = "history"
				fetchSlackHistory(attention.currentSlackChannel, function(messages, err)
					attention.renderSlackDetailWebview(attention.currentSlackMsg, messages)
				end)
			end
			return true
		end

		-- 'j' - scroll down (keycode 38)
		if keyCode == 38 and not flags.ctrl then
			attention.webview:evaluateJavaScript("document.getElementById('content').scrollTop += 60;", nil)
			return true
		end

		-- 'k' - scroll up (keycode 40)
		if keyCode == 40 and not flags.ctrl then
			attention.webview:evaluateJavaScript("document.getElementById('content').scrollTop -= 60;", nil)
			return true
		end

		-- Ctrl+d - page down (keycode 2)
		if keyCode == 2 and flags.ctrl then
			attention.webview:evaluateJavaScript("var c = document.getElementById('content'); c.scrollTop += c.clientHeight * 0.8;", nil)
			return true
		end

		-- Ctrl+u - page up (keycode 32)
		if keyCode == 32 and flags.ctrl then
			attention.webview:evaluateJavaScript("var c = document.getElementById('content'); c.scrollTop -= c.clientHeight * 0.8;", nil)
			return true
		end

		return true -- block all other keys
	end)
	attention.webviewKeyWatcher:start()
end

-- Close webview helper
function attention.closeWebview()
	if attention.webviewKeyWatcher then
		attention.webviewKeyWatcher:stop()
		attention.webviewKeyWatcher = nil
	end
	if attention.webview then
		attention.webview:delete()
		attention.webview = nil
	end
end

-- Update hover highlight
function attention.updateHover(index)
	if attention.hoveredIndex == index then return end
	attention.hoveredIndex = index

	if not attention.canvas then return end

	if index and attention.clickableItems[index] then
		local item = attention.clickableItems[index]
		attention.canvas[5] = {
			type = "rectangle",
			action = "fill",
			fillColor = { hex = "#ffffff", alpha = 0.08 },
			roundedRectRadii = { xRadius = 4, yRadius = 4 },
			frame = { x = item.x or 24, y = item.y, w = item.w or 852, h = item.h }
		}
		setHandCursor()
	else
		attention.canvas[5] = {
			type = "rectangle",
			action = "fill",
			fillColor = { hex = "#ffffff", alpha = 0 },
			frame = { x = 0, y = 0, w = 0, h = 0 }
		}
		resetCursor()
	end
end

-- Setup event handlers
function attention.setupEventHandlers()
	if attention.escapeWatcher then
		attention.escapeWatcher:stop()
	end
	if attention.clickWatcher then
		attention.clickWatcher:stop()
	end
	if attention.hoverWatcher then
		attention.hoverWatcher:stop()
	end

	attention.escapeWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
		local keyCode = event:getKeyCode()
		local char = event:getCharacters()
		local mods = event:getFlags()

		-- Escape - go back or close
		if keyCode == 53 then
			if attention.currentView == "linear-detail" or attention.currentView == "slack-detail" then
				attention.scrollOffset = 0
				attention.render(attention.cache)
			else
				attention.hide()
			end
			return true
		end

		-- Scroll in detail views: Ctrl+D/U or j/k
		if attention.currentView == "linear-detail" or attention.currentView == "slack-detail" then
			-- Use keyCode for Ctrl combos since getCharacters() returns control chars when Ctrl is held
			-- d=2, u=32, j=38, k=40
			local scrollDown = (mods.ctrl and keyCode == 2) or (keyCode == 38)
			local scrollUp = (mods.ctrl and keyCode == 32) or (keyCode == 40)

			if scrollDown then
				local maxScroll = math.max(0, (attention.contentHeight or 0) - (attention.viewHeight or 400))
				attention.scrollOffset = math.min(attention.scrollOffset + 100, maxScroll)
				if attention.currentView == "linear-detail" then
					attention.renderLinearDetail(nil, false)
				else
					attention.renderSlackDetail(nil, nil, false)
				end
				return true
			end

			if scrollUp then
				attention.scrollOffset = math.max(0, attention.scrollOffset - 100)
				if attention.currentView == "linear-detail" then
					attention.renderLinearDetail(nil, false)
				else
					attention.renderSlackDetail(nil, nil, false)
				end
				return true
			end
		end

		-- Check if it's a shortcut key
		if char and attention.keyMap[char] then
			local itemIdx = attention.keyMap[char]
			local item = attention.clickableItems[itemIdx]
			if item then
				if item.type == "linear" then
					attention.showLoader()
					fetchLinearDetail(item.data.identifier, function(issue, err)
						if issue then
							attention.renderLinearDetail(issue)
						else
							attention.render(attention.cache)
							hs.alert.show("Failed to load issue")
						end
					end)
				elseif item.type == "slack" then
					-- Show Slack detail view
					attention.showLoader()
					local channelId = item.data.channel and item.data.channel.id
					local isDM = item.data.channel and item.data.channel.is_im
					attention.currentSlackChannel = channelId

					if isDM and channelId then
						-- For DMs: fetch full conversation history
						attention.slackViewMode = "history"
						fetchSlackHistory(channelId, function(messages, err)
							attention.renderSlackDetailWebview(item.data, messages)
						end)
					else
						-- For channels: fetch thread
						attention.slackViewMode = "thread"
						local threadTs = item.data.thread_ts or item.data.ts
						if channelId and threadTs then
							fetchSlackThread(channelId, threadTs, function(thread, err)
								attention.renderSlackDetailWebview(item.data, thread)
							end)
						else
							attention.renderSlackDetailWebview(item.data, {})
						end
					end
				elseif item.type == "back" then
					attention.scrollOffset = 0
					attention.render(attention.cache)
				elseif item.type == "open-slack" then
					if item.data and item.data.permalink then
						hs.urlevent.openURL(item.data.permalink)
					end
					attention.hide()
				elseif item.type == "channel-up" then
					-- Go up from thread to channel history
					if attention.currentSlackChannel then
						attention.showLoader()
						attention.slackViewMode = "history"
						fetchSlackHistory(attention.currentSlackChannel, function(messages, err)
							attention.renderSlackDetailWebview(attention.currentSlackMsg, messages)
						end)
					end
				end
			end
			return true
		end

		-- Block ALL other keys from reaching other apps
		return true
	end)
	attention.escapeWatcher:start()

	-- Hover tracking
	attention.hoverWatcher = hs.eventtap.new({ hs.eventtap.event.types.mouseMoved }, function(event)
		local pos = hs.mouse.absolutePosition()
		local f = attention.canvasFrame
		if not f then return false end

		-- Check if mouse is inside canvas
		if pos.x >= f.x and pos.x <= f.x + f.w and pos.y >= f.y and pos.y <= f.y + f.h then
			local relY = pos.y - f.y
			local relX = pos.x - f.x

			-- Find which item is hovered
			local foundIndex = nil
			for i, item in ipairs(attention.clickableItems) do
				local itemX = item.x or 0
				local itemW = item.w or f.w
				if relY >= item.y and relY <= item.y + item.h then
					if item.type == "back" or item.type == "open-slack" or item.type == "channel-up" then
						if relX >= itemX and relX <= itemX + itemW then
							foundIndex = i
							break
						end
					else
						foundIndex = i
						break
					end
				end
			end

			attention.updateHover(foundIndex)
		else
			attention.updateHover(nil)
		end
		return false
	end)
	attention.hoverWatcher:start()

	attention.clickWatcher = hs.eventtap.new({ hs.eventtap.event.types.leftMouseDown }, function(event)
		local pos = hs.mouse.absolutePosition()
		local f = attention.canvasFrame
		if not f then return false end

		-- Check if click is inside canvas
		if pos.x >= f.x and pos.x <= f.x + f.w and pos.y >= f.y and pos.y <= f.y + f.h then
			local relY = pos.y - f.y
			local relX = pos.x - f.x

			-- Check clickable items
			for _, item in ipairs(attention.clickableItems) do
				if relY >= item.y and relY <= item.y + item.h then
					if item.type == "back" then
						if relX >= item.x and relX <= item.x + item.w then
							attention.scrollOffset = 0
							attention.render(attention.cache)
							return true
						end
					elseif item.type == "open-slack" then
						if relX >= item.x and relX <= item.x + item.w then
							if item.data and item.data.permalink then
								hs.urlevent.openURL(item.data.permalink)
							end
							attention.hide()
							return true
						end
					elseif item.type == "linear" then
						-- Fetch and show Linear detail
						attention.showLoader()
						fetchLinearDetail(item.data.identifier, function(issue, err)
							if issue then
								attention.renderLinearDetail(issue)
							else
								attention.render(attention.cache)
								hs.alert.show("Failed to load issue")
							end
						end)
						return true
					elseif item.type == "slack" then
						-- Fetch and show Slack detail with thread
						attention.showLoader()
						attention.slackViewMode = "thread"
						local channelId = item.data.channel and item.data.channel.id
						attention.currentSlackChannel = channelId -- Store for "up" navigation
						-- Use thread_ts if available (for replies), otherwise ts (for parent messages)
						local threadTs = item.data.thread_ts or item.data.ts
						if channelId and threadTs then
							fetchSlackThread(channelId, threadTs, function(thread, err)
								attention.renderSlackDetailWebview(item.data, thread)
							end)
						else
							attention.renderSlackDetailWebview(item.data, {})
						end
						return true
					elseif item.type == "channel-up" then
						-- Go up from thread view to channel history
						if relX >= item.x and relX <= item.x + item.w then
							if attention.currentSlackChannel then
								attention.showLoader()
								attention.slackViewMode = "history"
								fetchSlackHistory(attention.currentSlackChannel, function(messages, err)
									attention.renderSlackDetailWebview(attention.currentSlackMsg, messages)
								end)
							end
							return true
						end
					end
				end
			end

			-- Click outside items - dismiss if on main view
			if attention.currentView == "main" then
				attention.hide()
			end
			return true
		else
			-- Click outside canvas - dismiss
			attention.hide()
		end
		return false
	end)
	attention.clickWatcher:start()
end

function attention.show()
	attention.showLoader()
	if attention.cache.linear and attention.cache.slack and not attention.needsFetch() then
		attention.render(attention.cache)
	else
		attention.fetchAll(function(data)
			attention.render(data)
		end)
	end
end

function attention.hide()
	resetCursor()
	if attention.loadingTimer then
		attention.loadingTimer:stop()
		attention.loadingTimer = nil
	end
	if attention.webviewKeyWatcher then
		attention.webviewKeyWatcher:stop()
		attention.webviewKeyWatcher = nil
	end
	if attention.webview then
		attention.webview:delete()
		attention.webview = nil
	end
	if attention.canvas then
		attention.canvas:hide()
		attention.canvas:delete()
		attention.canvas = nil
	end
	attention.visible = false
	if attention.escapeWatcher then
		attention.escapeWatcher:stop()
		attention.escapeWatcher = nil
	end
	if attention.clickWatcher then
		attention.clickWatcher:stop()
		attention.clickWatcher = nil
	end
	if attention.hoverWatcher then
		attention.hoverWatcher:stop()
		attention.hoverWatcher = nil
	end
	attention.currentView = "main"
	attention.clickableItems = {}
	attention.canvasFrame = nil
	attention.hoveredIndex = nil
	attention.scrollOffset = 0
	attention.currentIssue = nil
	attention.currentSlackMsg = nil
	attention.currentSlackThread = nil
end

function attention.toggle()
	if attention.visible then
		attention.hide()
	else
		attention.show()
	end
end

function attention.refresh()
	attention.fetchAll(function()
		print("Attention dashboard refreshed at " .. os.date("%Y-%m-%d %H:%M"))
	end)
end

-- Schedule daily refresh at 6am
function attention.scheduleDailyRefresh()
	if attention.dailyTimer then
		attention.dailyTimer:stop()
	end
	attention.dailyTimer = hs.timer.doAt("06:00", "1d", function()
		attention.refresh()
	end)
end

-- Initial fetch on startup if new day
function attention.init()
	attention.scheduleDailyRefresh()
	if attention.needsFetch() then
		attention.refresh()
	end
end

-- Expose globally
_G.attention = attention

-- Initialize on load
attention.init()

----------------------------------------------------------------------------------------------------

-- Override the modal binding function to preserve case of keys (add this before loading MenuHammer)
local originalBind = hs.hotkey.modal.bind
hs.hotkey.modal.bind = function(self, mods, key, message, pressedfn, releasedfn, repeatfn)
	local result = originalBind(self, mods, key, message, pressedfn, releasedfn, repeatfn)
	if key and #key == 1 then
		local lastKeyIndex = #result.keys
		result.keys[lastKeyIndex].msg = key
	end
	return result
end

local menuHammer = hs.loadSpoon("MenuHammer")
menuHammer:enter()

-- local function cmd(key, command)
-- 	hs.hotkey.bind({ "cmd" }, key, command)
-- end

local function shiftCtrl(key, command)
	hs.hotkey.bind({ "shift", "ctrl" }, key, command)
end

-- local function shiftCtrlAlt(key, command)
-- 	hs.hotkey.bind({ "shift", "ctrl", "alt" }, key, command)
-- end

-- local function shiftCtrlAltCmd(key, command)
-- 	hs.hotkey.bind({ "shift", "ctrl", "alt", "cmd" }, key, command)
-- end

local function runTask(command)
	hs.task
		.new("/bin/bash", function(exitCode, stdOut, stdErr)
			if exitCode ~= 0 then
				print("Error running command:", stdErr)
			else
				print("Command output:", stdOut)
			end
		end, { "-c", command })
		:start()
end

shiftCtrl("i", function()
	runTask("/opt/homebrew/bin/aerospace workspace-back-and-forth")
end)

shiftCtrl("p", function()
	runTask(
		"/opt/homebrew/bin/aerospace list-workspaces --monitor focused --empty no | /opt/homebrew/bin/aerospace workspace prev"
	)
end)

shiftCtrl("n", function()
	runTask(
		"/opt/homebrew/bin/aerospace list-workspaces --monitor focused --empty no | /opt/homebrew/bin/aerospace workspace next"
	)
end)

shiftCtrl("a", function()
	hs.task
		.new("/opt/homebrew/bin/aerospace", function(exitCode, stdOut, stdErr)
			if exitCode == 0 then
				local enabled = stdOut:match("true")
				if enabled then
					hs.alert.show("AeroSpace enabled")
				else
					hs.alert.show("AeroSpace disabled")
				end
			else
				print("Error toggling AeroSpace:", stdErr)
			end
		end, { "enable", "toggle" })
		:start()
end)

shiftCtrl("l", function()
	attention.toggle()
end)

-- shiftCtrl("e", function()
-- 	yabai({ "space --toggle show-desktop" })
-- end)
-- shiftCtrl("space", function()
-- 	yabai({ "window --toggle split" })
-- end)
-- shiftCtrl("return", function()
-- 	yabai({ "window --toggle zoom-fullscreen" })
-- end)

local function reloadConfig(files)
	local doReload = false
	for _, file in pairs(files) do
		if file:sub(-4) == ".lua" then
			doReload = true
		end
	end
	if doReload then
		hs.reload()
	end
end

local myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()

hs.alert.show("Hammerspoon config loaded")
