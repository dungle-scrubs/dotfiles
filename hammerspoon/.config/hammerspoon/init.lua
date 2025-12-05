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
-- Linear Tasks Overlay
----------------------------------------------------------------------------------------------------

local linearTasks = {}
linearTasks.canvas = nil
linearTasks.visible = false

-- Get API key from ~/.env/services/.env
local function getLinearApiKey()
	local envFile = os.getenv("HOME") .. "/.env/services/.env"
	local output, status = hs.execute("grep '^LINEAR_API_KEY=' " .. envFile .. " | cut -d= -f2-")
	if status and output and #output > 0 then
		-- Strip whitespace and quotes
		local value = output:gsub("^%s+", ""):gsub("%s+$", "")
		value = value:gsub('^"', ""):gsub('"$', ""):gsub("^'", ""):gsub("'$", "")
		if #value > 0 then
			return value
		end
	end
	return nil
end

function linearTasks.fetch(callback)
	local apiKey = getLinearApiKey()
	if not apiKey then
		hs.alert.show("LINEAR_API_KEY not found in ~/.env/services/.env")
		return
	end

	local query = [[
		query InProgressIssues {
			issues(filter: { state: { type: { eq: "started" } } }, first: 20) {
				nodes {
					identifier
					title
					state { name }
					project { name }
				}
			}
		}
	]]

	local headers = {
		["Authorization"] = apiKey,
		["Content-Type"] = "application/json",
	}

	local body = hs.json.encode({ query = query })

	hs.http.asyncPost(
		"https://api.linear.app/graphql",
		body,
		headers,
		function(status, response, responseHeaders)
			if status ~= 200 then
				hs.alert.show("Linear API error: " .. tostring(status))
				print("Linear error response:", response)
				return
			end

			local data = hs.json.decode(response)
			if data and data.data and data.data.issues then
				local issues = data.data.issues.nodes
				callback(issues)
			else
				hs.alert.show("Failed to parse Linear response")
				print("Linear parse error:", response)
			end
		end
	)
end

function linearTasks.showLoader()
	local font = "CaskaydiaCove Nerd Font Mono"
	local fontSize = 13
	local padding = 16
	local boxWidth = 300
	local boxHeight = 80

	local screen = hs.screen.mainScreen()
	local frame = screen:frame()
	local boxX = frame.x + (frame.w - boxWidth) / 2
	local boxY = frame.y + (frame.h - boxHeight) / 2

	if linearTasks.canvas then
		linearTasks.canvas:delete()
	end

	linearTasks.canvas = hs.canvas.new({ x = boxX, y = boxY, w = boxWidth, h = boxHeight })
	local c = linearTasks.canvas

	c[1] = {
		type = "rectangle",
		action = "fill",
		fillColor = { hex = "#1a1a1a", alpha = 0.95 },
		roundedRectRadii = { xRadius = 8, yRadius = 8 },
	}
	c[2] = {
		type = "rectangle",
		action = "stroke",
		strokeColor = { hex = "#5e6ad2", alpha = 0.9 },
		strokeWidth = 2,
		roundedRectRadii = { xRadius = 8, yRadius = 8 },
	}
	c[3] = {
		type = "text",
		text = "Loading Linear tasks...",
		textFont = font,
		textSize = fontSize,
		textColor = { hex = "#5e6ad2", alpha = 1 },
		textAlignment = "center",
		frame = { x = padding, y = (boxHeight - fontSize) / 2, w = boxWidth - (padding * 2), h = fontSize + 4 },
	}

	c:level(hs.canvas.windowLevels.overlay)
	c:clickActivating(false)
	c:show()
	linearTasks.visible = true
end

function linearTasks.show()
	linearTasks.showLoader()
	linearTasks.fetch(function(issues)
		if not issues or #issues == 0 then
			linearTasks.hide()
			hs.alert.show("No in-progress tasks")
			return
		end

		-- Group issues by project
		local projects = {}
		local projectOrder = {}
		for _, issue in ipairs(issues) do
			local projectName = issue.project and issue.project.name or "No Project"
			if not projects[projectName] then
				projects[projectName] = {}
				table.insert(projectOrder, projectName)
			end
			table.insert(projects[projectName], issue)
		end

		-- Calculate dimensions
		local font = "CaskaydiaCove Nerd Font Mono"
		local fontSize = 13
		local lineHeight = fontSize + 8
		local projectHeaderHeight = fontSize + 12
		local padding = 16
		local titleHeight = 28
		local projectSpacing = 8

		local maxTitleLen = 0
		for _, issue in ipairs(issues) do
			local displayText = issue.identifier .. " " .. issue.title
			if #displayText > maxTitleLen then
				maxTitleLen = #displayText
			end
		end

		local boxWidth = math.min(math.max(maxTitleLen * 8 + padding * 2, 400), 700)
		local contentHeight = titleHeight + (#issues * lineHeight) + (#projectOrder * (projectHeaderHeight + projectSpacing)) + (padding * 2) + 8

		-- Get screen dimensions
		local screen = hs.screen.mainScreen()
		local frame = screen:frame()

		-- Center on screen
		local boxX = frame.x + (frame.w - boxWidth) / 2
		local boxY = frame.y + (frame.h - contentHeight) / 2

		-- Create or reuse canvas
		if linearTasks.canvas then
			linearTasks.canvas:delete()
		end

		linearTasks.canvas = hs.canvas.new({ x = boxX, y = boxY, w = boxWidth, h = contentHeight })
		local c = linearTasks.canvas

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
			strokeColor = { hex = "#5e6ad2", alpha = 0.9 },
			strokeWidth = 2,
			roundedRectRadii = { xRadius = 8, yRadius = 8 },
		}

		-- Title
		c[3] = {
			type = "text",
			text = "Linear - In Progress (" .. #issues .. ")",
			textFont = font,
			textSize = fontSize + 2,
			textColor = { hex = "#5e6ad2", alpha = 1 },
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

		-- Render issues grouped by project
		local yPos = padding + titleHeight + 12

		for _, projectName in ipairs(projectOrder) do
			-- Project header
			c[#c + 1] = {
				type = "text",
				text = projectName,
				textFont = font,
				textSize = fontSize,
				textColor = { hex = "#f97316", alpha = 1 },
				textAlignment = "left",
				frame = { x = padding, y = yPos, w = boxWidth - (padding * 2), h = projectHeaderHeight },
			}
			yPos = yPos + projectHeaderHeight

			-- Project issues
			for _, issue in ipairs(projects[projectName]) do
				-- Issue identifier
				c[#c + 1] = {
					type = "text",
					text = issue.identifier,
					textFont = font,
					textSize = fontSize,
					textColor = { hex = "#8b8b8b", alpha = 1 },
					textAlignment = "left",
					frame = { x = padding + 12, y = yPos, w = 80, h = lineHeight },
				}

				-- Issue title (truncate if needed)
				local title = issue.title
				local maxChars = math.floor((boxWidth - padding * 2 - 100) / 7)
				if #title > maxChars then
					title = title:sub(1, maxChars - 1) .. "…"
				end

				c[#c + 1] = {
					type = "text",
					text = title,
					textFont = font,
					textSize = fontSize,
					textColor = { hex = "#ffffff", alpha = 1 },
					textAlignment = "left",
					frame = { x = padding + 97, y = yPos, w = boxWidth - padding - 102, h = lineHeight },
				}

				yPos = yPos + lineHeight
			end

			yPos = yPos + projectSpacing
		end

		c:level(hs.canvas.windowLevels.overlay)
		c:clickActivating(false)
		c:show()
		linearTasks.visible = true

		-- Auto-hide on click anywhere or after timeout
		linearTasks.escapeWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
			local keyCode = event:getKeyCode()
			if keyCode == 53 then -- Escape key
				linearTasks.hide()
				return true
			end
			return false
		end)
		linearTasks.escapeWatcher:start()

		linearTasks.clickWatcher = hs.eventtap.new({ hs.eventtap.event.types.leftMouseDown }, function()
			linearTasks.hide()
			return false
		end)
		linearTasks.clickWatcher:start()
	end)
end

function linearTasks.hide()
	if linearTasks.canvas then
		linearTasks.canvas:hide()
		linearTasks.canvas:delete()
		linearTasks.canvas = nil
		linearTasks.visible = false
	end
	if linearTasks.escapeWatcher then
		linearTasks.escapeWatcher:stop()
		linearTasks.escapeWatcher = nil
	end
	if linearTasks.clickWatcher then
		linearTasks.clickWatcher:stop()
		linearTasks.clickWatcher = nil
	end
end

function linearTasks.toggle()
	if linearTasks.visible then
		linearTasks.hide()
	else
		linearTasks.show()
	end
end

-- Expose globally
_G.linearTasks = linearTasks

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
	linearTasks.toggle()
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
