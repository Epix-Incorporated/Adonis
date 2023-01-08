--# selene: allow(incorrect_standard_library_use, multiple_statements, shadowing, unused_variable, empty_if, divide_by_zero, unbalanced_assignments)
--[[--------------------------------------------------------------------

  ldump.lua
  Save precompiled Lua chunks
  This file is part of Yueliang.

  Copyright (c) 2006 Kein-Hong Man <khman@users.sf.net>
  The COPYRIGHT file describes the conditions
  under which this software may be distributed.

  See the ChangeLog for more information.

----------------------------------------------------------------------]]

--[[--------------------------------------------------------------------
-- Notes:
-- * WARNING! byte order (little endian) and data type sizes for header
--   signature values hard-coded; see luaU:header
-- * chunk writer generators are included, see below
-- * one significant difference is that instructions are still in table
--   form (with OP/A/B/C/Bx fields) and luaP:Instruction() is needed to
--   convert them into 4-char strings
--
-- Not implemented:
-- * DumpVar, DumpMem has been removed
-- * DumpVector folded into folded into DumpDebug, DumpCode
--
-- Added:
-- * for convenience, the following two functions have been added:
--   luaU:make_setS: create a chunk writer that writes to a string
--   luaU:make_setF: create a chunk writer that writes to a file
--   (lua.h contains a typedef for lua_Writer/lua_Chunkwriter, and
--    a Lua-based implementation exists, writer() in lstrlib.c)
-- * luaU:ttype(o) (from lobject.h)
-- * for converting number types to its binary equivalent:
--   luaU:from_double(x): encode double value for writing
--   luaU:from_int(x): encode integer value for writing
--     (error checking is limited for these conversion functions)
--     (double conversion does not support denormals or NaNs)
--
-- Changed in 5.1.x:
-- * the dumper was mostly rewritten in Lua 5.1.x, so notes on the
--   differences between 5.0.x and 5.1.x is limited
-- * LUAC_VERSION bumped to 0x51, LUAC_FORMAT added
-- * developer is expected to adjust LUAC_FORMAT in order to identify
--   non-standard binary chunk formats
-- * header signature code is smaller, has been simplified, and is
--   tested as a single unit; its logic is shared with the undumper
-- * no more endian conversion, invalid endianness mean rejection
-- * opcode field sizes are no longer exposed in the header
-- * code moved to front of a prototype, followed by constants
-- * debug information moved to the end of the binary chunk, and the
--   relevant functions folded into a single function
-- * luaU:dump returns a writer status code
-- * chunk writer now implements status code because dumper uses it
-- * luaU:endianness removed
----------------------------------------------------------------------]]

--requires luaP
local luaU = {}
local luaP = require(script.Parent.LuaP)

-- mark for precompiled code ('<esc>Lua') (from lua.h)
luaU.LUA_SIGNATURE = "\27Lua"

-- constants used by dumper (from lua.h)
luaU.LUA_TNUMBER = 3
luaU.LUA_TSTRING = 4
luaU.LUA_TNIL = 0
luaU.LUA_TBOOLEAN = 1
luaU.LUA_TNONE = -1

-- constants for header of binary files (from lundump.h)
luaU.LUAC_VERSION = 0x51 -- this is Lua 5.1
luaU.LUAC_FORMAT = 0 -- this is the official format
luaU.LUAC_HEADERSIZE = 12 -- size of header of binary files

--[[--------------------------------------------------------------------
-- Additional functions to handle chunk writing
-- * to use make_setS and make_setF, see test_ldump.lua elsewhere
----------------------------------------------------------------------]]

------------------------------------------------------------------------
-- create a chunk writer that writes to a string
-- * returns the writer function and a table containing the string
-- * to get the final result, look in buff.data
------------------------------------------------------------------------
function luaU:make_setS()
	local buff = {}
	buff.data = ""
	local writer = function(s, buff) -- chunk writer
		if not s then
			return 0
		end
		buff.data = buff.data .. s
		return 0
	end
	return writer, buff
end

------------------------------------------------------------------------
-- create a chunk writer that writes to a file
-- * returns the writer function and a table containing the file handle
-- * if a nil is passed, then writer should close the open file
------------------------------------------------------------------------

--[[
function luaU:make_setF(filename)
  local buff = {}
        buff.h = io.open(filename, "wb")
  if not buff.h then return nil end
  local writer =
    function(s, buff)  -- chunk writer
      if not buff.h then return 0 end
      if not s then
        if buff.h:close() then return 0 end
      else
        if buff.h:write(s) then return 0 end
      end
      return 1
    end
  return writer, buff
end--]]

------------------------------------------------------------------------
-- works like the lobject.h version except that TObject used in these
-- scripts only has a 'value' field, no 'tt' field (native types used)
------------------------------------------------------------------------
function luaU:ttype(o)
	local tt = type(o.value)
	if tt == "number" then
		return self.LUA_TNUMBER
	elseif tt == "string" then
		return self.LUA_TSTRING
	elseif tt == "nil" then
		return self.LUA_TNIL
	elseif tt == "boolean" then
		return self.LUA_TBOOLEAN
	else
		return self.LUA_TNONE -- the rest should not appear
	end
end

-----------------------------------------------------------------------
-- converts a IEEE754 double number to an 8-byte little-endian string
-- * luaU:from_double() and luaU:from_int() are adapted from ChunkBake
-- * supports +/- Infinity, but not denormals or NaNs
-----------------------------------------------------------------------
function luaU:from_double(x)
	local function grab_byte(v)
		local c = v % 256
		return (v - c) / 256, string.char(c)
	end
	local sign = 0
	if x < 0 then
		sign = 1
		x = -x
	end
	local mantissa, exponent = math.frexp(x)
	if x == 0 then -- zero
		mantissa, exponent = 0, 0
	elseif x == 1 / 0 then
		mantissa, exponent = 0, 2047
	else
		mantissa = (mantissa * 2 - 1) * math.ldexp(0.5, 53)
		exponent = exponent + 1022
	end
	local v, byte = "" -- convert to bytes
	x = math.floor(mantissa)
	for i = 1, 6 do
		x, byte = grab_byte(x)
		v = v .. byte -- 47:0
	end
	x, byte = grab_byte(exponent * 16 + x)
	v = v .. byte -- 55:48
	x, byte = grab_byte(sign * 128 + x)
	v = v .. byte -- 63:56
	return v
end

-----------------------------------------------------------------------
-- converts a number to a little-endian 32-bit integer string
-- * input value assumed to not overflow, can be signed/unsigned
-----------------------------------------------------------------------
function luaU:from_int(x)
	local v = ""
	x = math.floor(x)
	if x < 0 then
		x = 4294967296 + x
	end -- ULONG_MAX+1
	for i = 1, 4 do
		local c = x % 256
		v = v .. string.char(c)
		x = math.floor(x / 256)
	end
	return v
end

--[[--------------------------------------------------------------------
-- Functions to make a binary chunk
-- * many functions have the size parameter removed, since output is
--   in the form of a string and some sizes are implicit or hard-coded
----------------------------------------------------------------------]]

--[[--------------------------------------------------------------------
-- struct DumpState:
--   L  -- lua_State (not used in this script)
--   writer  -- lua_Writer (chunk writer function)
--   data  -- void* (chunk writer context or data already written)
--   strip  -- if true, don't write any debug information
--   status  -- if non-zero, an error has occured
----------------------------------------------------------------------]]

------------------------------------------------------------------------
-- dumps a block of bytes
-- * lua_unlock(D.L), lua_lock(D.L) unused
------------------------------------------------------------------------
function luaU:DumpBlock(b, D)
	if D.status == 0 then
		-- lua_unlock(D->L);
		D.status = D.write(b, D.data)
		-- lua_lock(D->L);
	end
end

------------------------------------------------------------------------
-- dumps a char
------------------------------------------------------------------------
function luaU:DumpChar(y, D)
	self:DumpBlock(string.char(y), D)
end

------------------------------------------------------------------------
-- dumps a 32-bit signed or unsigned integer (for int) (hard-coded)
------------------------------------------------------------------------
function luaU:DumpInt(x, D)
	self:DumpBlock(self:from_int(x), D)
end

------------------------------------------------------------------------
-- dumps a lua_Number (hard-coded as a double)
------------------------------------------------------------------------
function luaU:DumpNumber(x, D)
	self:DumpBlock(self:from_double(x), D)
end

------------------------------------------------------------------------
-- dumps a Lua string (size type is hard-coded)
------------------------------------------------------------------------
function luaU:DumpString(s, D)
	if s == nil then
		self:DumpInt(0, D)
	else
		s = s .. "\0" -- include trailing '\0'
		self:DumpInt(#s, D)
		self:DumpBlock(s, D)
	end
end

------------------------------------------------------------------------
-- dumps instruction block from function prototype
------------------------------------------------------------------------
function luaU:DumpCode(f, D)
	local n = f.sizecode
	--was DumpVector
	self:DumpInt(n, D)
	for i = 0, n - 1 do
		self:DumpBlock(luaP:Instruction(f.code[i]), D)
	end
end

------------------------------------------------------------------------
-- dump constant pool from function prototype
-- * bvalue(o), nvalue(o) and rawtsvalue(o) macros removed
------------------------------------------------------------------------
function luaU:DumpConstants(f, D)
	local n = f.sizek
	self:DumpInt(n, D)
	for i = 0, n - 1 do
		local o = f.k[i] -- TValue
		local tt = self:ttype(o)
		self:DumpChar(tt, D)
		if tt == self.LUA_TNIL then
		elseif tt == self.LUA_TBOOLEAN then
			self:DumpChar(o.value and 1 or 0, D)
		elseif tt == self.LUA_TNUMBER then
			self:DumpNumber(o.value, D)
		elseif tt == self.LUA_TSTRING then
			self:DumpString(o.value, D)
		else
			--lua_assert(0)  -- cannot happen
		end
	end
	n = f.sizep
	self:DumpInt(n, D)
	for i = 0, n - 1 do
		self:DumpFunction(f.p[i], f.source, D)
	end
end

------------------------------------------------------------------------
-- dump debug information
------------------------------------------------------------------------
function luaU:DumpDebug(f, D)
	local n
	n = D.strip and 0 or f.sizelineinfo -- dump line information
	--was DumpVector
	self:DumpInt(n, D)
	for i = 0, n - 1 do
		self:DumpInt(f.lineinfo[i], D)
	end
	n = D.strip and 0 or f.sizelocvars -- dump local information
	self:DumpInt(n, D)
	for i = 0, n - 1 do
		self:DumpString(f.locvars[i].varname, D)
		self:DumpInt(f.locvars[i].startpc, D)
		self:DumpInt(f.locvars[i].endpc, D)
	end
	n = D.strip and 0 or f.sizeupvalues -- dump upvalue information
	self:DumpInt(n, D)
	for i = 0, n - 1 do
		self:DumpString(f.upvalues[i], D)
	end
end

------------------------------------------------------------------------
-- dump child function prototypes from function prototype
------------------------------------------------------------------------
function luaU:DumpFunction(f, p, D)
	local source = f.source
	if source == p or D.strip then
		source = nil
	end
	self:DumpString(source, D)
	self:DumpInt(f.lineDefined, D)
	self:DumpInt(f.lastlinedefined, D)
	self:DumpChar(f.nups, D)
	self:DumpChar(f.numparams, D)
	self:DumpChar(f.is_vararg, D)
	self:DumpChar(f.maxstacksize, D)
	self:DumpCode(f, D)
	self:DumpConstants(f, D)
	self:DumpDebug(f, D)
end

------------------------------------------------------------------------
-- dump Lua header section (some sizes hard-coded)
------------------------------------------------------------------------
function luaU:DumpHeader(D)
	local h = self:header()
	assert(#h == self.LUAC_HEADERSIZE) -- fixed buffer now an assert
	self:DumpBlock(h, D)
end

------------------------------------------------------------------------
-- make header (from lundump.c)
-- returns the header string
------------------------------------------------------------------------
function luaU:header()
	local x = 1
	return self.LUA_SIGNATURE
		.. string.char(
			self.LUAC_VERSION,
			self.LUAC_FORMAT,
			x, -- endianness (1=little)
			4, -- sizeof(int)
			4, -- sizeof(size_t)
			4, -- sizeof(Instruction)
			8, -- sizeof(lua_Number)
			0
		) -- is lua_Number integral?
end

------------------------------------------------------------------------
-- dump Lua function as precompiled chunk
-- (lua_State* L, const Proto* f, lua_Writer w, void* data, int strip)
-- * w, data are created from make_setS, make_setF
------------------------------------------------------------------------
function luaU:dump(L, f, w, data, strip)
	local D = {} -- DumpState
	D.L = L
	D.write = w
	D.data = data
	D.strip = strip
	D.status = 0
	self:DumpHeader(D)
	self:DumpFunction(f, nil, D)
	-- added: for a chunk writer writing to a file, this final call with
	-- nil data is to indicate to the writer to close the file
	D.write(nil, D.data)
	return D.status
end

return luaU
