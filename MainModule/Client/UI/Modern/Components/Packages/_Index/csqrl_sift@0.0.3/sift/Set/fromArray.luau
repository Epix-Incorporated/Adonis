--!strict
--[=[
  @function fromArray
  @within Set

  @param array {T} -- The array to convert to a set.
  @return {[T]: boolean} -- The set.

  Converts an array to a set, where each item is mapped to true.
  Duplicate items are discarded.

  Aliases: `fromList`

  ```lua
  local array = { "hello", "world", "hello" }

  local set = FromArray(array) -- { hello = true, world = true }
  ```
]=]
local function fromArray<T>(array: { T }): { [T]: boolean }
	local result = table.create(#array)

	for _, value in ipairs(array) do
		result[value] = true
	end

	return result
end

return fromArray
