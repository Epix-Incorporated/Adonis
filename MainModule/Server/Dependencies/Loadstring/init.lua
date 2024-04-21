--[[
	Credit to einsteinK.
	Credit to Stravant for LBI.
	Credit to ccuser44 for proto conversion.

	Credit to the creators of all the other modules used in this.
	
	Sceleratis was here and decided modify some things.
	
	einsteinK was here again to fix a bug in LBI for if-statements
--]]

local PROTO_CONVERT = true -- If proto conversion is used instead of serialise->deserialise
local DEPENDANCIES = {
	"FiOne";
	"LuaK";
	"LuaP";
	"LuaU";
	"LuaX";
	"LuaY";
	"LuaZ";
}

for _, v in ipairs(DEPENDANCIES) do 
	script:WaitForChild(v)
end

local luaX = require(script.LuaX)
local luaY = require(script.LuaY)
local luaZ = require(script.LuaZ)
local luaU = require(script.LuaU)
local loadBytecode, fiOne = require(script.FiOne)

local function to1BasedIndex(tbl)
	local tbl = table.move(tbl, 0, #tbl + (tbl[0] and 1), 1)
	tbl[0] = nil

	return tbl
end

local function protoConvert(proto, opRemap, opType, opMode)
	local const = table.create(#proto.k + 1)
	proto.code, proto.lines, proto.subs = to1BasedIndex(proto.code), to1BasedIndex(proto.lineinfo), to1BasedIndex(proto.p)
	proto.linfeinfo, proto.p = nil, nil
	proto.max_stack, proto.maxstacksize = proto.maxstacksize, nil
	proto.num_param, proto.numparams = proto.numparams, nil
	proto.num_upval, proto.sizeupvalues = proto.sizeupvalues, nil
	proto.sizecode, proto.sizek, proto.sizelineinfo, proto.sizelocvars, proto.sizep = nil, nil, nil, nil, nil -- Clean up garbage values

	for i, v in to1BasedIndex(proto.k) do
		const[i] = v.value
	end

	proto.const, proto.k = const, nil

	for i, v in proto.code do
		local op = v.OP
		v.op, v.OP = opRemap[op], nil
		local regType = opType[op]
		local mode = opMode[op]

		if regType == "ABC" then
			v.is_KB = mode.b == "OpArgK" and v.B > 0xFF -- post process optimization
			v.is_KC = mode.c == "OpArgK" and v.C > 0xFF

			if op == 10 then -- decode NEWTABLE array size, store it as constant value
				local e = bit32.band(bit32.rshift(data.B, 3), 31)
				if e == 0 then
					v.const = v.B
				else
					v.const = bit32.lshift(bit32.band(v.B, 7) + 8, e - 1)
				end
			end
		elseif regType == "ABx" then
			v.is_K = mode.b == "OpArgK"
		end

		if v.is_K then
			v.const = proto.const[v.Bx + 1] -- offset for 1 based index
		else
			if v.is_KB then v.const_B = proto.const[v.B - 0xFF] end

			if v.is_KC then v.const_C = proto.const[v.C - 0xFF] end
		end
	end

	for _, v in proto.subs do
		protoConvert(v, opRemap, opType, opMode)
	end
end

luaX:init()
local LuaState = {}

getfenv().script = nil

return function(str, env)
	local f, writer, buff
	env = env or getfenv(2)
	local name = (type(env.script) == "userdata" and env.script:GetFullName())
	local ran, error = xpcall(function()
		local zio = luaZ:init(luaZ:make_getS(str), nil)
		if not zio then return error() end
		local func = luaY:parser(LuaState, zio, nil, name or "::Adonis::Loadstring::")

		if PROTO_CONVERT then
			protoConvert(func, fiOne.opcode_rm, fiOne.opcode_t, fiOne.opcode_m)
			f = loadBytecode(func, env)
		else
			writer, buff = luaU:make_setS()
			luaU:dump(LuaState, func, writer, buff)
			f = loadBytecode(buff.data, env)
		end
	end, function(err)
		return `{err}\n\n--- Loadstring Stacktrace Begin --- \n{debug.traceback("",2)}\n--- Loadstring Stacktrace End --- \n`
	end)
	
	if ran then
		return f, buff.data
	else
		return nil, error
	end
end
