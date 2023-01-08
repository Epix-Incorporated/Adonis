--[[
	Credit to einsteinK.
	Credit to Stravant for LBI.
	
	Credit to the creators of all the other modules used in this.
	
	Sceleratis was here and decided modify some things.
	
	einsteinK was here again to fix a bug in LBI for if-statements
--]]

local waitDeps = {
	"FiOne",
	"LuaK",
	"LuaP",
	"LuaU",
	"LuaX",
	"LuaY",
	"LuaZ",
}

for _, v in ipairs(waitDeps) do
	script:WaitForChild(v)
end

local luaX = require(script.LuaX)
local luaY = require(script.LuaY)
local luaZ = require(script.LuaZ)
local luaU = require(script.LuaU)
local fiOne = require(script.FiOne)

luaX:init()
local LuaState = {}

getfenv().script = nil

return function(str, env)
	local f, writer, buff
	env = env or getfenv(2)
	local name = (env.script and env.script:GetFullName())
	local ran, error = pcall(function()
		local zio = luaZ:init(luaZ:make_getS(str), nil)
		if not zio then
			return error()
		end
		local func = luaY:parser(LuaState, zio, nil, name or "::Adonis::Loadstring::")
		writer, buff = luaU:make_setS()
		luaU:dump(LuaState, func, writer, buff)
		f = fiOne(buff.data, env)
	end)

	if ran then
		return f, buff.data
	else
		return nil, error
	end
end
