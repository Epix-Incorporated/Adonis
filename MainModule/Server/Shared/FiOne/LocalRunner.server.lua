--!native
--!optimize 2
--[[
	Description: Wrapper for FiOne multithread closures
	Author: github@ccuser44
	Date: 2024
	License: CC0
]]

local fiOne = require(script.FiOne)
local actor = script.Parent
local event = script.ReturnPass
local callback = function(...) return ... end

actor:BindToMessage("wrap_state", function(proto, env, upval)
	callback = fiOne.wrap_state(proto, env, upval)
end)

actor:BindToMessageParallel("run_callback", function(tag, ...)
	event:Fire(tag, pcall(callback, ...))
end)
