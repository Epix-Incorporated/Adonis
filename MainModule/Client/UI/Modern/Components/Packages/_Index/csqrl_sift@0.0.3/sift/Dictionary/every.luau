--!strict
--[=[
  @function every
  @within Dictionary

  @param dictionary {[K]: V} -- The dictionary to check.
  @param predicate (value: V, key: K, dictionary: {[K]: V}) -> any -- The predicate to use to check the dictionary.
  @return boolean -- Whether every item in the dictionary passes the predicate.

  Checks whether every item in the dictionary passes the predicate.

  ```lua
  local dictionary = { hello = "world", goodbye = "world" }

  local value = Every(dictionary, function(value, key)
    return value == "world"
  end) -- true

  local value = Every(dictionary, function(value, key)
    return value == "hello"
  end) -- false
  ```
]=]
local function every<K, V>(
	dictionary: { [K]: V },
	predicate: (value: V, key: K, dictionary: { [K]: V }) -> any
): boolean
	for key, value in pairs(dictionary) do
		if not predicate(value, key, dictionary) then
			return false
		end
	end

	return true
end

return every
