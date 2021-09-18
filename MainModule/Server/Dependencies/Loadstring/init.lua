--[[
	Credit to einsteinK.
	Credit to Stravant for LBI.
	
	Credit to the creators of all the other modules used in this.
	(Yueliang is made by Kein-Hong Man,
	FiOne by Rerumu
	)
	
	Sceleratis was here and decided modify some things.
	
	einsteinK was here again to fix a bug in LBI for if-statements

	Github@ccuser44(ALE111_boiPNG) was here to to make some small changes (made it use vanilla loadstring when possible)
--]]

local waitDeps = {
	"FiOne";
	"LuaK";
	"LuaP";
	"LuaU";
	"LuaX";
	"LuaY";
	"LuaZ";
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

local isLoadstringEnabled = pcall(loadstring, "local a = 5 local c = a + 1")

return function(str, env)
	local f, writer, buff, name, error, success

	if isLoadstringEnabled then
		success, error = pcall(function()
			f = loadstring(str)
			setfenv(f, env)
		end)
	else
		local env = env or getfenv(2)
		local name = (env.script and env.script:GetFullName())
		success, error = pcall(function()
			local zio = luaZ:init(luaZ:make_getS(str), nil)
			if not zio then
				return error()
			end
			local func = luaY:parser(LuaState, zio, nil, name or "::Adonis::Loadstring::")
			writer, buff = luaU:make_setS()
			luaU:dump(LuaState, func, writer, buff)
			f = fiOne(buff.data, env)
		end)
	end

	if success then
		return f, (buff and buff.data)
	else
		return nil, error
	end
end
