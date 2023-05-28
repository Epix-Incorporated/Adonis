--!strict
--[=[
  @function keys
  @within Dictionary

  @param dictionary {[K]: V} -- The dictionary to get the keys of.
  @return {K} -- An array containing the keys of the given dictionary.

  Gets the keys of the given dictionary as an array.

  ```lua
  local dictionary = { hello = "roblox", goodbye = "world" }

  local keys = Keys(dictionary) -- { "hello", "goodbye" }
  ```
]=]
local function keys<K, V>(dictionary: { [K]: V }): { K }
	local result = {}

	for key in pairs(dictionary) do
		table.insert(result, key)
	end

	return result
end

return keys
