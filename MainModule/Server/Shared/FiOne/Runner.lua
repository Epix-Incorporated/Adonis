--!native
-- Multithreader - ccuser44
local fiOne = require(script.FiOne)
local actor = script.Parent
local event = script.ReturnPass
local callback = function(...) return ... end

actor:BindToMessage("lua_wrap_state", function(proto, env, upval)
	callback = fiOne.lua_wrap_state(proto, env, upval)
end)

actor:BindToMessageParallel("run_callback", function(tag, ...)
	event:Fire(tag, pcall(callback, ...))
end)
