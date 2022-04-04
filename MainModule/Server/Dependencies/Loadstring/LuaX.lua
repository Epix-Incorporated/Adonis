--# selene: allow(incorrect_standard_library_use, multiple_statements, shadowing, unused_variable, empty_if, divide_by_zero, unbalanced_assignments)
--[[--------------------------------------------------------------------

  llex.lua
  Lua lexical analyzer in Lua
  This file is part of Yueliang.

  Copyright (c) 2005-2006 Kein-Hong Man <khman@users.sf.net>
  The COPYRIGHT file describes the conditions
  under which this software may be distributed.

  See the ChangeLog for more information.

----------------------------------------------------------------------]]

--[[--------------------------------------------------------------------
-- Notes:
-- * intended to 'imitate' llex.c code; performance is not a concern
-- * tokens are strings; code structure largely retained
-- * deleted stuff (compared to llex.c) are noted, comments retained
-- * nextc() returns the currently read character to simplify coding
--   here; next() in llex.c does not return anything
-- * compatibility code is marked with "--#" comments
--
-- Added:
-- * luaX:chunkid (function luaO_chunkid from lobject.c)
-- * luaX:str2d (function luaO_str2d from lobject.c)
-- * luaX.LUA_QS used in luaX:lexerror (from luaconf.h)
-- * luaX.LUA_COMPAT_LSTR in luaX:read_long_string (from luaconf.h)
-- * luaX.MAX_INT used in luaX:inclinenumber (from llimits.h)
--
-- To use the lexer:
-- (1) luaX:init() to initialize the lexer
-- (2) luaX:setinput() to set the input stream to lex
-- (3) call luaX:next() or luaX:luaX:lookahead() to get tokens,
--     until "TK_EOS": luaX:next()
-- * since EOZ is returned as a string, be careful when regexp testing
--
-- Not implemented:
-- * luaX_newstring: not required by this Lua implementation
-- * buffer MAX_SIZET size limit (from llimits.h) test not implemented
--   in the interest of performance
-- * locale-aware number handling is largely redundant as Lua's
--   tonumber() function is already capable of this
--
-- Changed in 5.1.x:
-- * TK_NAME token order moved down
-- * string representation for TK_NAME, TK_NUMBER, TK_STRING changed
-- * token struct renamed to lower case (LS -> ls)
-- * LexState struct: removed nestlevel, added decpoint
-- * error message functions have been greatly simplified
-- * token2string renamed to luaX_tokens, exposed in llex.h
-- * lexer now handles all kinds of newlines, including CRLF
-- * shbang first line handling removed from luaX:setinput;
--   it is now done in lauxlib.c (luaL_loadfile)
-- * next(ls) macro renamed to nextc(ls) due to new luaX_next function
-- * EXTRABUFF and MAXNOCHECK removed due to lexer changes
-- * checkbuffer(ls, len) macro deleted
-- * luaX:read_numeral now has 3 support functions: luaX:trydecpoint,
--   luaX:buffreplace and (luaO_str2d from lobject.c) luaX:str2d
-- * luaX:read_numeral is now more promiscuous in slurping characters;
--   hexadecimal numbers was added, locale-aware decimal points too
-- * luaX:skip_sep is new; used by luaX:read_long_string
-- * luaX:read_long_string handles new-style long blocks, with some
--   optional compatibility code
-- * luaX:llex: parts changed to support new-style long blocks
-- * luaX:llex: readname functionality has been folded in
-- * luaX:llex: removed test for control characters
--
--------------------------------------------------------------------]]

local luaZ = require(script.Parent.LuaZ)

local luaX = {}

-- FIRST_RESERVED is not required as tokens are manipulated as strings
-- TOKEN_LEN deleted; maximum length of a reserved word not needed

------------------------------------------------------------------------
-- "ORDER RESERVED" deleted; enumeration in one place: luaX.RESERVED
------------------------------------------------------------------------

-- terminal symbols denoted by reserved words: TK_AND to TK_WHILE
-- other terminal symbols: TK_NAME to TK_EOS
luaX.RESERVED = [[
TK_AND and
TK_BREAK break
TK_DO do
TK_ELSE else
TK_ELSEIF elseif
TK_END end
TK_FALSE false
TK_FOR for
TK_FUNCTION function
TK_IF if
TK_IN in
TK_LOCAL local
TK_NIL nil
TK_NOT not
TK_OR or
TK_REPEAT repeat
TK_RETURN return
TK_THEN then
TK_TRUE true
TK_UNTIL until
TK_WHILE while
TK_CONCAT ..
TK_DOTS ...
TK_EQ ==
TK_GE >=
TK_LE <=
TK_NE ~=
TK_NAME <name>
TK_NUMBER <number>
TK_STRING <string>
TK_EOS <eof>]]

-- NUM_RESERVED is not required; number of reserved words

--[[--------------------------------------------------------------------
-- Instead of passing seminfo, the Token struct (e.g. ls.t) is passed
-- so that lexer functions can use its table element, ls.t.seminfo
--
-- SemInfo (struct no longer needed, a mixed-type value is used)
--
-- Token (struct of ls.t and ls.lookahead):
--   token  -- token symbol
--   seminfo  -- semantics information
--
-- LexState (struct of ls; ls is initialized by luaX:setinput):
--   current  -- current character (charint)
--   linenumber  -- input line counter
--   lastline  -- line of last token 'consumed'
--   t  -- current token (table: struct Token)
--   lookahead  -- look ahead token (table: struct Token)
--   fs  -- 'FuncState' is private to the parser
--   L -- LuaState
--   z  -- input stream
--   buff  -- buffer for tokens
--   source  -- current source name
--   decpoint -- locale decimal point
--   nestlevel  -- level of nested non-terminals
----------------------------------------------------------------------]]

-- luaX.tokens (was luaX_tokens) is now a hash; see luaX:init

luaX.MAXSRC = 80
luaX.MAX_INT = 2147483645       -- constants from elsewhere (see above)
luaX.LUA_QS = "'%s'"
luaX.LUA_COMPAT_LSTR = 1
--luaX.MAX_SIZET = 4294967293

------------------------------------------------------------------------
-- initialize lexer
-- * original luaX_init has code to create and register token strings
-- * luaX.tokens: TK_* -> token
-- * luaX.enums:  token -> TK_* (used in luaX:llex)
------------------------------------------------------------------------
function luaX:init()
  local tokens, enums = {}, {}
  for v in string.gmatch(self.RESERVED, "[^\n]+") do
    local _, _, tok, str = string.find(v, "(%S+)%s+(%S+)")
    tokens[tok] = str
    enums[str] = tok
  end
  self.tokens = tokens
  self.enums = enums
end

------------------------------------------------------------------------
-- returns a suitably-formatted chunk name or id
-- * from lobject.c, used in llex.c and ldebug.c
-- * the result, out, is returned (was first argument)
------------------------------------------------------------------------
function luaX:chunkid(source, bufflen)
  local out
  local first = string.sub(source, 1, 1)
  if first == "=" then
    out = string.sub(source, 2, bufflen)  -- remove first char
  else  -- out = "source", or "...source"
    if first == "@" then
      source = string.sub(source, 2)  -- skip the '@'
      bufflen = bufflen - #" '...' "
      local l = #source
      out = ""
      if l > bufflen then
        source = string.sub(source, 1 + l - bufflen)  -- get last part of file name
        out = out.."..."
      end
      out = out..source
    else  -- out = [string "string"]
      local len = string.find(source, "[\n\r]")  -- stop at first newline
      len = len and (len - 1) or #source
      bufflen = bufflen - #(" [string \"...\"] ")
      if len > bufflen then len = bufflen end
      out = "[string \""
      if len < #source then  -- must truncate?
        out = out..string.sub(source, 1, len).."..."
      else
        out = out..source
      end
      out = out.."\"]"
    end
  end
  return out
end

--[[--------------------------------------------------------------------
-- Support functions for lexer
-- * all lexer errors eventually reaches lexerror:
     syntaxerror -> lexerror
----------------------------------------------------------------------]]

------------------------------------------------------------------------
-- look up token and return keyword if found (also called by parser)
------------------------------------------------------------------------
function luaX:token2str(ls, token)
  if string.sub(token, 1, 3) ~= "TK_" then
    if string.find(token, "%c") then
      return string.format("char(%d)", string.byte(token))
    end
    return token
  else
  end
    return self.tokens[token]
end

------------------------------------------------------------------------
-- throws a lexer error
-- * txtToken has been made local to luaX:lexerror
-- * can't communicate LUA_ERRSYNTAX, so it is unimplemented
------------------------------------------------------------------------
function luaX:lexerror(ls, msg, token)
  local function txtToken(ls, token)
    if token == "TK_NAME" or
       token == "TK_STRING" or
       token == "TK_NUMBER" then
      return ls.buff
    else
      return self:token2str(ls, token)
    end
  end
  local buff = self:chunkid(ls.source, self.MAXSRC)
  local msg = string.format("%s:%d: %s", buff, ls.linenumber, msg)
  if token then
    msg = string.format("%s near "..self.LUA_QS, msg, txtToken(ls, token))
  end
  -- luaD_throw(ls->L, LUA_ERRSYNTAX)
  error(msg)
end

------------------------------------------------------------------------
-- throws a syntax error (mainly called by parser)
-- * ls.t.token has to be set by the function calling luaX:llex
--   (see luaX:next and luaX:lookahead elsewhere in this file)
------------------------------------------------------------------------
function luaX:syntaxerror(ls, msg)
  self:lexerror(ls, msg, ls.t.token)
end

------------------------------------------------------------------------
-- move on to next line
------------------------------------------------------------------------
function luaX:currIsNewline(ls)
  return ls.current == "\n" or ls.current == "\r"
end

function luaX:inclinenumber(ls)
  local old = ls.current
  -- lua_assert(currIsNewline(ls))
  self:nextc(ls)  -- skip '\n' or '\r'
  if self:currIsNewline(ls) and ls.current ~= old then
    self:nextc(ls)  -- skip '\n\r' or '\r\n'
  end
  ls.linenumber = ls.linenumber + 1
  if ls.linenumber >= self.MAX_INT then
    self:syntaxerror(ls, "chunk has too many lines")
  end
end

------------------------------------------------------------------------
-- initializes an input stream for lexing
-- * if ls (the lexer state) is passed as a table, then it is filled in,
--   otherwise it has to be retrieved as a return value
-- * LUA_MINBUFFER not used; buffer handling not required any more
------------------------------------------------------------------------
function luaX:setinput(L, ls, z, source)
  if not ls then ls = {} end  -- create struct
  if not ls.lookahead then ls.lookahead = {} end
  if not ls.t then ls.t = {} end
  ls.decpoint = "."
  ls.L = L
  ls.lookahead.token = "TK_EOS"  -- no look-ahead token
  ls.z = z
  ls.fs = nil
  ls.linenumber = 1
  ls.lastline = 1
  ls.source = source
  self:nextc(ls)  -- read first char
end

--[[--------------------------------------------------------------------
-- LEXICAL ANALYZER
----------------------------------------------------------------------]]

------------------------------------------------------------------------
-- checks if current character read is found in the set 'set'
------------------------------------------------------------------------
function luaX:check_next(ls, set)
  if not string.find(set, ls.current, 1, 1) then
    return false
  end
  self:save_and_next(ls)
  return true
end

------------------------------------------------------------------------
-- retrieve next token, checking the lookahead buffer if necessary
-- * note that the macro next(ls) in llex.c is now luaX:nextc
-- * utilized used in lparser.c (various places)
------------------------------------------------------------------------
function luaX:next(ls)
  ls.lastline = ls.linenumber
  if ls.lookahead.token ~= "TK_EOS" then  -- is there a look-ahead token?
    -- this must be copy-by-value
    ls.t.seminfo = ls.lookahead.seminfo  -- use this one
    ls.t.token = ls.lookahead.token
    ls.lookahead.token = "TK_EOS"  -- and discharge it
  else
    ls.t.token = self:llex(ls, ls.t)  -- read next token
  end
end

------------------------------------------------------------------------
-- fill in the lookahead buffer
-- * utilized used in lparser.c:constructor
------------------------------------------------------------------------
function luaX:lookahead(ls)
  -- lua_assert(ls.lookahead.token == "TK_EOS")
  ls.lookahead.token = self:llex(ls, ls.lookahead)
end

------------------------------------------------------------------------
-- gets the next character and returns it
-- * this is the next() macro in llex.c; see notes at the beginning
------------------------------------------------------------------------
function luaX:nextc(ls)
  local c = luaZ:zgetc(ls.z)
  ls.current = c
  return c
end

------------------------------------------------------------------------
-- saves the given character into the token buffer
-- * buffer handling code removed, not used in this implementation
-- * test for maximum token buffer length not used, makes things faster
------------------------------------------------------------------------

function luaX:save(ls, c)
  local buff = ls.buff
  -- if you want to use this, please uncomment luaX.MAX_SIZET further up
  --if #buff > self.MAX_SIZET then
  --  self:lexerror(ls, "lexical element too long")
  --end
  ls.buff = buff..c
end

------------------------------------------------------------------------
-- save current character into token buffer, grabs next character
-- * like luaX:nextc, returns the character read for convenience
------------------------------------------------------------------------
function luaX:save_and_next(ls)
  self:save(ls, ls.current)
  return self:nextc(ls)
end

------------------------------------------------------------------------
-- LUA_NUMBER
-- * luaX:read_numeral is the main lexer function to read a number
-- * luaX:str2d, luaX:buffreplace, luaX:trydecpoint are support functions
------------------------------------------------------------------------

------------------------------------------------------------------------
-- string to number converter (was luaO_str2d from lobject.c)
-- * returns the number, nil if fails (originally returns a boolean)
-- * conversion function originally lua_str2number(s,p), a macro which
--   maps to the strtod() function by default (from luaconf.h)
------------------------------------------------------------------------
function luaX:str2d(s)
  local result = tonumber(s)
  if result then return result end
  -- conversion failed
  if string.lower(string.sub(s, 1, 2)) == "0x" then  -- maybe an hexadecimal constant?
    result = tonumber(s, 16)
    if result then return result end  -- most common case
    -- Was: invalid trailing characters?
    -- In C, this function then skips over trailing spaces.
    -- true is returned if nothing else is found except for spaces.
    -- If there is still something else, then it returns a false.
    -- All this is not necessary using Lua's tonumber.
  end
  return nil
end

------------------------------------------------------------------------
-- single-character replacement, for locale-aware decimal points
------------------------------------------------------------------------
function luaX:buffreplace(ls, from, to)
  local result, buff = "", ls.buff
  for p = 1, #buff do
    local c = string.sub(buff, p, p)
    if c == from then c = to end
    result = result..c
  end
  ls.buff = result
end

------------------------------------------------------------------------
-- Attempt to convert a number by translating '.' decimal points to
-- the decimal point character used by the current locale. This is not
-- needed in Yueliang as Lua's tonumber() is already locale-aware.
-- Instead, the code is here in case the user implements localeconv().
------------------------------------------------------------------------
function luaX:trydecpoint(ls, Token)
  -- format error: try to update decimal point separator
  local old = ls.decpoint
  -- translate the following to Lua if you implement localeconv():
  -- struct lconv *cv = localeconv();
  -- ls->decpoint = (cv ? cv->decimal_point[0] : '.');
  self:buffreplace(ls, old, ls.decpoint)  -- try updated decimal separator
  local seminfo = self:str2d(ls.buff)
  Token.seminfo = seminfo
  if not seminfo then
    -- format error with correct decimal point: no more options
    self:buffreplace(ls, ls.decpoint, ".")  -- undo change (for error message)
    self:lexerror(ls, "malformed number", "TK_NUMBER")
  end
end

------------------------------------------------------------------------
-- main number conversion function
-- * "^%w$" needed in the scan in order to detect "EOZ"
------------------------------------------------------------------------
function luaX:read_numeral(ls, Token)
  -- lua_assert(string.find(ls.current, "%d"))
  repeat
    self:save_and_next(ls)
  until string.find(ls.current, "%D") and ls.current ~= "."
  if self:check_next(ls, "Ee") then  -- 'E'?
    self:check_next(ls, "+-")  -- optional exponent sign
  end
  while string.find(ls.current, "^%w$") or ls.current == "_" do
    self:save_and_next(ls)
  end
  self:buffreplace(ls, ".", ls.decpoint)  -- follow locale for decimal point
  local seminfo = self:str2d(ls.buff)
  Token.seminfo = seminfo
  if not seminfo then  -- format error?
    self:trydecpoint(ls, Token) -- try to update decimal point separator
  end
end

------------------------------------------------------------------------
-- count separators ("=") in a long string delimiter
-- * used by luaX:read_long_string
------------------------------------------------------------------------
function luaX:skip_sep(ls)
  local count = 0
  local s = ls.current
  -- lua_assert(s == "[" or s == "]")
  self:save_and_next(ls)
  while ls.current == "=" do
    self:save_and_next(ls)
    count = count + 1
  end
  return (ls.current == s) and count or (-count) - 1
end

------------------------------------------------------------------------
-- reads a long string or long comment
------------------------------------------------------------------------
function luaX:read_long_string(ls, Token, sep)
  local cont = 0
  self:save_and_next(ls)  -- skip 2nd '['
  if self:currIsNewline(ls) then  -- string starts with a newline?
    self:inclinenumber(ls)  -- skip it
  end
  while true do
    local c = ls.current
    if c == "EOZ" then
      self:lexerror(ls, Token and "unfinished long string" or
                    "unfinished long comment", "TK_EOS")
    elseif c == "[" then
      --# compatibility code start
      if self.LUA_COMPAT_LSTR then
        if self:skip_sep(ls) == sep then
          self:save_and_next(ls)  -- skip 2nd '['
          cont = cont + 1
          --# compatibility code start
          if self.LUA_COMPAT_LSTR == 1 then
            if sep == 0 then
              self:lexerror(ls, "nesting of [[...]] is deprecated", "[")
            end
          end
          --# compatibility code end
        end
      end
      --# compatibility code end
    elseif c == "]" then
      if self:skip_sep(ls) == sep then
        self:save_and_next(ls)  -- skip 2nd ']'
        --# compatibility code start
        if self.LUA_COMPAT_LSTR and self.LUA_COMPAT_LSTR == 2 then
          cont = cont - 1
          if sep == 0 and cont >= 0 then break end
        end
        --# compatibility code end
        break
      end
    elseif self:currIsNewline(ls) then
      self:save(ls, "\n")
      self:inclinenumber(ls)
      if not Token then ls.buff = "" end -- avoid wasting space
    else  -- default
      if Token then
        self:save_and_next(ls)
      else
        self:nextc(ls)
      end
    end--if c
  end--while
  if Token then
    local p = 3 + sep
    Token.seminfo = string.sub(ls.buff, p, -p)
  end
end

------------------------------------------------------------------------
-- reads a string
-- * has been restructured significantly compared to the original C code
------------------------------------------------------------------------

function luaX:read_string(ls, del, Token)
  self:save_and_next(ls)
  while ls.current ~= del do
    local c = ls.current
    if c == "EOZ" then
      self:lexerror(ls, "unfinished string", "TK_EOS")
    elseif self:currIsNewline(ls) then
      self:lexerror(ls, "unfinished string", "TK_STRING")
    elseif c == "\\" then
      c = self:nextc(ls)  -- do not save the '\'
      if self:currIsNewline(ls) then  -- go through
        self:save(ls, "\n")
        self:inclinenumber(ls)
      elseif c ~= "EOZ" then -- will raise an error next loop
        -- escapes handling greatly simplified here:
        local i = string.find("abfnrtv", c, 1, 1)
        if i then
          self:save(ls, string.sub("\a\b\f\n\r\t\v", i, i))
          self:nextc(ls)
        elseif not string.find(c, "%d") then
          self:save_and_next(ls)  -- handles \\, \", \', and \?
        else  -- \xxx
          c, i = 0, 0
          repeat
            c = 10 * c + ls.current
            self:nextc(ls)
            i = i + 1
          until i >= 3 or not string.find(ls.current, "%d")
          if c > 255 then  -- UCHAR_MAX
            self:lexerror(ls, "escape sequence too large", "TK_STRING")
          end
          self:save(ls, string.char(c))
        end
      end
    else
      self:save_and_next(ls)
    end--if c
  end--while
  self:save_and_next(ls)  -- skip delimiter
  Token.seminfo = string.sub(ls.buff, 2, -2)
end

------------------------------------------------------------------------
-- main lexer function
------------------------------------------------------------------------
function luaX:llex(ls, Token)
  ls.buff = ""
  while true do
    local c = ls.current
    ----------------------------------------------------------------
    if self:currIsNewline(ls) then
      self:inclinenumber(ls)
    ----------------------------------------------------------------
    elseif c == "-" then
      c = self:nextc(ls)
      if c ~= "-" then return "-" end
      -- else is a comment
      local sep = -1
      if self:nextc(ls) == '[' then
        sep = self:skip_sep(ls)
        ls.buff = ""  -- 'skip_sep' may dirty the buffer
      end
      if sep >= 0 then
        self:read_long_string(ls, nil, sep)  -- long comment
        ls.buff = ""
      else  -- else short comment
        while not self:currIsNewline(ls) and ls.current ~= "EOZ" do
          self:nextc(ls)
        end
      end
    ----------------------------------------------------------------
    elseif c == "[" then
      local sep = self:skip_sep(ls)
      if sep >= 0 then
        self:read_long_string(ls, Token, sep)
        return "TK_STRING"
      elseif sep == -1 then
        return "["
      else
        self:lexerror(ls, "invalid long string delimiter", "TK_STRING")
      end
    ----------------------------------------------------------------
    elseif c == "=" then
      c = self:nextc(ls)
      if c ~= "=" then return "="
      else self:nextc(ls); return "TK_EQ" end
    ----------------------------------------------------------------
    elseif c == "<" then
      c = self:nextc(ls)
      if c ~= "=" then return "<"
      else self:nextc(ls); return "TK_LE" end
    ----------------------------------------------------------------
    elseif c == ">" then
      c = self:nextc(ls)
      if c ~= "=" then return ">"
      else self:nextc(ls); return "TK_GE" end
    ----------------------------------------------------------------
    elseif c == "~" then
      c = self:nextc(ls)
      if c ~= "=" then return "~"
      else self:nextc(ls); return "TK_NE" end
    ----------------------------------------------------------------
    elseif c == "\"" or c == "'" then
      self:read_string(ls, c, Token)
      return "TK_STRING"
    ----------------------------------------------------------------
    elseif c == "." then
      c = self:save_and_next(ls)
      if self:check_next(ls, ".") then
        if self:check_next(ls, ".") then
          return "TK_DOTS"   -- ...
        else return "TK_CONCAT"   -- ..
        end
      elseif not string.find(c, "%d") then
        return "."
      else
        self:read_numeral(ls, Token)
        return "TK_NUMBER"
      end
    ----------------------------------------------------------------
    elseif c == "EOZ" then
      return "TK_EOS"
    ----------------------------------------------------------------
    else  -- default
      if string.find(c, "%s") then
        -- lua_assert(self:currIsNewline(ls))
        self:nextc(ls)
      elseif string.find(c, "%d") then
        self:read_numeral(ls, Token)
        return "TK_NUMBER"
      elseif string.find(c, "[_%a]") then
        -- identifier or reserved word
        repeat
          c = self:save_and_next(ls)
        until c == "EOZ" or not string.find(c, "[_%w]")
        local ts = ls.buff
        local tok = self.enums[ts]
        if tok then return tok end  -- reserved word?
        Token.seminfo = ts
        return "TK_NAME"
      else
        self:nextc(ls)
        return c  -- single-char tokens (+ - / ...)
      end
    ----------------------------------------------------------------
    end--if c
  end--while
end

return luaX