--- Attention.spoon/api/openai.lua
--- OpenRouter API functions for AI chat (OpenAI-compatible)

local M = {}

-- Will be set by init.lua
M.getEnvVar = nil

--- Send a chat completion request to OpenRouter
--- @param messages table Array of message objects { role, content }
--- @param callback function Callback with (response, error)
--- @param options table|nil Optional settings { model, temperature, max_tokens }
function M.chatCompletion(messages, callback, options)
	local apiKey = M.getEnvVar("OPENROUTER_API_KEY")
	if not apiKey then
		callback(nil, "OPENROUTER_API_KEY not found")
		return
	end

	options = options or {}
	local model = options.model or "openai/gpt-4o-mini"
	local temperature = options.temperature or 0.7
	local maxTokens = options.max_tokens or 2048

	local requestBody = hs.json.encode({
		model = model,
		messages = messages,
		temperature = temperature,
		max_tokens = maxTokens,
	})

	hs.http.asyncPost(
		"https://openrouter.ai/api/v1/chat/completions",
		requestBody,
		{
			["Authorization"] = "Bearer " .. apiKey,
			["Content-Type"] = "application/json",
			["HTTP-Referer"] = "https://github.com/hammerspoon/hammerspoon",
			["X-Title"] = "Attention Dashboard",
		},
		function(status, response)
			if status ~= 200 then
				local errMsg = "OpenRouter API error: " .. tostring(status)
				if response then
					local data = hs.json.decode(response)
					if data and data.error and data.error.message then
						errMsg = data.error.message
					end
				end
				callback(nil, errMsg)
				return
			end

			local data = hs.json.decode(response)
			if data and data.choices and data.choices[1] and data.choices[1].message then
				-- Return the actual model used (important for openrouter/auto)
			local actualModel = data.model or model
			callback(data.choices[1].message.content, nil, actualModel)
			else
				callback(nil, "Failed to parse OpenAI response")
			end
		end
	)
end

--- Stream a chat completion (returns chunks via callback)
--- Note: Hammerspoon doesn't support true streaming, so this uses the non-streaming endpoint
--- @param messages table Array of message objects { role, content }
--- @param callback function Callback with (response, error)
function M.streamChatCompletion(messages, callback)
	-- Hammerspoon's http module doesn't support streaming
	-- Fall back to regular completion
	M.chatCompletion(messages, callback)
end

return M
