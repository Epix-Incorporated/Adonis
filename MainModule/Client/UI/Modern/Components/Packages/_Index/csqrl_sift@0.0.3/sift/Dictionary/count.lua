--!strict
local Sift = script.Parent.Parent

local Util = require(Sift.Util)

--[=[
  @function count
  @within Dictionary

  @param dictionary T -- The dictionary to count.
  @param predicate? (value: T, key: K, dictionary: T) -> any -- The predicate to use to filter the dictionary.
  @return number -- The number of items in the dictionary.

  Counts the number of items in a dictionary.

  ```lua
  local dictionary = { hello = "world", goodbye = "world" }

  local value = Count(dictionary) -- 2
  local value = Count(dictionary, function(item, key)
    return item == "world"
  end) -- 1
  ```
]=]
local function count<K, V>(
	dictionary: { [K]: V },
	predicate: ((value: V, key: K, dictionary: { [K]: V }) -> any)?
): number
	local counter = 0

	predicate = if type(predicate) == "function" then predicate else Util.func.truthy

	for key, value in pairs(dictionary) do
		if predicate(value, key, dictionary) then
			counter += 1
		end
	end

	return counter
end

return count
