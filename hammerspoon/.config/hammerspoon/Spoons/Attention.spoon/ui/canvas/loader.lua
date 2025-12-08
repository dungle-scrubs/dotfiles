--- Attention.spoon/ui/canvas/loader.lua
--- Loading indicator canvas

-- Use global path set by init.lua
local spoonPath = _G.AttentionSpoonPath
local helpers = dofile(spoonPath .. "/ui/canvas/helpers.lua")

---@class AttentionLoaderCanvas
local M = {}

--- Render the loading indicator canvas
--- @param state table The Attention spoon state object
--- @return hs.canvas canvas The created canvas
function M.render(state)
	-- Stop any existing loading timer
	if state.loadingTimer then
		state.loadingTimer:stop()
		state.loadingTimer = nil
	end

	-- Calculate size based on last known size or default
	local boxWidth, boxHeight
	if state.lastCanvasSize then
		boxWidth = state.lastCanvasSize.w
		boxHeight = state.lastCanvasSize.h
	else
		boxWidth = 300
		boxHeight = 100
	end

	local frame = helpers.getCenteredFrame(boxWidth, boxHeight)

	-- Clean up existing canvas
	if state.canvas then
		state.canvas:delete()
	end

	-- Create new canvas
	state.canvas = hs.canvas.new(frame)
	state.canvasFrame = frame
	local c = state.canvas

	-- Add elements
	c[1] = helpers.background()
	c[2] = helpers.border()
	c[3] = helpers.text("Loading.  ", {
		x = 0,
		y = (boxHeight - helpers.fontSize) / 2,
		w = boxWidth,
		h = helpers.fontSize + 4,
		color = helpers.colors.accentPrimary,
		align = "center",
	})

	-- Configure canvas
	c:level(hs.canvas.windowLevels.overlay)
	c:clickActivating(false)
	c:show()
	state.visible = true

	-- Start loading animation
	state.loadingDots = 0
	state.loadingTimer = hs.timer.doEvery(0.3, function()
		state.loadingDots = (state.loadingDots % 3) + 1
		local dots = string.rep(".", state.loadingDots) .. string.rep(" ", 3 - state.loadingDots)
		if state.canvas and state.canvas[3] then
			state.canvas[3].text = "Loading" .. dots
		end
	end)

	return state.canvas
end

return M
