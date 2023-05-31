--!strict
--[=[
  @function has
  @within Set

  @param set { [T]: boolean } -- The set to check.
  @param value any -- The value to check for.
  @return boolean -- Whether the value is in the set.

  Checks whether a value is in a set.

  ```lua
  local set = { hello = true }

  local has = Has(set, "hello") -- true
  ```
]=]
local function has<T>(set: { [T]: boolean }, value: any): boolean
	return set[value] == true
end

return has
