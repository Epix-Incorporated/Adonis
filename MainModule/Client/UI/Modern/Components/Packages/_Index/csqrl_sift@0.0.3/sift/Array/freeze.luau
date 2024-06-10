--!strict
local Copy = require(script.Parent.copy)

--[=[
  @function freeze
  @within Array

  @param array {T} -- The array to freeze.
  @return {T} -- The frozen array.

  Freezes the top level of the array, making it read-only.

  ```lua
  local array = { 1, 2, 3, { 4, 5, 6 } }

  local new = Freeze(array)

  new[1] = 4 -- error!
  new[4][1] = 7 -- still works!
  ```
]=]
local function freeze<T>(array: { T }): { T }
	local new = Copy(array)

	table.freeze(new)

	return new
end

return freeze
