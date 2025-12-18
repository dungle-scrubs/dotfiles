--- Attention.spoon/ui/canvas/loader.lua
--- Loading indicator canvas

-- Use global path set by init.lua
local spoonPath = _G.AttentionSpoonPath
local helpers = dofile(spoonPath .. "/ui/canvas/helpers.lua")
local utils = dofile(spoonPath .. "/utils.lua")

---@class AttentionLoaderCanvas
local M = {}

--- Render the loading indicator canvas
--- @param state table The Attention spoon state object
--- @return hs.canvas canvas The created canvas
function M.render(state)
	-- Stop any existing loading animator
	if state.loadingAnimator then
		state.loadingAnimator.stop()
		state.loadingAnimator = nil
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
	c[3] = helpers.text(utils.getLoadingText(), {
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
	state.loadingAnimator = utils.createLoadingAnimator("Loading", function(text)
		if state.canvas and state.canvas[3] then
			state.canvas[3].text = text
		end
	end)

	return state.canvas
end

return M
