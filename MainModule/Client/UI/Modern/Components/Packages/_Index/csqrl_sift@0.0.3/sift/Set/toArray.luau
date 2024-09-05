--!strict
--[=[
  @function toArray
  @within Set

  @param set { [T]: boolean } -- The set to convert to an array.
  @return {T} -- The array.

  Converts a set to an array.

  ```lua
  local set = { hello = true, world = true }

  local array = ToArray(set) -- { "hello", "world" }
  ```
]=]
local function toArray<T>(set: { [T]: boolean }): { T }
	local result = {}

	for key, _ in pairs(set) do
		table.insert(result, key)
	end

	return result
end

return toArray
