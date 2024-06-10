--!strict
--[=[
  @function removeValue
  @within Dictionary

  @param dictionary {[K]: V} -- The dictionary to remove the value from.
  @param value V -- The value to remove.
  @return {[K]: V} -- The dictionary without the given value.

  Removes the given value from the given dictionary.

  ```lua
  local dictionary = { hello = "roblox", goodbye = "world" }

  local withoutHello = RemoveValue(dictionary, "roblox") -- { goodbye = "world" }
  local withoutGoodbye = RemoveValue(dictionary, "world") -- { hello = "roblox" }
  ```
]=]
local function removeValue<K, V>(dictionary: { [K]: V }, value: V): { [K]: V }
	local result = {}

	for key, v in pairs(dictionary) do
		if v ~= value then
			result[key] = v
		end
	end

	return result
end

return removeValue
