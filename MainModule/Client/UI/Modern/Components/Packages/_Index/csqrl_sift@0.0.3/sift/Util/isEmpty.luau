--!strict
local _T = require(script.Parent.Parent.Types)

--[=[
  @function isEmpty
  @within Sift
  @since v0.0.1

  @param table table -- The table to check.
  @return boolean -- Whether or not the table is empty.

  Checks whether or not a table is empty.

  ```lua
  local a = {}
  local b = { hello = "world" }

  local value = isEmpty(a) -- true
  local value = isEmpty(b) -- false
  ```
]=]
local function isEmpty(table: _T.Table): boolean
	return next(table) == nil
end

return isEmpty
