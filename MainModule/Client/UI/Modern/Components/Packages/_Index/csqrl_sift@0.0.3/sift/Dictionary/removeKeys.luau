--!strict
local copy = require(script.Parent.copy)

--[=[
  @function removeKeys
  @within Dictionary

  @param dictionary {[K]: V} -- The dictionary to remove the keys from.
  @param keys ...K -- The keys to remove.
  @return {[K]: V} -- The dictionary without the given keys.

  Removes the given keys from the given dictionary.

  ```lua
  local dictionary = { hello = "world", cat = "meow", dog = "woof", unicorn = "rainbow" }

  local withoutCatDog = RemoveKeys(dictionary, "cat", "dog") -- { hello = "world", unicorn = "rainbow" }
  ```
]=]
local function removeKeys<K, V>(dictionary: { [K]: V }, ...: K): { [K]: V }
	local result = copy(dictionary)

	for _, key in ipairs({ ... }) do
		result[key] = nil
	end

	return result
end

return removeKeys
