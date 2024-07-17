-- Send message(s) to a running instance of yabai.
local function yabai(commands)
	for _, cmd in ipairs(commands) do
		os.execute("/opt/homebrew/bin/yabai -m " .. cmd)
	end
end

--[[ local function cmd(key, commands)
	hs.hotkey.bind({ "cmd" }, key, function()
		yabai(commands)
	end)
end ]]

local function shiftCtrl(key, commands)
	---@diagnostic disable-next-line: undefined-global
	hs.hotkey.bind({ "shift", "ctrl" }, key, function()
		yabai(commands)
	end)
end

local function shiftCtrlAlt(key, commands)
	---@diagnostic disable-next-line: undefined-global
	hs.hotkey.bind({ "shift", "ctrl", "alt" }, key, function()
		yabai(commands)
	end)
end

local function shiftCtrlAltCmd(key, commands)
	---@diagnostic disable-next-line: undefined-global
	hs.hotkey.bind({ "shift", "ctrl", "alt", "cmd" }, key, function()
		yabai(commands)
	end)
end

shiftCtrl("p", { "space --focus prev" })
shiftCtrl("n", { "space --focus next" })
shiftCtrl("e", { "space --toggle show-desktop" })
shiftCtrl("space", { "window --toggle split" })
shiftCtrl("return", { "window --toggle zoom-fullscreen" })

-- focus spaces
for i = 0, 9, 1 do
	shiftCtrl(tostring(i), { "space --focus " .. i })
end

-- move to window and focus
for i = 0, 9, 1 do
	shiftCtrlAlt(tostring(i), { "window --space " .. i .. " --focus" })
end

local directions = {
	h = "west",
	l = "east",
	k = "north",
	j = "south",
}

-- focus windoes
for k, v in pairs(directions) do
	shiftCtrl(k, { "window --focus " .. v })
end

-- swap windows
for k, v in pairs(directions) do
	shiftCtrlAlt(k, { "window --swap " .. v })
end

-- move spaces
for k, v in pairs(directions) do
	shiftCtrlAltCmd(k, { "window --warp " .. v })
end
