--!native
--# selene: allow(divide_by_zero, multiple_statements, mixed_table)
--[[
FiOne
Copyright (C) 2021  Rerumu

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
]] --

local lua_wrap_state
local stm_lua_func

-- SETLIST config
local FIELDS_PER_FLUSH = 50

-- remap for better lookup
local OPCODE_RM = {
	-- level 1
	[22] = 18, -- JMP
	[31] = 8, -- FORLOOP
	[33] = 28, -- TFORLOOP
	-- level 2
	[0] = 3, -- MOVE
	[1] = 13, -- LOADK
	[2] = 23, -- LOADBOOL
	[26] = 33, -- TEST
	-- level 3
	[12] = 1, -- ADD
	[13] = 6, -- SUB
	[14] = 10, -- MUL
	[15] = 16, -- DIV
	[16] = 20, -- MOD
	[17] = 26, -- POW
	[18] = 30, -- UNM
	[19] = 36, -- NOT
	-- level 4
	[3] = 0, -- LOADNIL
	[4] = 2, -- GETUPVAL
	[5] = 4, -- GETGLOBAL
	[6] = 7, -- GETTABLE
	[7] = 9, -- SETGLOBAL
	[8] = 12, -- SETUPVAL
	[9] = 14, -- SETTABLE
	[10] = 17, -- NEWTABLE
	[20] = 19, -- LEN
	[21] = 22, -- CONCAT
	[23] = 24, -- EQ
	[24] = 27, -- LT
	[25] = 29, -- LE
	[27] = 32, -- TESTSET
	[32] = 34, -- FORPREP
	[34] = 37, -- SETLIST
	-- level 5
	[11] = 5, -- SELF
	[28] = 11, -- CALL
	[29] = 15, -- TAILCALL
	[30] = 21, -- RETURN
	[35] = 25, -- CLOSE
	[36] = 31, -- CLOSURE
	[37] = 35, -- VARARG
}

-- opcode types for getting values
local OPCODE_T = {
	[0] = 'ABC',
	'ABx',
	'ABC',
	'ABC',
	'ABC',
	'ABx',
	'ABC',
	'ABx',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'AsBx',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'AsBx',
	'AsBx',
	'ABC',
	'ABC',
	'ABC',
	'ABx',
	'ABC',
}

local OPCODE_M = {
	[0] = {b = 'OpArgR', c = 'OpArgN'},
	{b = 'OpArgK', c = 'OpArgN'},
	{b = 'OpArgU', c = 'OpArgU'},
	{b = 'OpArgR', c = 'OpArgN'},
	{b = 'OpArgU', c = 'OpArgN'},
	{b = 'OpArgK', c = 'OpArgN'},
	{b = 'OpArgR', c = 'OpArgK'},
	{b = 'OpArgK', c = 'OpArgN'},
	{b = 'OpArgU', c = 'OpArgN'},
	{b = 'OpArgK', c = 'OpArgK'},
	{b = 'OpArgU', c = 'OpArgU'},
	{b = 'OpArgR', c = 'OpArgK'},
	{b = 'OpArgK', c = 'OpArgK'},
	{b = 'OpArgK', c = 'OpArgK'},
	{b = 'OpArgK', c = 'OpArgK'},
	{b = 'OpArgK', c = 'OpArgK'},
	{b = 'OpArgK', c = 'OpArgK'},
	{b = 'OpArgK', c = 'OpArgK'},
	{b = 'OpArgR', c = 'OpArgN'},
	{b = 'OpArgR', c = 'OpArgN'},
	{b = 'OpArgR', c = 'OpArgN'},
	{b = 'OpArgR', c = 'OpArgR'},
	{b = 'OpArgR', c = 'OpArgN'},
	{b = 'OpArgK', c = 'OpArgK'},
	{b = 'OpArgK', c = 'OpArgK'},
	{b = 'OpArgK', c = 'OpArgK'},
	{b = 'OpArgR', c = 'OpArgU'},
	{b = 'OpArgR', c = 'OpArgU'},
	{b = 'OpArgU', c = 'OpArgU'},
	{b = 'OpArgU', c = 'OpArgU'},
	{b = 'OpArgU', c = 'OpArgN'},
	{b = 'OpArgR', c = 'OpArgN'},
	{b = 'OpArgR', c = 'OpArgN'},
	{b = 'OpArgN', c = 'OpArgU'},
	{b = 'OpArgU', c = 'OpArgU'},
	{b = 'OpArgN', c = 'OpArgN'},
	{b = 'OpArgU', c = 'OpArgN'},
	{b = 'OpArgU', c = 'OpArgN'},
}

-- int rd_int_basic(string src, int s, int e, int d)
-- @src - Source binary string
-- @s - Start index of a little endian integer
-- @e - End index of the integer
-- @d - Direction of the loop
local function rd_int_basic(src, s, e, d)
	local num = 0

	-- if bb[l] > 127 then -- signed negative
	-- 	num = num - 256 ^ l
	-- 	bb[l] = bb[l] - 128
	-- end

	for i = s, e, d do
		local mul = 256 ^ math.abs(i - s)

		num = num + mul * string.byte(src, i, i)
	end

	return num
end

-- float rd_flt_basic(byte f1..8)
-- @f1..4 - The 4 bytes composing a little endian float
local function rd_flt_basic(f1, f2, f3, f4)
	local sign = (-1) ^ bit32.rshift(f4, 7)
	local exp = bit32.rshift(f3, 7) + bit32.lshift(bit32.band(f4, 0x7F), 1)
	local frac = f1 + bit32.lshift(f2, 8) + bit32.lshift(bit32.band(f3, 0x7F), 16)
	local normal = 1

	if exp == 0 then
		if frac == 0 then
			return sign * 0
		else
			normal = 0
			exp = 1
		end
	elseif exp == 0x7F then
		if frac == 0 then
			return sign * (1 / 0)
		else
			return sign * (0 / 0)
		end
	end

	return sign * 2 ^ (exp - 127) * (1 + normal / 2 ^ 23)
end

-- double rd_dbl_basic(byte f1..8)
-- @f1..8 - The 8 bytes composing a little endian double
local function rd_dbl_basic(f1, f2, f3, f4, f5, f6, f7, f8)
	local sign = (-1) ^ bit32.rshift(f8, 7)
	local exp = bit32.lshift(bit32.band(f8, 0x7F), 4) + bit32.rshift(f7, 4)
	local frac = bit32.band(f7, 0x0F) * 2 ^ 48
	local normal = 1

	frac = frac + (f6 * 2 ^ 40) + (f5 * 2 ^ 32) + (f4 * 2 ^ 24) + (f3 * 2 ^ 16) + (f2 * 2 ^ 8) + f1 -- help

	if exp == 0 then
		if frac == 0 then
			return sign * 0
		else
			normal = 0
			exp = 1
		end
	elseif exp == 0x7FF then
		if frac == 0 then
			return sign * (1 / 0)
		else
			return sign * (0 / 0)
		end
	end

	return sign * 2 ^ (exp - 1023) * (normal + frac / 2 ^ 52)
end

-- int rd_int_le(string src, int s, int e)
-- @src - Source binary string
-- @s - Start index of a little endian integer
-- @e - End index of the integer
local function rd_int_le(src, s, e) return rd_int_basic(src, s, e - 1, 1) end

-- int rd_int_be(string src, int s, int e)
-- @src - Source binary string
-- @s - Start index of a big endian integer
-- @e - End index of the integer
local function rd_int_be(src, s, e) return rd_int_basic(src, e - 1, s, -1) end

-- float rd_flt_le(string src, int s)
-- @src - Source binary string
-- @s - Start index of little endian float
local function rd_flt_le(src, s) return rd_flt_basic(string.byte(src, s, s + 3)) end

-- float rd_flt_be(string src, int s)
-- @src - Source binary string
-- @s - Start index of big endian float
local function rd_flt_be(src, s)
	local f1, f2, f3, f4 = string.byte(src, s, s + 3)
	return rd_flt_basic(f4, f3, f2, f1)
end

-- double rd_dbl_le(string src, int s)
-- @src - Source binary string
-- @s - Start index of little endian double
local function rd_dbl_le(src, s) return rd_dbl_basic(string.byte(src, s, s + 7)) end

-- double rd_dbl_be(string src, int s)
-- @src - Source binary string
-- @s - Start index of big endian double
local function rd_dbl_be(src, s)
	local f1, f2, f3, f4, f5, f6, f7, f8 = string.byte(src, s, s + 7) -- same
	return rd_dbl_basic(f8, f7, f6, f5, f4, f3, f2, f1)
end

-- to avoid nested ifs in deserializing
local float_types = {
	[4] = {little = rd_flt_le, big = rd_flt_be},
	[8] = {little = rd_dbl_le, big = rd_dbl_be},
}

-- byte stm_byte(Stream S)
-- @S - Stream object to read from
local function stm_byte(S)
	local idx = S.index
	local bt = string.byte(S.source, idx, idx)

	S.index = idx + 1
	return bt
end

-- string stm_string(Stream S, int len)
-- @S - Stream object to read from
-- @len - Length of string being read
local function stm_string(S, len)
	local pos = S.index + len
	local str = string.sub(S.source, S.index, pos - 1)

	S.index = pos
	return str
end

-- string stm_lstring(Stream S)
-- @S - Stream object to read from
local function stm_lstring(S)
	local len = S:s_szt()
	local str

	if len ~= 0 then str = string.sub(stm_string(S, len), 1, -2) end

	return str
end

-- fn cst_int_rdr(string src, int len, fn func)
-- @len - Length of type for reader
-- @func - Reader callback
local function cst_int_rdr(len, func)
	return function(S)
		local pos = S.index + len
		local int = func(S.source, S.index, pos)
		S.index = pos

		return int
	end
end

-- fn cst_flt_rdr(string src, int len, fn func)
-- @len - Length of type for reader
-- @func - Reader callback
local function cst_flt_rdr(len, func)
	return function(S)
		local flt = func(S.source, S.index)
		S.index = S.index + len

		return flt
	end
end

local function stm_inst_list(S)
	local len = S:s_int()
	local list = table.create(len)

	for i = 1, len do
		local ins = S:s_ins()
		local op = bit32.band(ins, 0x3F)
		local args = OPCODE_T[op]
		local mode = OPCODE_M[op]
		local data = {value = ins, op = OPCODE_RM[op], A = bit32.band(bit32.rshift(ins, 6), 0xFF)}

		if args == 'ABC' then
			data.B = bit32.band(bit32.rshift(ins, 23), 0x1FF)
			data.C = bit32.band(bit32.rshift(ins, 14), 0x1FF)
			data.is_KB = mode.b == 'OpArgK' and data.B > 0xFF -- post process optimization
			data.is_KC = mode.c == 'OpArgK' and data.C > 0xFF

			if op == 10 then -- decode NEWTABLE array size, store it as constant value
				local e = bit32.band(bit32.rshift(data.B, 3), 31)
				if e == 0 then
					data.const = data.B
				else
					data.const = bit32.lshift(bit32.band(data.B, 7) + 8, e - 1)
				end
			end
		elseif args == 'ABx' then
			data.Bx = bit32.band(bit32.rshift(ins, 14), 0x3FFFF)
			data.is_K = mode.b == 'OpArgK'
		elseif args == 'AsBx' then
			data.sBx = bit32.band(bit32.rshift(ins, 14), 0x3FFFF) - 131071
		end

		list[i] = data
	end

	return list
end

local function stm_const_list(S)
	local len = S:s_int()
	local list = table.create(len)

	for i = 1, len do
		local tt = stm_byte(S)
		local k

		if tt == 1 then
			k = stm_byte(S) ~= 0
		elseif tt == 3 then
			k = S:s_num()
		elseif tt == 4 then
			k = stm_lstring(S)
		end

		list[i] = k -- offset +1 during instruction decode
	end

	return list
end

local function stm_sub_list(S, src)
	local len = S:s_int()
	local list = table.create(len)

	for i = 1, len do
		list[i] = stm_lua_func(S, src) -- offset +1 in CLOSURE
	end

	return list
end

local function stm_line_list(S)
	local len = S:s_int()
	local list = table.create(len)

	for i = 1, len do list[i] = S:s_int() end

	return list
end

local function stm_loc_list(S)
	local len = S:s_int()
	local list = table.create(len)

	for i = 1, len do list[i] = {varname = stm_lstring(S), startpc = S:s_int(), endpc = S:s_int()} end

	return list
end

local function stm_upval_list(S)
	local len = S:s_int()
	local list = table.create(len)

	for i = 1, len do list[i] = stm_lstring(S) end

	return list
end

function stm_lua_func(S, psrc)
	local proto = {}
	local src = stm_lstring(S) or psrc -- source is propagated

	proto.source = src -- source name

	S:s_int() -- line defined
	S:s_int() -- last line defined

	proto.num_upval = stm_byte(S) -- num upvalues
	proto.num_param = stm_byte(S) -- num params

	stm_byte(S) -- vararg flag
	proto.max_stack = stm_byte(S) -- max stack size

	proto.code = stm_inst_list(S)
	proto.const = stm_const_list(S)
	proto.subs = stm_sub_list(S, src)
	proto.lines = stm_line_list(S)

	stm_loc_list(S)
	stm_upval_list(S)

	-- post process optimization
	for _, v in ipairs(proto.code) do
		if v.is_K then
			v.const = proto.const[v.Bx + 1] -- offset for 1 based index
		else
			if v.is_KB then v.const_B = proto.const[v.B - 0xFF] end

			if v.is_KC then v.const_C = proto.const[v.C - 0xFF] end
		end
	end

	return proto
end

local function lua_bc_to_state(src)
	-- func reader
	local rdr_func

	-- header flags
	local little
	local size_int
	local size_szt
	local size_ins
	local size_num
	local flag_int

	-- stream object
	local stream = {
		-- data
		index = 1,
		source = src,
	}

	assert(stm_string(stream, 4) == '\27Lua', 'invalid Lua signature')
	assert(stm_byte(stream) == 0x51, 'invalid Lua version')
	assert(stm_byte(stream) == 0, 'invalid Lua format')

	little = stm_byte(stream) ~= 0
	size_int = stm_byte(stream)
	size_szt = stm_byte(stream)
	size_ins = stm_byte(stream)
	size_num = stm_byte(stream)
	flag_int = stm_byte(stream) ~= 0

	rdr_func = little and rd_int_le or rd_int_be
	stream.s_int = cst_int_rdr(size_int, rdr_func)
	stream.s_szt = cst_int_rdr(size_szt, rdr_func)
	stream.s_ins = cst_int_rdr(size_ins, rdr_func)

	if flag_int then
		stream.s_num = cst_int_rdr(size_num, rdr_func)
	elseif float_types[size_num] then
		stream.s_num = cst_flt_rdr(size_num, float_types[size_num][little and 'little' or 'big'])
	else
		error('unsupported float size')
	end

	return stm_lua_func(stream, '@virtual')
end

local function close_lua_upvalues(list, index)
	for i, uv in pairs(list) do
		if uv.index >= index then
			uv.value = uv.store[uv.index] -- store value
			uv.store = uv
			uv.index = 'value' -- self reference
			list[i] = nil
		end
	end
end

local function open_lua_upvalue(list, index, memory)
	local prev = list[index]

	if not prev then
		prev = {index = index, store = memory}
		list[index] = prev
	end

	return prev
end

local function on_lua_error(failed, err)
	local src = failed.source
	local line = failed.lines[failed.pc - 1]

	error(string.format('%s:%i: %s', src, line, err), 0)
end

local function run_lua_func(state, env, upvals)
	local code = state.code
	local subs = state.subs
	local vararg = state.vararg

	local top_index = -1
	local open_list = {}
	local memory = state.memory
	local pc = state.pc

	while true do
		local inst = code[pc]
		local op = inst.op
		pc = pc + 1

		if op < 18 then
			if op < 8 then
				if op < 3 then
					if op < 1 then
						--[[LOADNIL]]
						for i = inst.A, inst.B do memory[i] = nil end
					elseif op > 1 then
						--[[GETUPVAL]]
						local uv = upvals[inst.B]

						memory[inst.A] = uv.store[uv.index]
					else
						--[[ADD]]
						local lhs, rhs

						if inst.is_KB then
							lhs = inst.const_B
						else
							lhs = memory[inst.B]
						end

						if inst.is_KC then
							rhs = inst.const_C
						else
							rhs = memory[inst.C]
						end

						memory[inst.A] = lhs + rhs
					end
				elseif op > 3 then
					if op < 6 then
						if op > 4 then
							--[[SELF]]
							local A = inst.A
							local B = inst.B
							local index

							if inst.is_KC then
								index = inst.const_C
							else
								index = memory[inst.C]
							end

							memory[A + 1] = memory[B]
							memory[A] = memory[B][index]
						else
							--[[GETGLOBAL]]
							memory[inst.A] = env[inst.const]
						end
					elseif op > 6 then
						--[[GETTABLE]]
						local index

						if inst.is_KC then
							index = inst.const_C
						else
							index = memory[inst.C]
						end

						memory[inst.A] = memory[inst.B][index]
					else
						--[[SUB]]
						local lhs, rhs

						if inst.is_KB then
							lhs = inst.const_B
						else
							lhs = memory[inst.B]
						end

						if inst.is_KC then
							rhs = inst.const_C
						else
							rhs = memory[inst.C]
						end

						memory[inst.A] = lhs - rhs
					end
				else --[[MOVE]]
					memory[inst.A] = memory[inst.B]
				end
			elseif op > 8 then
				if op < 13 then
					if op < 10 then
						--[[SETGLOBAL]]
						env[inst.const] = memory[inst.A]
					elseif op > 10 then
						if op < 12 then
							--[[CALL]]
							local A = inst.A
							local B = inst.B
							local C = inst.C
							local params

							if B == 0 then
								params = top_index - A
							else
								params = B - 1
							end

							local ret_list = table.pack(memory[A](table.unpack(memory, A + 1, A + params)))
							local ret_num = ret_list.n

							if C == 0 then
								top_index = A + ret_num - 1
							else
								ret_num = C - 1
							end

							table.move(ret_list, 1, ret_num, A, memory)
						else
							--[[SETUPVAL]]
							local uv = upvals[inst.B]

							uv.store[uv.index] = memory[inst.A]
						end
					else
						--[[MUL]]
						local lhs, rhs

						if inst.is_KB then
							lhs = inst.const_B
						else
							lhs = memory[inst.B]
						end

						if inst.is_KC then
							rhs = inst.const_C
						else
							rhs = memory[inst.C]
						end

						memory[inst.A] = lhs * rhs
					end
				elseif op > 13 then
					if op < 16 then
						if op > 14 then
							--[[TAILCALL]]
							local A = inst.A
							local B = inst.B
							local params

							if B == 0 then
								params = top_index - A
							else
								params = B - 1
							end

							close_lua_upvalues(open_list, 0)

							return memory[A](table.unpack(memory, A + 1, A + params))
						else
							--[[SETTABLE]]
							local index, value

							if inst.is_KB then
								index = inst.const_B
							else
								index = memory[inst.B]
							end

							if inst.is_KC then
								value = inst.const_C
							else
								value = memory[inst.C]
							end

							memory[inst.A][index] = value
						end
					elseif op > 16 then
						--[[NEWTABLE]]
						memory[inst.A] = table.create(inst.const) -- inst.const contains array size
					else
						--[[DIV]]
						local lhs, rhs

						if inst.is_KB then
							lhs = inst.const_B
						else
							lhs = memory[inst.B]
						end

						if inst.is_KC then
							rhs = inst.const_C
						else
							rhs = memory[inst.C]
						end

						memory[inst.A] = lhs / rhs
					end
				else
					--[[LOADK]]
					memory[inst.A] = inst.const
				end
			else
				--[[FORLOOP]]
				local A = inst.A
				local step = memory[A + 2]
				local index = memory[A] + step
				local limit = memory[A + 1]
				local loops

				if step == math.abs(step) then
					loops = index <= limit
				else
					loops = index >= limit
				end

				if loops then
					memory[A] = index
					memory[A + 3] = index
					pc = pc + inst.sBx
				end
			end
		elseif op > 18 then
			if op < 28 then
				if op < 23 then
					if op < 20 then
						--[[LEN]]
						memory[inst.A] = #memory[inst.B]
					elseif op > 20 then
						if op < 22 then
							--[[RETURN]]
							local A = inst.A
							local B = inst.B
							local len

							if B == 0 then
								len = top_index - A + 1
							else
								len = B - 1
							end

							close_lua_upvalues(open_list, 0)

							return table.unpack(memory, A, A + len - 1)
						else
							--[[CONCAT]]
							local B = inst.B
							local str = memory[B]

							for i = B + 1, inst.C do str = str .. memory[i] end

							memory[inst.A] = str
						end
					else
						--[[MOD]]
						local lhs, rhs

						if inst.is_KB then
							lhs = inst.const_B
						else
							lhs = memory[inst.B]
						end

						if inst.is_KC then
							rhs = inst.const_C
						else
							rhs = memory[inst.C]
						end

						memory[inst.A] = lhs % rhs
					end
				elseif op > 23 then
					if op < 26 then
						if op > 24 then
							--[[CLOSE]]
							close_lua_upvalues(open_list, inst.A)
						else
							--[[EQ]]
							local lhs, rhs

							if inst.is_KB then
								lhs = inst.const_B
							else
								lhs = memory[inst.B]
							end

							if inst.is_KC then
								rhs = inst.const_C
							else
								rhs = memory[inst.C]
							end

							if (lhs == rhs) == (inst.A ~= 0) then pc = pc + code[pc].sBx end

							pc = pc + 1
						end
					elseif op > 26 then
						--[[LT]]
						local lhs, rhs

						if inst.is_KB then
							lhs = inst.const_B
						else
							lhs = memory[inst.B]
						end

						if inst.is_KC then
							rhs = inst.const_C
						else
							rhs = memory[inst.C]
						end

						if (lhs < rhs) == (inst.A ~= 0) then pc = pc + code[pc].sBx end

						pc = pc + 1
					else
						--[[POW]]
						local lhs, rhs

						if inst.is_KB then
							lhs = inst.const_B
						else
							lhs = memory[inst.B]
						end

						if inst.is_KC then
							rhs = inst.const_C
						else
							rhs = memory[inst.C]
						end

						memory[inst.A] = lhs ^ rhs
					end
				else
					--[[LOADBOOL]]
					memory[inst.A] = inst.B ~= 0

					if inst.C ~= 0 then pc = pc + 1 end
				end
			elseif op > 28 then
				if op < 33 then
					if op < 30 then
						--[[LE]]
						local lhs, rhs

						if inst.is_KB then
							lhs = inst.const_B
						else
							lhs = memory[inst.B]
						end

						if inst.is_KC then
							rhs = inst.const_C
						else
							rhs = memory[inst.C]
						end

						if (lhs <= rhs) == (inst.A ~= 0) then pc = pc + code[pc].sBx end

						pc = pc + 1
					elseif op > 30 then
						if op < 32 then
							--[[CLOSURE]]
							local sub = subs[inst.Bx + 1] -- offset for 1 based index
							local nups = sub.num_upval
							local uvlist

							if nups ~= 0 then
								uvlist = table.create(nups - 1)

								for i = 1, nups do
									local pseudo = code[pc + i - 1]

									if pseudo.op == OPCODE_RM[0] then -- @MOVE
										uvlist[i - 1] = open_lua_upvalue(open_list, pseudo.B, memory)
									elseif pseudo.op == OPCODE_RM[4] then -- @GETUPVAL
										uvlist[i - 1] = upvals[pseudo.B]
									end
								end

								pc = pc + nups
							end

							memory[inst.A] = lua_wrap_state(sub, env, uvlist)
						else
							--[[TESTSET]]
							local A = inst.A
							local B = inst.B

							if (not memory[B]) ~= (inst.C ~= 0) then
								memory[A] = memory[B]
								pc = pc + code[pc].sBx
							end
							pc = pc + 1
						end
					else
						--[[UNM]]
						memory[inst.A] = -memory[inst.B]
					end
				elseif op > 33 then
					if op < 36 then
						if op > 34 then
							--[[VARARG]]
							local A = inst.A
							local len = inst.B

							if len == 0 then
								len = vararg.len
								top_index = A + len - 1
							end

							table.move(vararg.list, 1, len, A, memory)
						else
							--[[FORPREP]]
							local A = inst.A
							local init, limit, step

							init = assert(tonumber(memory[A]), '`for` initial value must be a number')
							limit = assert(tonumber(memory[A + 1]), '`for` limit must be a number')
							step = assert(tonumber(memory[A + 2]), '`for` step must be a number')

							memory[A] = init - step
							memory[A + 1] = limit
							memory[A + 2] = step

							pc = pc + inst.sBx
						end
					elseif op > 36 then
						--[[SETLIST]]
						local A = inst.A
						local C = inst.C
						local len = inst.B
						local tab = memory[A]
						local offset

						if len == 0 then len = top_index - A end

						if C == 0 then
							C = inst[pc].value
							pc = pc + 1
						end

						offset = (C - 1) * FIELDS_PER_FLUSH

						table.move(memory, A + 1, A + len, offset + 1, tab)
					else
						--[[NOT]]
						memory[inst.A] = not memory[inst.B]
					end
				else
					--[[TEST]]
					if (not memory[inst.A]) ~= (inst.C ~= 0) then pc = pc + code[pc].sBx end
					pc = pc + 1
				end
			else
				--[[TFORLOOP]]
				local A = inst.A
				local func = memory[A]
				local state = memory[A + 1]
				local index = memory[A + 2]
				local base = A + 3
				local vals

				-- === Luau compatibility - General iteration begin ===
				-- // ccuser44 added support for generic iteration
				-- (Please don't use general iteration in vanilla Lua code)
				if not index and not state and type(func) == "table" then
					-- Hacky check to see if __metatable is locked
					local canGetMt = pcall(getmetatable, func)
					local isMtLocked = canGetMt and not pcall(setmetatable, func, getmetatable(func)) or not canGetMt
					local metatable = canGetMt and getmetatable(func)

					if not (table.isfrozen and table.isfrozen(func)) and isMtLocked and not metatable then
						warn("[FiOne]: The table has a metatable buts it's hidden, __iter and __call won't work in forloop.")
					end

					if not (type(metatable) == "table" and rawget(metatable, "__call")) then
						func, state, index = (type(metatable) == "table" and rawget(metatable, "__iter") or next), func, nil
						memory[A], memory[A + 1], memory[A + 2] = func, state, index
					end
				end
				-- === Luau compatibility - General iteration end ===

				vals = {func(state, index)}

				table.move(vals, 1, inst.C, base, memory)

				if memory[base] ~= nil then
					memory[A + 2] = memory[base]
					pc = pc + code[pc].sBx
				end

				pc = pc + 1
			end
		else
			--[[JMP]]
			pc = pc + inst.sBx
		end

		state.pc = pc
	end
end

function lua_wrap_state(proto, env, upval)
	local function wrapped(...)
		local passed = table.pack(...)
		local memory = table.create(proto.max_stack)
		local vararg = {len = 0, list = {}}

		table.move(passed, 1, proto.num_param, 0, memory)

		if proto.num_param < passed.n then
			local start = proto.num_param + 1
			local len = passed.n - proto.num_param

			vararg.len = len
			table.move(passed, start, start + len - 1, 1, vararg.list)
		end

		local state = {vararg = vararg, memory = memory, code = proto.code, subs = proto.subs, pc = 1}

		local result = table.pack(pcall(run_lua_func, state, env, upval))

		if result[1] then
			return table.unpack(result, 2, result.n)
		else
			local failed = {pc = state.pc, source = proto.source, lines = proto.lines}

			on_lua_error(failed, result[2])

			return
		end
	end

	return wrapped
end

return function(BCode, Env)
	return lua_wrap_state(lua_bc_to_state(BCode), Env or {})
end
