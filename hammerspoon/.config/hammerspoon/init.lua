require("hs.ipc")
hs.loadSpoon("EmmyLua")

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
