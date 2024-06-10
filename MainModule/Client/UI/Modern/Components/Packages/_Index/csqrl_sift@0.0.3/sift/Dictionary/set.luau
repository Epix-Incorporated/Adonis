--!strict
local copy = require(script.Parent.copy)

--[=[
  @function set
  @within Dictionary

  @param dictionary {[K]: V} -- The dictionary to set the value in.
  @param key K -- The key to set the value in.
  @param value V -- The value to set.
  @return {[K]: V} -- The dictionary with the given value set.

  Sets the given value in the given dictionary.

  ```lua
  local dictionary = { hello = "world", cat = "meow", unicorn = "rainbow" }

  local setCat = Set(dictionary, "cat", "woof") -- { hello = "world", cat = "woof", unicorn = "rainbow" }
  ```
]=]
local function set<K, V>(dictionary: { [K]: V }, key: K, value: V): { [K]: V }
	local result = copy(dictionary)

	result[key] = value

	return result
end

return set
