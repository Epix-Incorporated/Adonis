--!strict
--[=[
  @function some
  @within Dictionary

  @param dictionary {[K]: V} -- The dictionary to check.
  @param predicate (value: V, key: K, dictionary: { [K]: V }) -> any -- The predicate to check against.
  @return boolean -- Whether or not the predicate returned true for any value.

  Checks whether or not the predicate returned true for any value in the dictionary.

  ```lua
  local dictionary = { hello = "world", cat = "meow", unicorn = "rainbow" }

  local hasMeow = Some(dictionary, function(value)
    return value == "meow"
  end) -- true

  local hasDog = Some(dictionary, function(_, key)
    return key == "dog"
  end) -- false
  ```
]=]
local function some<K, V>(dictionary: { [K]: V }, predicate: (value: V, key: V, dictionary: { [K]: V }) -> any): boolean
	for key, value in pairs(dictionary) do
		if predicate(value, key, dictionary) then
			return true
		end
	end

	return false
end

return some
