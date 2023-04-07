--!strict
--[=[
  @function fromEntries
  @within Dictionary

  @param entries {{ K, V }} -- An array of key-value pairs.
  @return {[K]: V} -- A dictionary composed of the given key-value pairs.

  Creates a dictionary from the given key-value pairs.

  ```lua
  local entries = { { "hello", "roblox" }, { "goodbye", "world" } }

  local dictionary = FromEntries(entries) -- { hello = "roblox", goodbye = "world" }
  ```
]=]
local function fromEntries<K, V>(entries: { [number]: { [number]: K | V } }): { [K]: V }
	local result = {}

	for _, entry in ipairs(entries) do
		result[entry[1]] = entry[2]
	end

	return result
end

return fromEntries
