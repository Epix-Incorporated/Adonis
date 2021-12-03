--[[--------------------------------------------------------------------

  lcode.lua
  Lua 5 code generator in Lua
  This file is part of Yueliang.

  Copyright (c) 2005-2007 Kein-Hong Man <khman@users.sf.net>
  The COPYRIGHT file describes the conditions
  under which this software may be distributed.

  See the ChangeLog for more information.

----------------------------------------------------------------------]]

--[[--------------------------------------------------------------------
-- Notes:
-- * one function manipulate a pointer argument with a simple data type
--   (can't be emulated by a table, ambiguous), now returns that value:
--   luaK:concat(fs, l1, l2)
-- * luaM_growvector uses the faux luaY:growvector, for limit checking
-- * some function parameters changed to boolean, additional code
--   translates boolean back to 1/0 for instruction fields
--
-- Not implemented:
-- * NOTE there is a failed assert in luaK:addk, a porting problem
--
-- Added:
-- * constant MAXSTACK from llimits.h
-- * luaK:ttisnumber(o) (from lobject.h)
-- * luaK:nvalue(o) (from lobject.h)
-- * luaK:setnilvalue(o) (from lobject.h)
-- * luaK:setnvalue(o, x) (from lobject.h)
-- * luaK:setbvalue(o, x) (from lobject.h)
-- * luaK:sethvalue(o, x) (from lobject.h), parameter L deleted
-- * luaK:setsvalue(o, x) (from lobject.h), parameter L deleted
-- * luaK:numadd, luaK:numsub, luaK:nummul, luaK:numdiv, luaK:nummod,
--   luaK:numpow, luaK:numunm, luaK:numisnan (from luaconf.h)
-- * copyexp(e1, e2) added in luaK:posfix to copy expdesc struct
--
-- Changed in 5.1.x:
-- * enum BinOpr has a new entry, OPR_MOD
-- * enum UnOpr has a new entry, OPR_LEN
-- * binopistest, unused in 5.0.x, has been deleted
-- * macro setmultret is new
-- * functions isnumeral, luaK_ret, boolK are new
-- * funcion nilK was named nil_constant in 5.0.x
-- * function interface changed: need_value, patchtestreg, concat
-- * TObject now a TValue
-- * functions luaK_setreturns, luaK_setoneret are new
-- * function luaK:setcallreturns deleted, to be replaced by:
--   luaK:setmultret, luaK:ret, luaK:setreturns, luaK:setoneret
-- * functions constfolding, codearith, codecomp are new
-- * luaK:codebinop has been deleted
-- * function luaK_setlist is new
-- * OPR_MULT renamed to OPR_MUL
----------------------------------------------------------------------]]

-- requires luaP, luaX, luaY
local luaY
local luaK = {}
local luaP = require(script.Parent.LuaP)
local luaX = require(script.Parent.LuaX)

------------------------------------------------------------------------
-- constants used by code generator
------------------------------------------------------------------------
-- maximum stack for a Lua function
luaK.MAXSTACK = 250  -- (from llimits.h)

--[[--------------------------------------------------------------------
-- other functions
----------------------------------------------------------------------]]

------------------------------------------------------------------------
-- emulation of TValue macros (these are from lobject.h)
-- * TValue is a table since lcode passes references around
-- * tt member field removed, using Lua's type() instead
-- * for setsvalue, sethvalue, parameter L (deleted here) in lobject.h
--   is used in an assert for testing, see checkliveness(g,obj)
------------------------------------------------------------------------
function luaK:ttisnumber(o)
  if o then return type(o.value) == "number" else return false end
end
function luaK:nvalue(o) return o.value end
function luaK:setnilvalue(o) o.value = nil end
function luaK:setsvalue(o, x) o.value = x end
luaK.setnvalue = luaK.setsvalue
luaK.sethvalue = luaK.setsvalue
luaK.setbvalue = luaK.setsvalue

------------------------------------------------------------------------
-- The luai_num* macros define the primitive operations over numbers.
-- * this is not the entire set of primitive operations from luaconf.h
-- * used in luaK:constfolding()
------------------------------------------------------------------------
function luaK:numadd(a, b) return a + b end
function luaK:numsub(a, b) return a - b end
function luaK:nummul(a, b) return a * b end
function luaK:numdiv(a, b) return a / b end
function luaK:nummod(a, b) return a % b end
  -- ((a) - floor((a)/(b))*(b)) /* actual, for reference */
function luaK:numpow(a, b) return a ^ b end
function luaK:numunm(a) return -a end
function luaK:numisnan(a) return not a == a end
  -- a NaN cannot equal another NaN

--[[--------------------------------------------------------------------
-- code generator functions
----------------------------------------------------------------------]]

------------------------------------------------------------------------
-- Marks the end of a patch list. It is an invalid value both as an absolute
-- address, and as a list link (would link an element to itself).
------------------------------------------------------------------------
luaK.NO_JUMP = -1

------------------------------------------------------------------------
-- grep "ORDER OPR" if you change these enums
------------------------------------------------------------------------
luaK.BinOpr = {
  OPR_ADD = 0, OPR_SUB = 1, OPR_MUL = 2, OPR_DIV = 3, OPR_MOD = 4, OPR_POW = 5,
  OPR_CONCAT = 6,
  OPR_NE = 7, OPR_EQ = 8,
  OPR_LT = 9, OPR_LE = 10, OPR_GT = 11, OPR_GE = 12,
  OPR_AND = 13, OPR_OR = 14,
  OPR_NOBINOPR = 15,
}

-- * UnOpr is used by luaK:prefix's op argument, but not directly used
--   because the function receives the symbols as strings, e.g. "OPR_NOT"
luaK.UnOpr = {
  OPR_MINUS = 0, OPR_NOT = 1, OPR_LEN = 2, OPR_NOUNOPR = 3
}

------------------------------------------------------------------------
-- returns the instruction object for given e (expdesc), was a macro
------------------------------------------------------------------------
function luaK:getcode(fs, e)
  return fs.f.code[e.info]
end

------------------------------------------------------------------------
-- codes an instruction with a signed Bx (sBx) field, was a macro
-- * used in luaK:jump(), (lparser) luaY:forbody()
------------------------------------------------------------------------
function luaK:codeAsBx(fs, o, A, sBx)
  return self:codeABx(fs, o, A, sBx + luaP.MAXARG_sBx)
end

------------------------------------------------------------------------
-- set the expdesc e instruction for multiple returns, was a macro
------------------------------------------------------------------------
function luaK:setmultret(fs, e)
  self:setreturns(fs, e, luaY.LUA_MULTRET)
end

------------------------------------------------------------------------
-- there is a jump if patch lists are not identical, was a macro
-- * used in luaK:exp2reg(), luaK:exp2anyreg(), luaK:exp2val()
------------------------------------------------------------------------
function luaK:hasjumps(e)
  return e.t ~= e.f
end

------------------------------------------------------------------------
-- true if the expression is a constant number (for constant folding)
-- * used in constfolding(), infix()
------------------------------------------------------------------------
function luaK:isnumeral(e)
  return e.k == "VKNUM" and e.t == self.NO_JUMP and e.f == self.NO_JUMP
end

------------------------------------------------------------------------
-- codes loading of nil, optimization done if consecutive locations
-- * used in luaK:discharge2reg(), (lparser) luaY:adjust_assign()
------------------------------------------------------------------------
function luaK:_nil(fs, from, n)
  if fs.pc > fs.lasttarget then  -- no jumps to current position?
    if fs.pc == 0 then  -- function start?
      if from >= fs.nactvar then
        return  -- positions are already clean
      end
    else
      local previous = fs.f.code[fs.pc - 1]
      if luaP:GET_OPCODE(previous) == "OP_LOADNIL" then
        local pfrom = luaP:GETARG_A(previous)
        local pto = luaP:GETARG_B(previous)
        if pfrom <= from and from <= pto + 1 then  -- can connect both?
          if from + n - 1 > pto then
            luaP:SETARG_B(previous, from + n - 1)
          end
          return
        end
      end
    end
  end
  self:codeABC(fs, "OP_LOADNIL", from, from + n - 1, 0)  -- else no optimization
end

------------------------------------------------------------------------
--
-- * used in multiple locations
------------------------------------------------------------------------
function luaK:jump(fs)
  local jpc = fs.jpc  -- save list of jumps to here
  fs.jpc = self.NO_JUMP
  local j = self:codeAsBx(fs, "OP_JMP", 0, self.NO_JUMP)
  j = self:concat(fs, j, jpc)  -- keep them on hold
  return j
end

------------------------------------------------------------------------
-- codes a RETURN instruction
-- * used in luaY:close_func(), luaY:retstat()
------------------------------------------------------------------------
function luaK:ret(fs, first, nret)
  self:codeABC(fs, "OP_RETURN", first, nret + 1, 0)
end

------------------------------------------------------------------------
--
-- * used in luaK:jumponcond(), luaK:codecomp()
------------------------------------------------------------------------
function luaK:condjump(fs, op, A, B, C)
  self:codeABC(fs, op, A, B, C)
  return self:jump(fs)
end

------------------------------------------------------------------------
--
-- * used in luaK:patchlistaux(), luaK:concat()
------------------------------------------------------------------------
function luaK:fixjump(fs, pc, dest)
  local jmp = fs.f.code[pc]
  local offset = dest - (pc + 1)
  assert(dest ~= self.NO_JUMP)
  if math.abs(offset) > luaP.MAXARG_sBx then
    luaX:syntaxerror(fs.ls, "control structure too long")
  end
  luaP:SETARG_sBx(jmp, offset)
end

------------------------------------------------------------------------
-- returns current 'pc' and marks it as a jump target (to avoid wrong
-- optimizations with consecutive instructions not in the same basic block).
-- * used in multiple locations
-- * fs.lasttarget tested only by luaK:_nil() when optimizing OP_LOADNIL
------------------------------------------------------------------------
function luaK:getlabel(fs)
  fs.lasttarget = fs.pc
  return fs.pc
end

------------------------------------------------------------------------
--
-- * used in luaK:need_value(), luaK:removevalues(), luaK:patchlistaux(),
--   luaK:concat()
------------------------------------------------------------------------
function luaK:getjump(fs, pc)
  local offset = luaP:GETARG_sBx(fs.f.code[pc])
  if offset == self.NO_JUMP then  -- point to itself represents end of list
    return self.NO_JUMP  -- end of list
  else
    return (pc + 1) + offset  -- turn offset into absolute position
  end
end

------------------------------------------------------------------------
--
-- * used in luaK:need_value(), luaK:patchtestreg(), luaK:invertjump()
------------------------------------------------------------------------
function luaK:getjumpcontrol(fs, pc)
  local pi = fs.f.code[pc]
  local ppi = fs.f.code[pc - 1]
  if pc >= 1 and luaP:testTMode(luaP:GET_OPCODE(ppi)) ~= 0 then
    return ppi
  else
    return pi
  end
end

------------------------------------------------------------------------
-- check whether list has any jump that do not produce a value
-- (or produce an inverted value)
-- * return value changed to boolean
-- * used only in luaK:exp2reg()
------------------------------------------------------------------------
function luaK:need_value(fs, list)
  while list ~= self.NO_JUMP do
    local i = self:getjumpcontrol(fs, list)
    if luaP:GET_OPCODE(i) ~= "OP_TESTSET" then return true end
    list = self:getjump(fs, list)
  end
  return false  -- not found
end

------------------------------------------------------------------------
--
-- * used in luaK:removevalues(), luaK:patchlistaux()
------------------------------------------------------------------------
function luaK:patchtestreg(fs, node, reg)
  local i = self:getjumpcontrol(fs, node)
  if luaP:GET_OPCODE(i) ~= "OP_TESTSET" then
    return false  -- cannot patch other instructions
  end
  if reg ~= luaP.NO_REG and reg ~= luaP:GETARG_B(i) then
    luaP:SETARG_A(i, reg)
  else  -- no register to put value or register already has the value
    -- due to use of a table as i, i cannot be replaced by another table
    -- so the following is required; there is no change to ARG_C
    luaP:SET_OPCODE(i, "OP_TEST")
    local b = luaP:GETARG_B(i)
    luaP:SETARG_A(i, b)
    luaP:SETARG_B(i, 0)
    -- *i = CREATE_ABC(OP_TEST, GETARG_B(*i), 0, GETARG_C(*i)); /* C */
  end
  return true
end

------------------------------------------------------------------------
--
-- * used only in luaK:codenot()
------------------------------------------------------------------------
function luaK:removevalues(fs, list)
  while list ~= self.NO_JUMP do
    self:patchtestreg(fs, list, luaP.NO_REG)
    list = self:getjump(fs, list)
  end
end

------------------------------------------------------------------------
--
-- * used in luaK:dischargejpc(), luaK:patchlist(), luaK:exp2reg()
------------------------------------------------------------------------
function luaK:patchlistaux(fs, list, vtarget, reg, dtarget)
  while list ~= self.NO_JUMP do
    local _next = self:getjump(fs, list)
    if self:patchtestreg(fs, list, reg) then
      self:fixjump(fs, list, vtarget)
    else
      self:fixjump(fs, list, dtarget)  -- jump to default target
    end
    list = _next
  end
end

------------------------------------------------------------------------
--
-- * used only in luaK:code()
------------------------------------------------------------------------
function luaK:dischargejpc(fs)
  self:patchlistaux(fs, fs.jpc, fs.pc, luaP.NO_REG, fs.pc)
  fs.jpc = self.NO_JUMP
end

------------------------------------------------------------------------
--
-- * used in (lparser) luaY:whilestat(), luaY:repeatstat(), luaY:forbody()
------------------------------------------------------------------------
function luaK:patchlist(fs, list, target)
  if target == fs.pc then
    self:patchtohere(fs, list)
  else
    assert(target < fs.pc)
    self:patchlistaux(fs, list, target, luaP.NO_REG, target)
  end
end

------------------------------------------------------------------------
--
-- * used in multiple locations
------------------------------------------------------------------------
function luaK:patchtohere(fs, list)
  self:getlabel(fs)
  fs.jpc = self:concat(fs, fs.jpc, list)
end

------------------------------------------------------------------------
-- * l1 was a pointer, now l1 is returned and callee assigns the value
-- * used in multiple locations
------------------------------------------------------------------------
function luaK:concat(fs, l1, l2)
  if l2 == self.NO_JUMP then return l1
  elseif l1 == self.NO_JUMP then
    return l2
  else
    local list = l1
    local _next = self:getjump(fs, list)
    while _next ~= self.NO_JUMP do  -- find last element
      list = _next
      _next = self:getjump(fs, list)
    end
    self:fixjump(fs, list, l2)
  end
  return l1
end

------------------------------------------------------------------------
--
-- * used in luaK:reserveregs(), (lparser) luaY:forlist()
------------------------------------------------------------------------
function luaK:checkstack(fs, n)
  local newstack = fs.freereg + n
  if newstack > fs.f.maxstacksize then
    if newstack >= self.MAXSTACK then
      luaX:syntaxerror(fs.ls, "function or expression too complex")
    end
    fs.f.maxstacksize = newstack
  end
end

------------------------------------------------------------------------
--
-- * used in multiple locations
------------------------------------------------------------------------
function luaK:reserveregs(fs, n)
  self:checkstack(fs, n)
  fs.freereg = fs.freereg + n
end

------------------------------------------------------------------------
--
-- * used in luaK:freeexp(), luaK:dischargevars()
------------------------------------------------------------------------
function luaK:freereg(fs, reg)
  if not luaP:ISK(reg) and reg >= fs.nactvar then
    fs.freereg = fs.freereg - 1
    assert(reg == fs.freereg)
  end
end

------------------------------------------------------------------------
--
-- * used in multiple locations
------------------------------------------------------------------------
function luaK:freeexp(fs, e)
  if e.k == "VNONRELOC" then
    self:freereg(fs, e.info)
  end
end

------------------------------------------------------------------------
-- * TODO NOTE implementation is not 100% correct, since the assert fails
-- * luaH_set, setobj deleted; direct table access used instead
-- * used in luaK:stringK(), luaK:numberK(), luaK:boolK(), luaK:nilK()
------------------------------------------------------------------------
function luaK:addk(fs, k, v)
  local L = fs.L
  local idx = fs.h[k.value]
  --TValue *idx = luaH_set(L, fs->h, k); /* C */
  local f = fs.f
  if self:ttisnumber(idx) then
    --TODO this assert currently FAILS (last tested for 5.0.2)
    --assert(fs.f.k[self:nvalue(idx)] == v)
    --assert(luaO_rawequalObj(&fs->f->k[cast_int(nvalue(idx))], v)); /* C */
    return self:nvalue(idx)
  else -- constant not found; create a new entry
    idx = {}
    self:setnvalue(idx, fs.nk)
    fs.h[k.value] = idx
    -- setnvalue(idx, cast_num(fs->nk)); /* C */
    luaY:growvector(L, f.k, fs.nk, f.sizek, nil,
                    luaP.MAXARG_Bx, "constant table overflow")
    -- loop to initialize empty f.k positions not required
    f.k[fs.nk] = v
    -- setobj(L, &f->k[fs->nk], v); /* C */
    -- luaC_barrier(L, f, v); /* GC */
    local nk = fs.nk
    fs.nk = fs.nk + 1
    return nk
  end

end

------------------------------------------------------------------------
-- creates and sets a string object
-- * used in (lparser) luaY:codestring(), luaY:singlevar()
------------------------------------------------------------------------
function luaK:stringK(fs, s)
  local o = {}  -- TValue
  self:setsvalue(o, s)
  return self:addk(fs, o, o)
end

------------------------------------------------------------------------
-- creates and sets a number object
-- * used in luaK:prefix() for negative (or negation of) numbers
-- * used in (lparser) luaY:simpleexp(), luaY:fornum()
------------------------------------------------------------------------
function luaK:numberK(fs, r)
  local o = {}  -- TValue
  self:setnvalue(o, r)
  return self:addk(fs, o, o)
end

------------------------------------------------------------------------
-- creates and sets a boolean object
-- * used only in luaK:exp2RK()
------------------------------------------------------------------------
function luaK:boolK(fs, b)
  local o = {}  -- TValue
  self:setbvalue(o, b)
  return self:addk(fs, o, o)
end

------------------------------------------------------------------------
-- creates and sets a nil object
-- * used only in luaK:exp2RK()
------------------------------------------------------------------------
function luaK:nilK(fs)
  local k, v = {}, {}  -- TValue
  self:setnilvalue(v)
  -- cannot use nil as key; instead use table itself to represent nil
  self:sethvalue(k, fs.h)
  return self:addk(fs, k, v)
end

------------------------------------------------------------------------
--
-- * used in luaK:setmultret(), (lparser) luaY:adjust_assign()
------------------------------------------------------------------------
function luaK:setreturns(fs, e, nresults)
  if e.k == "VCALL" then  -- expression is an open function call?
    luaP:SETARG_C(self:getcode(fs, e), nresults + 1)
  elseif e.k == "VVARARG" then
    luaP:SETARG_B(self:getcode(fs, e), nresults + 1);
    luaP:SETARG_A(self:getcode(fs, e), fs.freereg);
    luaK:reserveregs(fs, 1)
  end
end

------------------------------------------------------------------------
--
-- * used in luaK:dischargevars(), (lparser) luaY:assignment()
------------------------------------------------------------------------
function luaK:setoneret(fs, e)
  if e.k == "VCALL" then  -- expression is an open function call?
    e.k = "VNONRELOC"
    e.info = luaP:GETARG_A(self:getcode(fs, e))
  elseif e.k == "VVARARG" then
    luaP:SETARG_B(self:getcode(fs, e), 2)
    e.k = "VRELOCABLE"  -- can relocate its simple result
  end
end

------------------------------------------------------------------------
--
-- * used in multiple locations
------------------------------------------------------------------------
function luaK:dischargevars(fs, e)
  local k = e.k
  if k == "VLOCAL" then
    e.k = "VNONRELOC"
  elseif k == "VUPVAL" then
    e.info = self:codeABC(fs, "OP_GETUPVAL", 0, e.info, 0)
    e.k = "VRELOCABLE"
  elseif k == "VGLOBAL" then
    e.info = self:codeABx(fs, "OP_GETGLOBAL", 0, e.info)
    e.k = "VRELOCABLE"
  elseif k == "VINDEXED" then
    self:freereg(fs, e.aux)
    self:freereg(fs, e.info)
    e.info = self:codeABC(fs, "OP_GETTABLE", 0, e.info, e.aux)
    e.k = "VRELOCABLE"
  elseif k == "VVARARG" or k == "VCALL" then
    self:setoneret(fs, e)
  else
    -- there is one value available (somewhere)
  end
end

------------------------------------------------------------------------
--
-- * used only in luaK:exp2reg()
------------------------------------------------------------------------
function luaK:code_label(fs, A, b, jump)
  self:getlabel(fs)  -- those instructions may be jump targets
  return self:codeABC(fs, "OP_LOADBOOL", A, b, jump)
end

------------------------------------------------------------------------
--
-- * used in luaK:discharge2anyreg(), luaK:exp2reg()
------------------------------------------------------------------------
function luaK:discharge2reg(fs, e, reg)
  self:dischargevars(fs, e)
  local k = e.k
  if k == "VNIL" then
    self:_nil(fs, reg, 1)
  elseif k == "VFALSE" or k == "VTRUE" then
    self:codeABC(fs, "OP_LOADBOOL", reg, (e.k == "VTRUE") and 1 or 0, 0)
  elseif k == "VK" then
    self:codeABx(fs, "OP_LOADK", reg, e.info)
  elseif k == "VKNUM" then
    self:codeABx(fs, "OP_LOADK", reg, self:numberK(fs, e.nval))
  elseif k == "VRELOCABLE" then
    local pc = self:getcode(fs, e)
    luaP:SETARG_A(pc, reg)
  elseif k == "VNONRELOC" then
    if reg ~= e.info then
      self:codeABC(fs, "OP_MOVE", reg, e.info, 0)
    end
  else
    assert(e.k == "VVOID" or e.k == "VJMP")
    return  -- nothing to do...
  end
  e.info = reg
  e.k = "VNONRELOC"
end

------------------------------------------------------------------------
--
-- * used in luaK:jumponcond(), luaK:codenot()
------------------------------------------------------------------------
function luaK:discharge2anyreg(fs, e)
  if e.k ~= "VNONRELOC" then
    self:reserveregs(fs, 1)
    self:discharge2reg(fs, e, fs.freereg - 1)
  end
end

------------------------------------------------------------------------
--
-- * used in luaK:exp2nextreg(), luaK:exp2anyreg(), luaK:storevar()
------------------------------------------------------------------------
function luaK:exp2reg(fs, e, reg)
  self:discharge2reg(fs, e, reg)
  if e.k == "VJMP" then
    e.t = self:concat(fs, e.t, e.info)  -- put this jump in 't' list
  end
  if self:hasjumps(e) then
    local final  -- position after whole expression
    local p_f = self.NO_JUMP  -- position of an eventual LOAD false
    local p_t = self.NO_JUMP  -- position of an eventual LOAD true
    if self:need_value(fs, e.t) or self:need_value(fs, e.f) then
      local fj = (e.k == "VJMP") and self.NO_JUMP or self:jump(fs)
      p_f = self:code_label(fs, reg, 0, 1)
      p_t = self:code_label(fs, reg, 1, 0)
      self:patchtohere(fs, fj)
    end
    final = self:getlabel(fs)
    self:patchlistaux(fs, e.f, final, reg, p_f)
    self:patchlistaux(fs, e.t, final, reg, p_t)
  end
  e.f, e.t = self.NO_JUMP, self.NO_JUMP
  e.info = reg
  e.k = "VNONRELOC"
end

------------------------------------------------------------------------
--
-- * used in multiple locations
------------------------------------------------------------------------
function luaK:exp2nextreg(fs, e)
  self:dischargevars(fs, e)
  self:freeexp(fs, e)
  self:reserveregs(fs, 1)
  self:exp2reg(fs, e, fs.freereg - 1)
end

------------------------------------------------------------------------
--
-- * used in multiple locations
------------------------------------------------------------------------
function luaK:exp2anyreg(fs, e)
  self:dischargevars(fs, e)
  if e.k == "VNONRELOC" then
    if not self:hasjumps(e) then  -- exp is already in a register
      return e.info
    end
    if e.info >= fs.nactvar then  -- reg. is not a local?
      self:exp2reg(fs, e, e.info)  -- put value on it
      return e.info
    end
  end
  self:exp2nextreg(fs, e)  -- default
  return e.info
end

------------------------------------------------------------------------
--
-- * used in luaK:exp2RK(), luaK:prefix(), luaK:posfix()
-- * used in (lparser) luaY:yindex()
------------------------------------------------------------------------
function luaK:exp2val(fs, e)
  if self:hasjumps(e) then
    self:exp2anyreg(fs, e)
  else
    self:dischargevars(fs, e)
  end
end

------------------------------------------------------------------------
--
-- * used in multiple locations
------------------------------------------------------------------------
function luaK:exp2RK(fs, e)
  self:exp2val(fs, e)
  local k = e.k
  if k == "VKNUM" or k == "VTRUE" or k == "VFALSE" or k == "VNIL" then
    if fs.nk <= luaP.MAXINDEXRK then  -- constant fit in RK operand?
      -- converted from a 2-deep ternary operator expression
      if e.k == "VNIL" then
        e.info = self:nilK(fs)
      else
        e.info = (e.k == "VKNUM") and self:numberK(fs, e.nval)
                                  or self:boolK(fs, e.k == "VTRUE")
      end
      e.k = "VK"
      return luaP:RKASK(e.info)
    end
  elseif k == "VK" then
    if e.info <= luaP.MAXINDEXRK then  -- constant fit in argC?
      return luaP:RKASK(e.info)
    end
  else
    -- default
  end
  -- not a constant in the right range: put it in a register
  return self:exp2anyreg(fs, e)
end

------------------------------------------------------------------------
--
-- * used in (lparser) luaY:assignment(), luaY:localfunc(), luaY:funcstat()
------------------------------------------------------------------------
function luaK:storevar(fs, var, ex)
  local k = var.k
  if k == "VLOCAL" then
    self:freeexp(fs, ex)
    self:exp2reg(fs, ex, var.info)
    return
  elseif k == "VUPVAL" then
    local e = self:exp2anyreg(fs, ex)
    self:codeABC(fs, "OP_SETUPVAL", e, var.info, 0)
  elseif k == "VGLOBAL" then
    local e = self:exp2anyreg(fs, ex)
    self:codeABx(fs, "OP_SETGLOBAL", e, var.info)
  elseif k == "VINDEXED" then
    local e = self:exp2RK(fs, ex)
    self:codeABC(fs, "OP_SETTABLE", var.info, var.aux, e)
  else
    assert(0)  -- invalid var kind to store
  end
  self:freeexp(fs, ex)
end

------------------------------------------------------------------------
--
-- * used only in (lparser) luaY:primaryexp()
------------------------------------------------------------------------
function luaK:_self(fs, e, key)
  self:exp2anyreg(fs, e)
  self:freeexp(fs, e)
  local func = fs.freereg
  self:reserveregs(fs, 2)
  self:codeABC(fs, "OP_SELF", func, e.info, self:exp2RK(fs, key))
  self:freeexp(fs, key)
  e.info = func
  e.k = "VNONRELOC"
end

------------------------------------------------------------------------
--
-- * used in luaK:goiftrue(), luaK:codenot()
------------------------------------------------------------------------
function luaK:invertjump(fs, e)
  local pc = self:getjumpcontrol(fs, e.info)
  assert(luaP:testTMode(luaP:GET_OPCODE(pc)) ~= 0 and
             luaP:GET_OPCODE(pc) ~= "OP_TESTSET" and
             luaP:GET_OPCODE(pc) ~= "OP_TEST")
  luaP:SETARG_A(pc, (luaP:GETARG_A(pc) == 0) and 1 or 0)
end

------------------------------------------------------------------------
--
-- * used in luaK:goiftrue(), luaK:goiffalse()
------------------------------------------------------------------------
function luaK:jumponcond(fs, e, cond)
  if e.k == "VRELOCABLE" then
    local ie = self:getcode(fs, e)
    if luaP:GET_OPCODE(ie) == "OP_NOT" then
      fs.pc = fs.pc - 1  -- remove previous OP_NOT
      return self:condjump(fs, "OP_TEST", luaP:GETARG_B(ie), 0, cond and 0 or 1)
    end
    -- else go through
  end
  self:discharge2anyreg(fs, e)
  self:freeexp(fs, e)
  return self:condjump(fs, "OP_TESTSET", luaP.NO_REG, e.info, cond and 1 or 0)
end

------------------------------------------------------------------------
--
-- * used in luaK:infix(), (lparser) luaY:cond()
------------------------------------------------------------------------
function luaK:goiftrue(fs, e)
  local pc  -- pc of last jump
  self:dischargevars(fs, e)
  local k = e.k
  if k == "VK" or k == "VKNUM" or k == "VTRUE" then
    pc = self.NO_JUMP  -- always true; do nothing
  elseif k == "VFALSE" then
    pc = self:jump(fs)  -- always jump
  elseif k == "VJMP" then
    self:invertjump(fs, e)
    pc = e.info
  else
    pc = self:jumponcond(fs, e, false)
  end
  e.f = self:concat(fs, e.f, pc)  -- insert last jump in `f' list
  self:patchtohere(fs, e.t)
  e.t = self.NO_JUMP
end

------------------------------------------------------------------------
--
-- * used in luaK:infix()
------------------------------------------------------------------------
function luaK:goiffalse(fs, e)
  local pc  -- pc of last jump
  self:dischargevars(fs, e)
  local k = e.k
  if k == "VNIL" or k == "VFALSE"then
    pc = self.NO_JUMP  -- always false; do nothing
  elseif k == "VTRUE" then
    pc = self:jump(fs)  -- always jump
  elseif k == "VJMP" then
    pc = e.info
  else
    pc = self:jumponcond(fs, e, true)
  end
  e.t = self:concat(fs, e.t, pc)  -- insert last jump in `t' list
  self:patchtohere(fs, e.f)
  e.f = self.NO_JUMP
end

------------------------------------------------------------------------
--
-- * used only in luaK:prefix()
------------------------------------------------------------------------
function luaK:codenot(fs, e)
  self:dischargevars(fs, e)
  local k = e.k
  if k == "VNIL" or k == "VFALSE" then
    e.k = "VTRUE"
  elseif k == "VK" or k == "VKNUM" or k == "VTRUE" then
    e.k = "VFALSE"
  elseif k == "VJMP" then
    self:invertjump(fs, e)
  elseif k == "VRELOCABLE" or k == "VNONRELOC" then
    self:discharge2anyreg(fs, e)
    self:freeexp(fs, e)
    e.info = self:codeABC(fs, "OP_NOT", 0, e.info, 0)
    e.k = "VRELOCABLE"
  else
    assert(0)  -- cannot happen
  end
  -- interchange true and false lists
  e.f, e.t = e.t, e.f
  self:removevalues(fs, e.f)
  self:removevalues(fs, e.t)
end

------------------------------------------------------------------------
--
-- * used in (lparser) luaY:field(), luaY:primaryexp()
------------------------------------------------------------------------
function luaK:indexed(fs, t, k)
  t.aux = self:exp2RK(fs, k)
  t.k = "VINDEXED"
end

------------------------------------------------------------------------
--
-- * used only in luaK:codearith()
------------------------------------------------------------------------
function luaK:constfolding(op, e1, e2)
  local r
  if not self:isnumeral(e1) or not self:isnumeral(e2) then return false end
  local v1 = e1.nval
  local v2 = e2.nval
  if op == "OP_ADD" then
    r = self:numadd(v1, v2)
  elseif op == "OP_SUB" then
    r = self:numsub(v1, v2)
  elseif op == "OP_MUL" then
    r = self:nummul(v1, v2)
  elseif op == "OP_DIV" then
    if v2 == 0 then return false end  -- do not attempt to divide by 0
    r = self:numdiv(v1, v2)
  elseif op == "OP_MOD" then
    if v2 == 0 then return false end  -- do not attempt to divide by 0
    r = self:nummod(v1, v2)
  elseif op == "OP_POW" then
    r = self:numpow(v1, v2)
  elseif op == "OP_UNM" then
    r = self:numunm(v1)
  elseif op == "OP_LEN" then
    return false  -- no constant folding for 'len'
  else
    assert(0)
    r = 0
  end
  if self:numisnan(r) then return false end  -- do not attempt to produce NaN
  e1.nval = r
  return true
end

------------------------------------------------------------------------
--
-- * used in luaK:prefix(), luaK:posfix()
------------------------------------------------------------------------
function luaK:codearith(fs, op, e1, e2)
  if self:constfolding(op, e1, e2) then
    return
  else
    local o2 = (op ~= "OP_UNM" and op ~= "OP_LEN") and self:exp2RK(fs, e2) or 0
    local o1 = self:exp2RK(fs, e1)
    if o1 > o2 then
      self:freeexp(fs, e1)
      self:freeexp(fs, e2)
    else
      self:freeexp(fs, e2)
      self:freeexp(fs, e1)
    end
    e1.info = self:codeABC(fs, op, 0, o1, o2)
    e1.k = "VRELOCABLE"
  end
end

------------------------------------------------------------------------
--
-- * used only in luaK:posfix()
------------------------------------------------------------------------
function luaK:codecomp(fs, op, cond, e1, e2)
  local o1 = self:exp2RK(fs, e1)
  local o2 = self:exp2RK(fs, e2)
  self:freeexp(fs, e2)
  self:freeexp(fs, e1)
  if cond == 0 and op ~= "OP_EQ" then
    -- exchange args to replace by `<' or `<='
    o1, o2 = o2, o1  -- o1 <==> o2
    cond = 1
  end
  e1.info = self:condjump(fs, op, cond, o1, o2)
  e1.k = "VJMP"
end

------------------------------------------------------------------------
--
-- * used only in (lparser) luaY:subexpr()
------------------------------------------------------------------------
function luaK:prefix(fs, op, e)
  local e2 = {}  -- expdesc
  e2.t, e2.f = self.NO_JUMP, self.NO_JUMP
  e2.k = "VKNUM"
  e2.nval = 0
  if op == "OPR_MINUS" then
    if not self:isnumeral(e) then
      self:exp2anyreg(fs, e)  -- cannot operate on non-numeric constants
    end
    self:codearith(fs, "OP_UNM", e, e2)
  elseif op == "OPR_NOT" then
    self:codenot(fs, e)
  elseif op == "OPR_LEN" then
    self:exp2anyreg(fs, e)  -- cannot operate on constants
    self:codearith(fs, "OP_LEN", e, e2)
  else
    assert(0)
  end
end

------------------------------------------------------------------------
--
-- * used only in (lparser) luaY:subexpr()
------------------------------------------------------------------------
function luaK:infix(fs, op, v)
  if op == "OPR_AND" then
    self:goiftrue(fs, v)
  elseif op == "OPR_OR" then
    self:goiffalse(fs, v)
  elseif op == "OPR_CONCAT" then
    self:exp2nextreg(fs, v)  -- operand must be on the 'stack'
  elseif op == "OPR_ADD" or op == "OPR_SUB" or
         op == "OPR_MUL" or op == "OPR_DIV" or
         op == "OPR_MOD" or op == "OPR_POW" then
    if not self:isnumeral(v) then self:exp2RK(fs, v) end
  else
    self:exp2RK(fs, v)
  end
end

------------------------------------------------------------------------
--
-- * used only in (lparser) luaY:subexpr()
------------------------------------------------------------------------
-- table lookups to simplify testing
luaK.arith_op = {
  OPR_ADD = "OP_ADD", OPR_SUB = "OP_SUB", OPR_MUL = "OP_MUL",
  OPR_DIV = "OP_DIV", OPR_MOD = "OP_MOD", OPR_POW = "OP_POW",
}
luaK.comp_op = {
  OPR_EQ = "OP_EQ", OPR_NE = "OP_EQ", OPR_LT = "OP_LT",
  OPR_LE = "OP_LE", OPR_GT = "OP_LT", OPR_GE = "OP_LE",
}
luaK.comp_cond = {
  OPR_EQ = 1, OPR_NE = 0, OPR_LT = 1,
  OPR_LE = 1, OPR_GT = 0, OPR_GE = 0,
}
function luaK:posfix(fs, op, e1, e2)
  -- needed because e1 = e2 doesn't copy values...
  -- * in 5.0.x, only k/info/aux/t/f copied, t for AND, f for OR
  --   but here, all elements are copied for completeness' sake
  local function copyexp(e1, e2)
    e1.k = e2.k
    e1.info = e2.info; e1.aux = e2.aux
    e1.nval = e2.nval
    e1.t = e2.t; e1.f = e2.f
  end
  if op == "OPR_AND" then
    assert(e1.t == self.NO_JUMP)  -- list must be closed
    self:dischargevars(fs, e2)
    e2.f = self:concat(fs, e2.f, e1.f)
    copyexp(e1, e2)
  elseif op == "OPR_OR" then
    assert(e1.f == self.NO_JUMP)  -- list must be closed
    self:dischargevars(fs, e2)
    e2.t = self:concat(fs, e2.t, e1.t)
    copyexp(e1, e2)
  elseif op == "OPR_CONCAT" then
    self:exp2val(fs, e2)
    if e2.k == "VRELOCABLE" and luaP:GET_OPCODE(self:getcode(fs, e2)) == "OP_CONCAT" then
      assert(e1.info == luaP:GETARG_B(self:getcode(fs, e2)) - 1)
      self:freeexp(fs, e1)
      luaP:SETARG_B(self:getcode(fs, e2), e1.info)
      e1.k = "VRELOCABLE"
      e1.info = e2.info
    else
      self:exp2nextreg(fs, e2)  -- operand must be on the 'stack'
      self:codearith(fs, "OP_CONCAT", e1, e2)
    end
  else
    -- the following uses a table lookup in place of conditionals
    local arith = self.arith_op[op]
    if arith then
      self:codearith(fs, arith, e1, e2)
    else
      local comp = self.comp_op[op]
      if comp then
        self:codecomp(fs, comp, self.comp_cond[op], e1, e2)
      else
        assert(0)
      end
    end--if arith
  end--if op
end

------------------------------------------------------------------------
-- adjusts debug information for last instruction written, in order to
-- change the line where item comes into existence
-- * used in (lparser) luaY:funcargs(), luaY:forbody(), luaY:funcstat()
------------------------------------------------------------------------
function luaK:fixline(fs, line)
  fs.f.lineinfo[fs.pc - 1] = line
end

------------------------------------------------------------------------
-- general function to write an instruction into the instruction buffer,
-- sets debug information too
-- * used in luaK:codeABC(), luaK:codeABx()
-- * called directly by (lparser) luaY:whilestat()
------------------------------------------------------------------------
function luaK:code(fs, i, line)
  local f = fs.f
  self:dischargejpc(fs)  -- 'pc' will change
  -- put new instruction in code array
  luaY:growvector(fs.L, f.code, fs.pc, f.sizecode, nil,
                  luaY.MAX_INT, "code size overflow")
  f.code[fs.pc] = i
  -- save corresponding line information
  luaY:growvector(fs.L, f.lineinfo, fs.pc, f.sizelineinfo, nil,
                  luaY.MAX_INT, "code size overflow")
  f.lineinfo[fs.pc] = line
  local pc = fs.pc
  fs.pc = fs.pc + 1
  return pc
end

------------------------------------------------------------------------
-- writes an instruction of type ABC
-- * calls luaK:code()
------------------------------------------------------------------------
function luaK:codeABC(fs, o, a, b, c)
  assert(luaP:getOpMode(o) == luaP.OpMode.iABC)
  assert(luaP:getBMode(o) ~= luaP.OpArgMask.OpArgN or b == 0)
  assert(luaP:getCMode(o) ~= luaP.OpArgMask.OpArgN or c == 0)
  return self:code(fs, luaP:CREATE_ABC(o, a, b, c), fs.ls.lastline)
end

------------------------------------------------------------------------
-- writes an instruction of type ABx
-- * calls luaK:code(), called by luaK:codeAsBx()
------------------------------------------------------------------------
function luaK:codeABx(fs, o, a, bc)
  assert(luaP:getOpMode(o) == luaP.OpMode.iABx or
             luaP:getOpMode(o) == luaP.OpMode.iAsBx)
  assert(luaP:getCMode(o) == luaP.OpArgMask.OpArgN)
  return self:code(fs, luaP:CREATE_ABx(o, a, bc), fs.ls.lastline)
end

------------------------------------------------------------------------
--
-- * used in (lparser) luaY:closelistfield(), luaY:lastlistfield()
------------------------------------------------------------------------
function luaK:setlist(fs, base, nelems, tostore)
  local c = math.floor((nelems - 1)/luaP.LFIELDS_PER_FLUSH) + 1
  local b = (tostore == luaY.LUA_MULTRET) and 0 or tostore
  assert(tostore ~= 0)
  if c <= luaP.MAXARG_C then
    self:codeABC(fs, "OP_SETLIST", base, b, c)
  else
    self:codeABC(fs, "OP_SETLIST", base, b, 0)
    self:code(fs, luaP:CREATE_Inst(c), fs.ls.lastline)
  end
  fs.freereg = base + 1  -- free registers with list values
end

return function(a) luaY = a return luaK end