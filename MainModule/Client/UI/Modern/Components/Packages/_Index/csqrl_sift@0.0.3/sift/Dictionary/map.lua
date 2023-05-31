--!strict
--[=[
  @function map
  @within Dictionary

  @param dictionary {[K]: V} -- The dictionary to map.
  @param mapper (value: V, key: K, dictionary: {[K]: V}) -> (Y?, X?) -- The mapper function.
  @return {[X]: Y} -- The mapped dictionary.

  Maps the dictionary using the mapper function. The mapper function can
  return a value and a key. If the mapper function does not return a key,
  the original key will be used.

  ```lua
  local dictionary = { hello = 10, goodbye = 20 }

  local new = Map(dictionary, function(value, key)
    return value * 2, key .. "!"
  end) -- { ["hello!"] = 20, ["goodbye!"] = 40 }

  local new = Map(dictionary, function(value, key)
    return value * 10
  end) -- { hello = 100, goodbye = 200 }
  ```
]=]
local function map<K, V, X, Y>(
	dictionary: { [K]: V },
	mapper: (value: V, key: K, dictionary: { [K]: V }) -> (Y?, X?)
): { [X]: Y }
	local mapped = {}

	for key, value in pairs(dictionary) do
		local mappedValue, mappedKey = mapper(value, key, dictionary)
		mapped[mappedKey or key] = mappedValue
	end

	return mapped
end

return map
