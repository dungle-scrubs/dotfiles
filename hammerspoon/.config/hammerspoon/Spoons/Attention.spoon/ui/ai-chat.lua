--- Attention.spoon/ui/ai-chat.lua
--- AI Chat webview using compiled Preact bundle

-- Use global path set by init.lua
local spoonPath = _G.AttentionSpoonPath
local styles = dofile(spoonPath .. "/ui/styles.lua")

---@class AttentionAiChatUI
local M = {}

-- Dependencies (set by init.lua)
M.openaiApi = nil
M.getEnvVar = nil

-- State
M.webview = nil
M.webviewUC = nil
M.conversation = {}
M.isLoading = false
M.currentModel = "openai/gpt-4o-mini"
M.previousWindow = nil  -- Window that had focus before AI chat opened

-- Load the bundled JS once
local bundlePath = spoonPath .. "/webview/dist/ai-chat.js"
local bundleFile = io.open(bundlePath, "r")
local bundledJS = bundleFile and bundleFile:read("*all") or ""
if bundleFile then bundleFile:close() end

if bundledJS == "" then
	print("[AiChat] WARNING: Could not load ai-chat.js from " .. bundlePath)
end

--- Show the AI chat overlay
--- @param initialQuery string|nil Optional initial query text
--- @param callbacks table Callbacks { onClose }
function M.show(initialQuery, callbacks)
	if M.webview then
		M.close()
	end

	-- Save the currently focused window to restore later (if not already set by caller)
	if not M.previousWindow then
		M.previousWindow = hs.window.focusedWindow()
	end

	M.conversation = {}
	M.isLoading = false
	callbacks = callbacks or {}

	local screen = hs.screen.mainScreen()
	local screenFrame = screen:frame()

	-- Center modal
	local width = 1200
	local height = 1000
	local x = screenFrame.x + (screenFrame.w - width) / 2
	local y = screenFrame.y + (screenFrame.h - height) / 2

	-- Get CSS from shared styles module
	local css = styles.getAiChatWebviewCSS()

	-- Build HTML with bundled JS
	local html = [[
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
]] .. css .. [[
</style>
</head>
<body>
<div id="app"></div>
<script>
// Initialize app state before bundle runs
window.appState = {
	messages: [],
	isLoading: false,
	initialQuery: ]] .. hs.json.encode({ q = initialQuery or "" }) .. [[.q,
	currentModel: ]] .. hs.json.encode({ m = M.currentModel }) .. [[.m
};
</script>
<script>
]] .. bundledJS .. [[
</script>
</body>
</html>
]]

	-- Create user content controller for message passing
	M.webviewUC = hs.webview.usercontent.new("hammerspoon")
	M.webviewUC:setCallback(function(message)
		local body = message.body
		if body.action == "close" then
			M.close()
			if callbacks.onClose then
				callbacks.onClose()
			end
		elseif body.action == "send" then
			M.sendMessage(body.message)
		elseif body.action == "setModel" then
			M.currentModel = body.model
			print("[AiChat] Model changed to: " .. M.currentModel)
		end
	end)

	-- Create webview
	M.webview = hs.webview.new(
		{ x = x, y = y, w = width, h = height },
		{ developerExtrasEnabled = true },
		M.webviewUC
	)
	M.webview:windowStyle({ "borderless" })
	M.webview:allowTextEntry(true)
	M.webview:level(hs.canvas.windowLevels.modalPanel)
	M.webview:transparent(true)

	M.webview:html(html)
	M.webview:show()

	-- Focus the webview window
	local win = M.webview:hswindow()
	if win then win:focus() end
end

--- Send a message to the AI
--- @param userMessage string The user's message
function M.sendMessage(userMessage)
	if M.isLoading then return end
	M.isLoading = true

	-- Add to conversation history
	table.insert(M.conversation, { role = "user", content = userMessage })

	-- Build messages for API
	local messages = {
		{ role = "system", content = "You are a helpful AI assistant. Be concise and direct in your responses." },
	}
	for _, msg in ipairs(M.conversation) do
		table.insert(messages, msg)
	end

	-- Call OpenAI API with current model
	M.openaiApi.chatCompletion(messages, function(response, err, actualModel)
		M.isLoading = false

		if err then
			if M.webview then
				-- Wrap in table since hs.json.encode only accepts tables
				M.webview:evaluateJavaScript("window.receiveResponse && window.receiveResponse(" .. hs.json.encode({ r = err }) .. ".r, true);", function() end)
			end
		else
			-- Add assistant response to history
			table.insert(M.conversation, { role = "assistant", content = response })
			if M.webview then
				-- Always pass model: prefer actual model from API, fallback to selected model
				local modelToShow = actualModel or M.currentModel
				M.webview:evaluateJavaScript("window.receiveResponse && window.receiveResponse(" .. hs.json.encode({ r = response, m = modelToShow }) .. ".r, false, " .. hs.json.encode({ m = modelToShow }) .. ".m);", function() end)
			end
		end
	end, { model = M.currentModel })
end

--- Close the AI chat overlay and restore focus to previous app
--- @param restoreFocus boolean|nil Whether to restore focus (default true)
function M.close(restoreFocus)
	if restoreFocus == nil then restoreFocus = true end
	local windowToRestore = M.previousWindow
	if M.webview then
		-- Hide immediately for perceived speed, then delete
		M.webview:hide()
		M.webview:delete()
		M.webview = nil
	end
	M.webviewUC = nil
	M.conversation = {}
	M.isLoading = false
	M.previousWindow = nil
	-- Restore focus to the previously focused window (slight delay for cleanup)
	if restoreFocus and windowToRestore then
		hs.timer.doAfter(0.05, function()
			if windowToRestore:isVisible() then
				windowToRestore:focus()
			end
		end)
	end
end

--- Get the previous window (for passing to dashboard on back)
--- @return hs.window|nil
function M.getPreviousWindow()
	return M.previousWindow
end

--- Check if chat is visible
--- @return boolean
function M.isVisible()
	return M.webview ~= nil
end

return M
