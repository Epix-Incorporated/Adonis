--!nocheck
--# selene: allow(incorrect_standard_library_use, multiple_statements, shadowing, unused_variable, empty_if, divide_by_zero, unbalanced_assignments)
--[[--------------------------------------------------------------------

  lopcodes.lua
  Lua 5 virtual machine opcodes in Lua
  This file is part of Yueliang.

  Copyright (c) 2006 Kein-Hong Man <khman@users.sf.net>
  The COPYRIGHT file describes the conditions
  under which this software may be distributed.

  See the ChangeLog for more information.

----------------------------------------------------------------------]]

--[[--------------------------------------------------------------------
-- Notes:
-- * an Instruction is a table with OP, A, B, C, Bx elements; this
--   makes the code easy to follow and should allow instruction handling
--   to work with doubles and ints
-- * WARNING luaP:Instruction outputs instructions encoded in little-
--   endian form and field size and positions are hard-coded
--
-- Not implemented:
-- *
--
-- Added:
-- * luaP:CREATE_Inst(c): create an inst from a number (for OP_SETLIST)
-- * luaP:Instruction(i): convert field elements to a 4-char string
-- * luaP:DecodeInst(x): convert 4-char string into field elements
--
-- Changed in 5.1.x:
-- * POS_OP added, instruction field positions changed
-- * some symbol names may have changed, e.g. LUAI_BITSINT
-- * new operators for RK indices: BITRK, ISK(x), INDEXK(r), RKASK(x)
-- * OP_MOD, OP_LEN is new
-- * OP_TEST is now OP_TESTSET, OP_TEST is new
-- * OP_FORLOOP, OP_TFORLOOP adjusted, OP_FORPREP is new
-- * OP_TFORPREP deleted
-- * OP_SETLIST and OP_SETLISTO merged and extended
-- * OP_VARARG is new
-- * many changes to implementation of OpMode data
----------------------------------------------------------------------]]

local luaP = {}

--[[
===========================================================================
  We assume that instructions are unsigned numbers.
  All instructions have an opcode in the first 6 bits.
  Instructions can have the following fields:
        'A' : 8 bits
        'B' : 9 bits
        'C' : 9 bits
        'Bx' : 18 bits ('B' and 'C' together)
        'sBx' : signed Bx

  A signed argument is represented in excess K; that is, the number
  value is the unsigned value minus K. K is exactly the maximum value
  for that argument (so that -max is represented by 0, and +max is
  represented by 2*max), which is half the maximum for the corresponding
  unsigned argument.
===========================================================================
--]]

luaP.OpMode = { iABC = 0, iABx = 1, iAsBx = 2 } -- basic instruction format

------------------------------------------------------------------------
-- size and position of opcode arguments.
-- * WARNING size and position is hard-coded elsewhere in this script
------------------------------------------------------------------------
luaP.SIZE_C = 9
luaP.SIZE_B = 9
luaP.SIZE_Bx = luaP.SIZE_C + luaP.SIZE_B
luaP.SIZE_A = 8

luaP.SIZE_OP = 6

luaP.POS_OP = 0
luaP.POS_A = luaP.POS_OP + luaP.SIZE_OP
luaP.POS_C = luaP.POS_A + luaP.SIZE_A
luaP.POS_B = luaP.POS_C + luaP.SIZE_C
luaP.POS_Bx = luaP.POS_C

------------------------------------------------------------------------
-- limits for opcode arguments.
-- we use (signed) int to manipulate most arguments,
-- so they must fit in LUAI_BITSINT-1 bits (-1 for sign)
------------------------------------------------------------------------
-- removed "#if SIZE_Bx < BITS_INT-1" test, assume this script is
-- running on a Lua VM with double or int as LUA_NUMBER

luaP.MAXARG_Bx = math.ldexp(1, luaP.SIZE_Bx) - 1
luaP.MAXARG_sBx = math.floor(luaP.MAXARG_Bx / 2) -- 'sBx' is signed

luaP.MAXARG_A = math.ldexp(1, luaP.SIZE_A) - 1
luaP.MAXARG_B = math.ldexp(1, luaP.SIZE_B) - 1
luaP.MAXARG_C = math.ldexp(1, luaP.SIZE_C) - 1

-- creates a mask with 'n' 1 bits at position 'p'
-- MASK1(n,p) deleted, not required
-- creates a mask with 'n' 0 bits at position 'p'
-- MASK0(n,p) deleted, not required

--[[--------------------------------------------------------------------
  Visual representation for reference:

   31    |    |     |            0      bit position
    +-----+-----+-----+----------+
    |  B  |  C  |  A  |  Opcode  |      iABC format
    +-----+-----+-----+----------+
    -  9  -  9  -  8  -    6     -      field sizes
    +-----+-----+-----+----------+
    |   [s]Bx   |  A  |  Opcode  |      iABx | iAsBx format
    +-----+-----+-----+----------+

----------------------------------------------------------------------]]

------------------------------------------------------------------------
-- the following macros help to manipulate instructions
-- * changed to a table object representation, very clean compared to
--   the [nightmare] alternatives of using a number or a string
-- * Bx is a separate element from B and C, since there is never a need
--   to split Bx in the parser or code generator
------------------------------------------------------------------------

-- these accept or return opcodes in the form of string names
function luaP:GET_OPCODE(i)
	return self.ROpCode[i.OP]
end
function luaP:SET_OPCODE(i, o)
	i.OP = self.OpCode[o]
end

function luaP:GETARG_A(i)
	return i.A
end
function luaP:SETARG_A(i, u)
	i.A = u
end

function luaP:GETARG_B(i)
	return i.B
end
function luaP:SETARG_B(i, b)
	i.B = b
end

function luaP:GETARG_C(i)
	return i.C
end
function luaP:SETARG_C(i, b)
	i.C = b
end

function luaP:GETARG_Bx(i)
	return i.Bx
end
function luaP:SETARG_Bx(i, b)
	i.Bx = b
end

function luaP:GETARG_sBx(i)
	return i.Bx - self.MAXARG_sBx
end
function luaP:SETARG_sBx(i, b)
	i.Bx = b + self.MAXARG_sBx
end

function luaP:CREATE_ABC(o, a, b, c)
	return { OP = self.OpCode[o], A = a, B = b, C = c }
end

function luaP:CREATE_ABx(o, a, bc)
	return { OP = self.OpCode[o], A = a, Bx = bc }
end

------------------------------------------------------------------------
-- create an instruction from a number (for OP_SETLIST)
------------------------------------------------------------------------
function luaP:CREATE_Inst(c)
	local o = c % 64
	c = (c - o) / 64
	local a = c % 256
	c = (c - a) / 256
	return self:CREATE_ABx(o, a, c)
end

------------------------------------------------------------------------
-- returns a 4-char string little-endian encoded form of an instruction
------------------------------------------------------------------------
function luaP:Instruction(i)
	if i.Bx then
		-- change to OP/A/B/C format
		i.C = i.Bx % 512
		i.B = (i.Bx - i.C) / 512
	end
	local I = i.A * 64 + i.OP
	local c0 = I % 256
	I = i.C * 64 + (I - c0) / 256 -- 6 bits of A left
	local c1 = I % 256
	I = i.B * 128 + (I - c1) / 256 -- 7 bits of C left
	local c2 = I % 256
	local c3 = (I - c2) / 256
	return string.char(c0, c1, c2, c3)
end

------------------------------------------------------------------------
-- decodes a 4-char little-endian string into an instruction struct
------------------------------------------------------------------------
function luaP:DecodeInst(x)
	local byte = string.byte
	local i = {}
	local I = byte(x, 1)
	local op = I % 64
	i.OP = op
	I = byte(x, 2) * 4 + (I - op) / 64 -- 2 bits of c0 left
	local a = I % 256
	i.A = a
	I = byte(x, 3) * 4 + (I - a) / 256 -- 2 bits of c1 left
	local c = I % 512
	i.C = c
	i.B = byte(x, 4) * 2 + (I - c) / 512 -- 1 bits of c2 left
	local opmode = self.OpMode[tonumber(string.sub(self.opmodes[op + 1], 7, 7))]
	if opmode ~= "iABC" then
		i.Bx = i.B * 512 + i.C
	end
	return i
end

------------------------------------------------------------------------
-- Macros to operate RK indices
-- * these use arithmetic instead of bit ops
------------------------------------------------------------------------

-- this bit 1 means constant (0 means register)
luaP.BITRK = math.ldexp(1, luaP.SIZE_B - 1)

-- test whether value is a constant
function luaP:ISK(x)
	return x >= self.BITRK
end

-- gets the index of the constant
function luaP:INDEXK(x)
	return x - self.BITRK
end

luaP.MAXINDEXRK = luaP.BITRK - 1

-- code a constant index as a RK value
function luaP:RKASK(x)
	return x + self.BITRK
end

------------------------------------------------------------------------
-- invalid register that fits in 8 bits
------------------------------------------------------------------------
luaP.NO_REG = luaP.MAXARG_A

------------------------------------------------------------------------
-- R(x) - register
-- Kst(x) - constant (in constant table)
-- RK(x) == if ISK(x) then Kst(INDEXK(x)) else R(x)
------------------------------------------------------------------------

------------------------------------------------------------------------
-- grep "ORDER OP" if you change these enums
------------------------------------------------------------------------

--[[--------------------------------------------------------------------
Lua virtual machine opcodes (enum OpCode):
------------------------------------------------------------------------
name          args    description
------------------------------------------------------------------------
OP_MOVE       A B     R(A) := R(B)
OP_LOADK      A Bx    R(A) := Kst(Bx)
OP_LOADBOOL   A B C   R(A) := (Bool)B; if (C) pc++
OP_LOADNIL    A B     R(A) := ... := R(B) := nil
OP_GETUPVAL   A B     R(A) := UpValue[B]
OP_GETGLOBAL  A Bx    R(A) := Gbl[Kst(Bx)]
OP_GETTABLE   A B C   R(A) := R(B)[RK(C)]
OP_SETGLOBAL  A Bx    Gbl[Kst(Bx)] := R(A)
OP_SETUPVAL   A B     UpValue[B] := R(A)
OP_SETTABLE   A B C   R(A)[RK(B)] := RK(C)
OP_NEWTABLE   A B C   R(A) := {} (size = B,C)
OP_SELF       A B C   R(A+1) := R(B); R(A) := R(B)[RK(C)]
OP_ADD        A B C   R(A) := RK(B) + RK(C)
OP_SUB        A B C   R(A) := RK(B) - RK(C)
OP_MUL        A B C   R(A) := RK(B) * RK(C)
OP_DIV        A B C   R(A) := RK(B) / RK(C)
OP_MOD        A B C   R(A) := RK(B) % RK(C)
OP_POW        A B C   R(A) := RK(B) ^ RK(C)
OP_UNM        A B     R(A) := -R(B)
OP_NOT        A B     R(A) := not R(B)
OP_LEN        A B     R(A) := length of R(B)
OP_CONCAT     A B C   R(A) := R(B).. ... ..R(C)
OP_JMP        sBx     pc+=sBx
OP_EQ         A B C   if ((RK(B) == RK(C)) ~= A) then pc++
OP_LT         A B C   if ((RK(B) <  RK(C)) ~= A) then pc++
OP_LE         A B C   if ((RK(B) <= RK(C)) ~= A) then pc++
OP_TEST       A C     if not (R(A) <=> C) then pc++
OP_TESTSET    A B C   if (R(B) <=> C) then R(A) := R(B) else pc++
OP_CALL       A B C   R(A), ... ,R(A+C-2) := R(A)(R(A+1), ... ,R(A+B-1))
OP_TAILCALL   A B C   return R(A)(R(A+1), ... ,R(A+B-1))
OP_RETURN     A B     return R(A), ... ,R(A+B-2)  (see note)
OP_FORLOOP    A sBx   R(A)+=R(A+2);
                      if R(A) <?= R(A+1) then { pc+=sBx; R(A+3)=R(A) }
OP_FORPREP    A sBx   R(A)-=R(A+2); pc+=sBx
OP_TFORLOOP   A C     R(A+3), ... ,R(A+2+C) := R(A)(R(A+1), R(A+2));
                      if R(A+3) ~= nil then R(A+2)=R(A+3) else pc++
OP_SETLIST    A B C   R(A)[(C-1)*FPF+i] := R(A+i), 1 <= i <= B
OP_CLOSE      A       close all variables in the stack up to (>=) R(A)
OP_CLOSURE    A Bx    R(A) := closure(KPROTO[Bx], R(A), ... ,R(A+n))
OP_VARARG     A B     R(A), R(A+1), ..., R(A+B-1) = vararg
----------------------------------------------------------------------]]

luaP.opnames = {} -- opcode names
luaP.OpCode = {} -- lookup name -> number
luaP.ROpCode = {} -- lookup number -> name

------------------------------------------------------------------------
-- ORDER OP
------------------------------------------------------------------------
local i = 0
for v in
	string.gmatch(
		[[
MOVE LOADK LOADBOOL LOADNIL GETUPVAL
GETGLOBAL GETTABLE SETGLOBAL SETUPVAL SETTABLE
NEWTABLE SELF ADD SUB MUL
DIV MOD POW UNM NOT
LEN CONCAT JMP EQ LT
LE TEST TESTSET CALL TAILCALL
RETURN FORLOOP FORPREP TFORLOOP SETLIST
CLOSE CLOSURE VARARG
]],
		"%S+"
	)
do
	local n = "OP_" .. v
	luaP.opnames[i] = v
	luaP.OpCode[n] = i
	luaP.ROpCode[i] = n
	i = i + 1
end
luaP.NUM_OPCODES = i

--[[
===========================================================================
  Notes:
  (*) In OP_CALL, if (B == 0) then B = top. C is the number of returns - 1,
      and can be 0: OP_CALL then sets 'top' to last_result+1, so
      next open instruction (OP_CALL, OP_RETURN, OP_SETLIST) may use 'top'.
  (*) In OP_VARARG, if (B == 0) then use actual number of varargs and
      set top (like in OP_CALL with C == 0).
  (*) In OP_RETURN, if (B == 0) then return up to 'top'
  (*) In OP_SETLIST, if (B == 0) then B = 'top';
      if (C == 0) then next 'instruction' is real C
  (*) For comparisons, A specifies what condition the test should accept
      (true or false).
  (*) All 'skips' (pc++) assume that next instruction is a jump
===========================================================================
--]]

--[[--------------------------------------------------------------------
  masks for instruction properties. The format is:
  bits 0-1: op mode
  bits 2-3: C arg mode
  bits 4-5: B arg mode
  bit 6: instruction set register A
  bit 7: operator is a test

  for OpArgMask:
  OpArgN - argument is not used
  OpArgU - argument is used
  OpArgR - argument is a register or a jump offset
  OpArgK - argument is a constant or register/constant
----------------------------------------------------------------------]]

-- was enum OpArgMask
luaP.OpArgMask = { OpArgN = 0, OpArgU = 1, OpArgR = 2, OpArgK = 3 }

------------------------------------------------------------------------
-- e.g. to compare with symbols, luaP:getOpMode(...) == luaP.OpCode.iABC
-- * accepts opcode parameter as strings, e.g. "OP_MOVE"
------------------------------------------------------------------------

function luaP:getOpMode(m)
	return self.opmodes[self.OpCode[m]] % 4
end

function luaP:getBMode(m)
	return math.floor(self.opmodes[self.OpCode[m]] / 16) % 4
end

function luaP:getCMode(m)
	return math.floor(self.opmodes[self.OpCode[m]] / 4) % 4
end

function luaP:testAMode(m)
	return math.floor(self.opmodes[self.OpCode[m]] / 64) % 2
end

function luaP:testTMode(m)
	return math.floor(self.opmodes[self.OpCode[m]] / 128)
end

-- luaP_opnames[] is set above, as the luaP.opnames table

-- number of list items to accumulate before a SETLIST instruction
luaP.LFIELDS_PER_FLUSH = 50

------------------------------------------------------------------------
-- build instruction properties array
-- * deliberately coded to look like the C equivalent
------------------------------------------------------------------------
local function opmode(t, a, b, c, m)
	local luaP = luaP
	return t * 128 + a * 64 + luaP.OpArgMask[b] * 16 + luaP.OpArgMask[c] * 4 + luaP.OpMode[m]
end

-- ORDER OP
luaP.opmodes = {
	-- T A B C mode opcode
	opmode(0, 1, "OpArgK", "OpArgN", "iABx"), -- OP_LOADK
	opmode(0, 1, "OpArgU", "OpArgU", "iABC"), -- OP_LOADBOOL
	opmode(0, 1, "OpArgR", "OpArgN", "iABC"), -- OP_LOADNIL
	opmode(0, 1, "OpArgU", "OpArgN", "iABC"), -- OP_GETUPVAL
	opmode(0, 1, "OpArgK", "OpArgN", "iABx"), -- OP_GETGLOBAL
	opmode(0, 1, "OpArgR", "OpArgK", "iABC"), -- OP_GETTABLE
	opmode(0, 0, "OpArgK", "OpArgN", "iABx"), -- OP_SETGLOBAL
	opmode(0, 0, "OpArgU", "OpArgN", "iABC"), -- OP_SETUPVAL
	opmode(0, 0, "OpArgK", "OpArgK", "iABC"), -- OP_SETTABLE
	opmode(0, 1, "OpArgU", "OpArgU", "iABC"), -- OP_NEWTABLE
	opmode(0, 1, "OpArgR", "OpArgK", "iABC"), -- OP_SELF
	opmode(0, 1, "OpArgK", "OpArgK", "iABC"), -- OP_ADD
	opmode(0, 1, "OpArgK", "OpArgK", "iABC"), -- OP_SUB
	opmode(0, 1, "OpArgK", "OpArgK", "iABC"), -- OP_MUL
	opmode(0, 1, "OpArgK", "OpArgK", "iABC"), -- OP_DIV
	opmode(0, 1, "OpArgK", "OpArgK", "iABC"), -- OP_MOD
	opmode(0, 1, "OpArgK", "OpArgK", "iABC"), -- OP_POW
	opmode(0, 1, "OpArgR", "OpArgN", "iABC"), -- OP_UNM
	opmode(0, 1, "OpArgR", "OpArgN", "iABC"), -- OP_NOT
	opmode(0, 1, "OpArgR", "OpArgN", "iABC"), -- OP_LEN
	opmode(0, 1, "OpArgR", "OpArgR", "iABC"), -- OP_CONCAT
	opmode(0, 0, "OpArgR", "OpArgN", "iAsBx"), -- OP_JMP
	opmode(1, 0, "OpArgK", "OpArgK", "iABC"), -- OP_EQ
	opmode(1, 0, "OpArgK", "OpArgK", "iABC"), -- OP_LT
	opmode(1, 0, "OpArgK", "OpArgK", "iABC"), -- OP_LE
	opmode(1, 1, "OpArgR", "OpArgU", "iABC"), -- OP_TEST
	opmode(1, 1, "OpArgR", "OpArgU", "iABC"), -- OP_TESTSET
	opmode(0, 1, "OpArgU", "OpArgU", "iABC"), -- OP_CALL
	opmode(0, 1, "OpArgU", "OpArgU", "iABC"), -- OP_TAILCALL
	opmode(0, 0, "OpArgU", "OpArgN", "iABC"), -- OP_RETURN
	opmode(0, 1, "OpArgR", "OpArgN", "iAsBx"), -- OP_FORLOOP
	opmode(0, 1, "OpArgR", "OpArgN", "iAsBx"), -- OP_FORPREP
	opmode(1, 0, "OpArgN", "OpArgU", "iABC"), -- OP_TFORLOOP
	opmode(0, 0, "OpArgU", "OpArgU", "iABC"), -- OP_SETLIST
	opmode(0, 0, "OpArgN", "OpArgN", "iABC"), -- OP_CLOSE
	opmode(0, 1, "OpArgU", "OpArgN", "iABx"), -- OP_CLOSURE
	opmode(0, 1, "OpArgU", "OpArgN", "iABC"), -- OP_VARARG
}
-- an awkward way to set a zero-indexed table...
luaP.opmodes[0] = opmode(0, 1, "OpArgR", "OpArgN", "iABC") -- OP_MOVE

return luaP
