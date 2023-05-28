--!strict
--[=[
  @function fromArrays
  @within Dictionary

  @param keys {K} -- An array containing values to be used as keys.
  @param values {V} -- An array containing values to be used as values.
  @return {[K]: V} -- A dictionary composed of the given keys and values.

  Creates a dictionary from the given arrays, where the first array is used
  as keys and the second array is used as values.

  ```lua
  local keys = { "hello", "goodbye" }
  local values = { "roblox", "world" }

  local dictionary = FromArrays(keys, values) -- { hello = "roblox", goodbye = "world" }
  ```
]=]
local function fromArrays<K, V>(keys: { K }, values: { V }): { [K]: V }
	local keysLength = #keys
	local result = {}

	for i = 1, keysLength do
		result[keys[i]] = values[i]
	end

	return result
end

return fromArrays
