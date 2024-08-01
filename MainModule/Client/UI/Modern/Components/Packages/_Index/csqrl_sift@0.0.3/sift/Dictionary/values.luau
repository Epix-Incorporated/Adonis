--!strict
--[=[
  @function values
  @within Dictionary

  @param dictionary {[K]: V} -- The dictionary to get the values from.
  @return {V} -- The values in the dictionary.

  Gets the values in the given dictionary.

  ```lua
  local dictionary = { hello = "roblox", goodbye = "world" }

  local values = Values(dictionary) -- { "roblox", "world" }
  ```
]=]
local function values<K, V>(dictionary: { [K]: V }): { V }
	local result = {}

	for _, value in pairs(dictionary) do
		table.insert(result, value)
	end

	return result
end

return values
